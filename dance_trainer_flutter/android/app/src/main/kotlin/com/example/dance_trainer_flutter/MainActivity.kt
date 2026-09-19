package com.example.dance_trainer_flutter

import android.Manifest
import android.content.pm.PackageManager
import android.os.SystemClock
import android.util.Size
import android.view.View
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private var sink: EventChannel.EventSink? = null
    private var provider: ProcessCameraProvider? = null
    private var previewView: PreviewView? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val busy = AtomicBoolean(false)
    private var permissionResult: MethodChannel.Result? = null
    private var running = false
    private var generation = 0

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        EventChannel(engine.dartExecutor.binaryMessenger, "dance/frames").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) { sink = events }
            override fun onCancel(arguments: Any?) { sink = null; stopCamera() }
        })
        MethodChannel(engine.dartExecutor.binaryMessenger, "dance/camera").setMethodCallHandler { call, result ->
            when (call.method) {
                "permission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) result.success(true)
                    else if (permissionResult != null) result.error("busy", "Permission request in progress", null)
                    else { permissionResult = result; ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), 71) }
                }
                "start" -> { running = true; startCamera(); result.success(null) }
                "stop" -> { stopCamera(); result.success(null) }
                "ack" -> { busy.set(false); result.success(null) }
                "clock" -> result.success(SystemClock.elapsedRealtimeNanos() / 1000)
                else -> result.notImplemented()
            }
        }
        engine.platformViewsController.registry.registerViewFactory("dance/preview", object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
            override fun create(context: android.content.Context, id: Int, args: Any?): PlatformView {
                val view = PreviewView(context)
                view.implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                view.scaleType = PreviewView.ScaleType.FIT_CENTER
                previewView = view
                if (running) startCamera()
                return object : PlatformView {
                    override fun getView(): View = view
                    override fun dispose() { if (previewView === view) { stopCamera(); previewView = null } }
                }
            }
        })
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, results: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, results)
        if (requestCode == 71) { permissionResult?.success(results.isNotEmpty() && results[0] == PackageManager.PERMISSION_GRANTED); permissionResult = null }
    }
    private fun stopCamera() { running = false; generation++; provider?.unbindAll(); busy.set(false) }
    private fun startCamera() {
        val view = previewView ?: return
        if (!running || ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) return
        val token = ++generation
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            if (!running || token != generation) return@addListener
            try {
                val cameraProvider = future.get(); provider = cameraProvider
                cameraProvider.unbindAll()
                val preview = Preview.Builder().build(); preview.setSurfaceProvider(view.surfaceProvider)
                val analysis = ImageAnalysis.Builder().setTargetResolution(Size(640, 480))
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
                analysis.setAnalyzer(worker) { frame ->
                    if (!running || !busy.compareAndSet(false, true)) { frame.close(); return@setAnalyzer }
                    try {
                        val captureUs = frame.imageInfo.timestamp / 1000
                        val rotation = frame.imageInfo.rotationDegrees
                        val sw = frame.width; val sh = frame.height
                        val ow = if (rotation == 90 || rotation == 270) sh else sw
                        val oh = if (rotation == 90 || rotation == 270) sw else sh
                        val scale = minOf(640.0 / ow, 640.0 / oh)
                        val padX = (640 - ow * scale) / 2; val padY = (640 - oh * scale) / 2
                        val planes = frame.planes
                        val y = planes[0].buffer; val u = planes[1].buffer; val v = planes[2].buffer
                        val out = ByteBuffer.allocate(3 * 640 * 640 * 4).order(ByteOrder.LITTLE_ENDIAN)
                        for (py in 0 until 640) for (px in 0 until 640) {
                            val rx = ((px - padX) / scale).toInt(); val ry = ((py - padY) / scale).toInt()
                            var r = 114.0; var g = 114.0; var b = 114.0
                            if (px >= padX && py >= padY && rx in 0 until ow && ry in 0 until oh) {
                                val sx: Int; val sy: Int
                                when (rotation) {
                                    90 -> { sx = ry; sy = sh - 1 - rx }
                                    180 -> { sx = sw - 1 - rx; sy = sh - 1 - ry }
                                    270 -> { sx = sw - 1 - ry; sy = rx }
                                    else -> { sx = rx; sy = ry }
                                }
                                val yy = (y.get(sy * planes[0].rowStride + sx * planes[0].pixelStride).toInt() and 255) - 16
                                val uu = (u.get((sy / 2) * planes[1].rowStride + (sx / 2) * planes[1].pixelStride).toInt() and 255) - 128
                                val vv = (v.get((sy / 2) * planes[2].rowStride + (sx / 2) * planes[2].pixelStride).toInt() and 255) - 128
                                r = (1.164 * yy + 1.596 * vv).coerceIn(0.0, 255.0)
                                g = (1.164 * yy - 0.392 * uu - 0.813 * vv).coerceIn(0.0, 255.0)
                                b = (1.164 * yy + 2.017 * uu).coerceIn(0.0, 255.0)
                            }
                            val i = py * 640 + px
                            out.putFloat(i * 4, (r / 255).toFloat())
                            out.putFloat((640 * 640 + i) * 4, (g / 255).toFloat())
                            out.putFloat((2 * 640 * 640 + i) * 4, (b / 255).toFloat())
                        }
                        val data = mapOf("bytes" to out.array(), "captureUs" to captureUs, "width" to ow, "height" to oh,
                            "scale" to scale, "padX" to padX, "padY" to padY)
                        runOnUiThread { if (running && token == generation && sink != null) sink?.success(data) else busy.set(false) }
                    } catch (_: Exception) {
                        busy.set(false); runOnUiThread { sink?.error("camera", "Camera conversion failed. Restart the camera.", null) }
                    } finally { frame.close() }
                }
                cameraProvider.bindToLifecycle(this, CameraSelector.DEFAULT_FRONT_CAMERA, preview, analysis)
            } catch (_: Exception) { sink?.error("camera", "Front camera could not be started.", null) }
        }, ContextCompat.getMainExecutor(this))
    }
    override fun onPause() { stopCamera(); super.onPause() }
    override fun onDestroy() { stopCamera(); worker.shutdown(); super.onDestroy() }
}
