import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_client/dance_trainer_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'pose_engine.dart';
import 'repository.dart';
import 'management_screens.dart';

String readableError(Object error) => error is TrainingError
    ? error.message
    : error is StateError
    ? error.message.toString()
    : 'Could not complete this action. Check your connection and try again.';
String durationLabel(int ms) =>
    '${ms ~/ 60000}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}';

class TrainingHome extends StatefulWidget {
  const TrainingHome({
    super.key,
    required this.repository,
    required this.onSignOut,
  });
  final TrainingRepository repository;
  final Future<void> Function() onSignOut;
  @override
  State<TrainingHome> createState() => _TrainingHomeState();
}

class _TrainingHomeState extends State<TrainingHome> {
  late Future<List<TrainingCatalogEntry>> _catalog;
  int _tab = 0;
  String? _syncMessage;
  Timer? _retryTimer;
  bool _syncing = false;
  @override
  void initState() {
    super.initState();
    _catalog = widget.repository.client.catalog.list();
    _sync(force: false);
    _retryTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sync(force: false),
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _sync({bool force = true}) async {
    if (kIsWeb || !Platform.isAndroid || _syncing) return;
    _syncing = true;
    try {
      final report = await widget.repository.syncPending(force: force);
      if (mounted) {
        setState(
          () => _syncMessage = report.pending > 0
              ? '${report.pending} runs await sync. Automatic retry is active.'
              : report.saved > 0
              ? '${report.saved} pending runs saved.'
              : null,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _syncMessage =
              'Completed runs are on this device. Tap sync to retry.',
        );
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Dance Trainer'),
      actions: [
        IconButton(
          tooltip: 'Sync saved runs',
          onPressed: _sync,
          icon: const Icon(Icons.sync),
        ),
      ],
    ),
    body: Column(
      children: [
        if (_syncMessage != null)
          MaterialBanner(
            content: Text(_syncMessage!),
            actions: [TextButton(onPressed: _sync, child: const Text('Sync'))],
          ),
        Expanded(
          child: switch (_tab) {
            0 => FutureBuilder<List<TrainingCatalogEntry>>(
              future: _catalog,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return RetryPanel(
                    message: readableError(snapshot.error!),
                    retry: () => setState(
                      () => _catalog = widget.repository.client.catalog.list(),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return CatalogList(
                  entries: snapshot.data!,
                  onChoose: (entry) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RoutineScreen(
                        repository: widget.repository,
                        entry: entry,
                      ),
                    ),
                  ),
                );
              },
            ),
            1 => ProgressScreen(repository: widget.repository),
            _ => ProfileScreen(
              repository: widget.repository,
              onSignOut: widget.onSignOut,
            ),
          },
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.music_note), label: 'Routines'),
        NavigationDestination(icon: Icon(Icons.insights), label: 'Progress'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}

class CatalogList extends StatelessWidget {
  const CatalogList({super.key, required this.entries, required this.onChoose});
  final List<TrainingCatalogEntry> entries;
  final void Function(TrainingCatalogEntry) onChoose;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Find your rhythm',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Follow a routine, review your movement, then practice one section.',
      ),
      const SizedBox(height: 24),
      if (entries.isEmpty) const Text('No routines have been published yet.'),
      for (final entry in entries)
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: const Icon(Icons.play_circle_outline, size: 44),
            title: Text(entry.title),
            subtitle: Text(
              '${durationLabel(entry.durationMs)} · ${entry.rankedAvailable ? 'Ranked available' : 'Development practice, unranked'}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onChoose(entry),
          ),
        ),
    ],
  );
}

class RetryPanel extends StatelessWidget {
  const RetryPanel({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({
    super.key,
    required this.repository,
    required this.entry,
    this.assignment,
  });
  final TrainingRepository repository;
  final TrainingCatalogEntry entry;
  final PracticeAssignment? assignment;
  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  bool _busy = false;
  double _progress = 0;
  String? _error;
  Future<void> _start() async {
    if (kIsWeb || !Platform.isAndroid) {
      setState(
        () => _error =
            'Camera training is available in the Android app. You can view your history here.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await widget.repository.download(
        widget.entry.mediaPath,
        widget.entry.mediaSha256,
        progress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RunScreen(
            repository: widget.repository,
            entry: widget.entry,
            video: file,
            assignment: widget.assignment,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.entry.title)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.directions_walk, size: 88),
        const SizedBox(height: 24),
        Text(
          widget.assignment == null
              ? 'Dance the routine'
              : 'Practice ${widget.assignment!.sectionId}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text('${durationLabel(widget.entry.durationMs)} · Bachata'),
        const SizedBox(height: 16),
        const Text(
          'Place your phone where your whole body fits in view. Use good lighting and clear space to move. Camera images stay on your phone; only pose coordinates are saved.',
        ),
        const SizedBox(height: 16),
        if (!widget.entry.rankedAvailable)
          const Text(
            'This development routine uses automatic pose checkpoints. Results are unranked until the content and scoring have been reviewed.',
          ),
        if (widget.assignment != null)
          Text(
            'Complete three repetitions with enough tracking coverage. Completed: ${widget.assignment!.completedRepetitions}/3.',
          ),
        const SizedBox(height: 24),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_busy)
          LinearProgressIndicator(value: _progress == 0 ? null : _progress),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _start,
          icon: const Icon(Icons.camera_alt),
          label: Text(_busy ? 'Preparing video…' : 'Set up camera'),
        ),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Leaderboard'),
              content: FutureBuilder<List<BoardEntry>>(
                future: widget.repository.client.training.leaderboard(
                  widget.entry.routineId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(readableError(snapshot.error!));
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Text(
                      'No ranked results yet. Development practice does not enter the leaderboard.',
                    );
                  }
                  return SizedBox(
                    width: 320,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final row in snapshot.data!)
                          ListTile(
                            title: Text(row.displayName),
                            trailing: Text('${row.score}'),
                          ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          child: const Text('View leaderboard'),
        ),
      ],
    ),
  );
}

class RunScreen extends StatefulWidget {
  const RunScreen({
    super.key,
    required this.repository,
    required this.entry,
    required this.video,
    this.assignment,
  });
  final TrainingRepository repository;
  final TrainingCatalogEntry entry;
  final File video;
  final PracticeAssignment? assignment;
  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with WidgetsBindingObserver {
  static const _camera = MethodChannel('dance/camera');
  static const _frames = EventChannel('dance/frames');
  final _engine = PoseEngine();
  late final TrainingBundle _bundle = TrainingBundle.fromJson(
    jsonDecode(widget.entry.bundleJson),
  );
  late final VideoPlayerController _player = VideoPlayerController.file(
    widget.video,
  );
  StreamSubscription<dynamic>? _subscription;
  Timer? _clock;
  final _frameWatch = Stopwatch();
  String _phase = 'loading', _message = 'Loading the pose model…';
  TrainingAttempt? _attempt;
  final _observations = <TrainingObservation>[];
  int _generation = 0,
      _anchorUs = 0,
      _anchorMs = 0,
      _stableSince = 0,
      _lastCapture = 0,
      _sequence = 0,
      _segment = 0,
      _count = 0;
  bool _tracking = false,
      _inferBusy = false,
      _mirror = false,
      _interrupted = false,
      _clockBusy = false;
  Future<void> _writes = Future.value();
  Map<String, dynamic>? _provisional;
  int get _startMs => widget.assignment == null
      ? 0
      : wholeNumber(
          _bundle.sections.firstWhere(
            (s) => s['id'] == widget.assignment!.sectionId,
          )['startMs'],
        );
  int get _endMs => widget.assignment == null
      ? _bundle.durationMs
      : wholeNumber(
          _bundle.sections.firstWhere(
            (s) => s['id'] == widget.assignment!.sectionId,
          )['endMs'],
        );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await _player.initialize();
      await _player.seekTo(Duration(milliseconds: _startMs));
      final permission = await _camera.invokeMethod<bool>('permission');
      if (permission != true) {
        throw StateError(
          'Camera access is needed to track your movement. Allow it in Android settings, then reopen this routine.',
        );
      }
      await _engine.load(await widget.repository.model());
      if (!mounted) return;
      _subscription = _frames.receiveBroadcastStream().listen(
        (value) => _onFrame(Map<Object?, Object?>.from(value as Map)),
        onError: (Object e) => _error(readableError(e)),
      );
      setState(() {
        _phase = 'setup';
        _message =
            'Step back until your shoulders, hands and feet stay visible.';
      });
      await _camera.invokeMethod<void>('start');
      _frameWatch.start();
      _clock = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _refreshClock(),
      );
    } catch (e) {
      _error(readableError(e));
    }
  }

  Future<void> _refreshClock() async {
    if (['setup', 'counting', 'running'].contains(_phase) &&
        _frameWatch.elapsed > const Duration(seconds: 10)) {
      _error('Camera observations stopped. Restart the routine.');
      return;
    }
    if (_clockBusy || _phase != 'running') return;
    _clockBusy = true;
    try {
      final position = await _player.position;
      final now = await _camera.invokeMethod<int>('clock');
      if (!mounted || _phase != 'running') return;
      if (position != null && now != null) {
        _anchorMs = position.inMilliseconds;
        _anchorUs = now;
      }
      if (_player.value.hasError) {
        _error('Video playback failed. Restart the routine.');
        return;
      }
      if (_anchorMs >= _endMs - 100 || _player.value.isCompleted) {
        await _finish();
      }
    } catch (_) {
      _error('Playback timing could not be read. Restart the routine.');
    } finally {
      _clockBusy = false;
    }
  }

  Future<void> _onFrame(Map<Object?, Object?> frame) async {
    if (_inferBusy) return;
    _frameWatch.reset();
    _inferBusy = true;
    final token = _generation;
    try {
      final capture = frame['captureUs'] as int;
      final points = await _engine.infer(frame, mirror: _mirror);
      if (!mounted || token != _generation) return;
      final pose = decodeLandmarks(
        points,
        (frame['width'] as num).toDouble(),
        (frame['height'] as num).toDouble(),
      );
      _tracking = pose.allObserved(trainingLandmarks);
      if (!_tracking || capture - _lastCapture > 1000000) {
        _stableSince = 0;
      } else if (_stableSince == 0) {
        _stableSince = capture;
      }
      if (_phase == 'setup') {
        setState(
          () => _message = _tracking
              ? 'Hold your position for two seconds.'
              : 'Keep your shoulders, hands and feet in view.',
        );
      }
      if (_phase == 'running' && _anchorUs > 0 && capture > _lastCapture) {
        // Capture time, never inference-completion time, sets the content time.
        final ms = _anchorMs + ((capture - _anchorUs) / 1000).round();
        if ((capture - _anchorUs).abs() > 2000000) {
          throw StateError(
            'This camera clock cannot be aligned with playback. Restart on a supported Android device.',
          );
        }
        if (ms >= _startMs &&
            ms <= _endMs &&
            // Bound evidence size on fast phones using capture-derived time.
            (_observations.isEmpty || ms - _observations.last.timeMs >= 100)) {
          final observation = TrainingObservation(
            timeMs: ms,
            width: (frame['width'] as num).toDouble(),
            height: (frame['height'] as num).toDouble(),
            points: points,
            sequence: _sequence++,
            segment: _segment,
          );
          _observations.add(observation);
          _writes = _writes.then(
            (_) => widget.repository.append(_attempt!.id!, observation),
          );
          await _writes;
          if (_sequence % 10 == 0) {
            _provisional = scoreTraining(
              _bundle,
              _observations,
              sectionId: widget.assignment?.sectionId,
              interrupted: _interrupted,
            );
          }
          if (mounted) {
            setState(
              () => _message = _tracking
                  ? 'Follow the instructor.'
                  : 'Tracking lost. Step back into view.',
            );
          }
        }
      }
      _lastCapture = capture;
      if (mounted && _phase == 'setup') setState(() {});
    } catch (e) {
      _error(readableError(e));
    } finally {
      _inferBusy = false;
      await _camera.invokeMethod<void>('ack');
    }
  }

  Future<void> _start() async {
    if (_phase != 'setup' ||
        !_tracking ||
        _lastCapture - _stableSince < 2000000) {
      return;
    }
    setState(() => _phase = 'counting');
    final token = _generation;
    try {
      final id =
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
      _attempt = await widget.repository.client.training.begin(
        _bundle.id,
        _bundle.version,
        poseModelHash,
        id,
        widget.assignment?.sectionId,
      );
      await widget.repository.saveRun(
        _attempt!,
        assignmentId: widget.assignment?.id,
        entry: widget.entry,
      );
      for (var n = 3; n > 0; n--) {
        if (!mounted || token != _generation) return;
        setState(() => _count = n);
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (!mounted || token != _generation) return;
      await _player.play();
      _anchorUs = (await _camera.invokeMethod<int>('clock'))!;
      _anchorMs = _startMs;
      setState(() => _phase = 'running');
    } catch (e) {
      _error(readableError(e));
    }
  }

  Future<void> _finish() async {
    if (_phase != 'running') return;
    setState(() => _phase = 'saving');
    _generation++;
    try {
      await _writes;
      if (_observations.isEmpty) {
        throw StateError(
          'No pose observations were captured. No score was saved.',
        );
      }
      await widget.repository.markComplete(_attempt!.id!, _endMs, _interrupted);
      await _player.pause();
      await _camera.invokeMethod<void>('stop');
      _provisional = scoreTraining(
        _bundle,
        _observations,
        sectionId: widget.assignment?.sectionId,
        interrupted: _interrupted,
      );
      TrainingAttempt? saved;
      try {
        saved = await widget.repository.sync(_attempt!.id!);
      } catch (_) {
        /* Durable evidence remains pending. */
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            repository: widget.repository,
            entry: widget.entry,
            attempt: saved ?? _attempt!,
            result: saved?.resultJson == null
                ? _provisional!
                : jsonObject(jsonDecode(saved!.resultJson!)),
            pending: saved == null,
            assignment: widget.assignment,
          ),
        ),
      );
    } catch (e) {
      _error(readableError(e));
    }
  }

  void _error(String message) {
    if (!mounted) return;
    _generation++;
    _clock?.cancel();
    _player.pause();
    _camera.invokeMethod<void>('stop');
    setState(() {
      _phase = 'error';
      _message = message;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        ['running', 'counting', 'setup'].contains(_phase)) {
      _interrupted = true;
      _segment++;
      _error(
        'The run stopped when the app left the screen. Restart to capture a complete attempt.',
      );
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _subscription?.cancel();
    _camera.invokeMethod<void>('stop');
    _player.dispose();
    // Native forward is asynchronous. Wait for it before releasing the model.
    Future<void>(() async {
      while (_inferBusy) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await _engine.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.entry.title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_player.value.isInitialized)
          AspectRatio(
            aspectRatio: _player.value.aspectRatio,
            child: VideoPlayer(_player),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const AndroidView(viewType: 'dance/preview'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _phase == 'counting' ? '$_count' : _message,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (_phase == 'running')
          Text(
            _provisional?['judgmentAvailable'] == true
                ? 'Provisional ${_provisional!['totalScore']} / 10000 · Tracking ${(finiteNumber(_provisional!['coverage']) * 100).round()}%'
                : 'Collecting observations · Tracking ${(((_provisional?['coverage'] as num?) ?? 0) * 100).round()}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        if (_phase == 'setup') ...[
          SwitchListTile(
            title: const Text('Mirror the movement comparison'),
            subtitle: const Text('Use the same setting for each attempt.'),
            value: _mirror,
            onChanged: (v) => setState(() {
              _mirror = v;
              _stableSince = 0;
            }),
          ),
          FilledButton(
            onPressed:
                _tracking &&
                    _stableSince > 0 &&
                    _lastCapture - _stableSince >= 2000000
                ? _start
                : null,
            child: const Text('Start dancing'),
          ),
        ],
        if (_phase == 'loading' || _phase == 'saving')
          const Center(child: CircularProgressIndicator()),
        if (_phase == 'error')
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to routine'),
          ),
      ],
    ),
  );
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.repository,
    required this.entry,
    required this.attempt,
    required this.result,
    required this.pending,
    this.assignment,
  });
  final TrainingRepository repository;
  final TrainingCatalogEntry entry;
  final TrainingAttempt attempt;
  final Map<String, dynamic> result;
  final bool pending;
  final PracticeAssignment? assignment;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _busy = false;
  String? _error;
  Future<void> _practice() async {
    setState(() => _busy = true);
    try {
      final assignment = await widget.repository.client.training.practice(
        widget.assignment?.sourceAttemptId ?? widget.attempt.id!,
      );
      if (!mounted) return;
      if (assignment.completed) {
        setState(
          () => _error = 'Drill complete. Return to routines for a full run.',
        );
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RoutineScreen(
            repository: widget.repository,
            entry: widget.entry,
            assignment: assignment,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Your result')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            r['judgmentAvailable'] == true
                ? '${r['totalScore']} / 10000'
                : 'Not enough tracking',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Tracking coverage ${(finiteNumber(r['coverage']) * 100).round()}%',
          ),
          Text(
            widget.pending
                ? 'Saved on this phone · pending sync'
                : 'Saved to your account',
          ),
          Text(r['rankReason'] as String),
          const SizedBox(height: 24),
          Text(
            r['feedback'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final section in jsonList(r['sections']))
            ListTile(
              title: Text(jsonObject(section)['title'] as String),
              subtitle: Text(
                'Tracking ${(finiteNumber(jsonObject(section)['coverage']) * 100).round()}%',
              ),
              trailing: Text(
                finiteNumber(jsonObject(section)['coverage']) >= 0.85
                    ? '${jsonObject(section)['score']}'
                    : 'Not enough tracking',
              ),
            ),
          if (_error != null) Text(_error!),
          if (!widget.pending &&
              (r['sectionId'] != null || widget.assignment != null))
            FilledButton(
              onPressed: _busy ? null : _practice,
              child: Text(
                widget.assignment == null
                    ? 'Practice this section'
                    : 'Repeat the section',
              ),
            ),
          if (widget.assignment != null && !widget.pending)
            const Text(
              'A repetition counts when tracking coverage is sufficient. Three repetitions complete the drill; completion does not imply mastery.',
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to routines'),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.onSignOut,
  });
  final TrainingRepository repository;
  final Future<void> Function() onSignOut;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  bool _visible = false, _loaded = false, _deleting = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await widget.repository.client.training.profile();
      if (!mounted) return;
      setState(() {
        _name.text = p.displayName;
        _visible = p.leaderboardVisible;
        _loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _message = readableError(e));
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This removes local queued runs immediately, then deletes your sign-in account, results, practice records and leaderboard entries. If the connection fails, you must retry account deletion. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.repository.deleteAccount();
      await widget.onSignOut();
    } catch (e) {
      if (mounted) setState(() => _message = readableError(e));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Your profile', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      TextField(
        controller: _name,
        maxLength: 40,
        decoration: const InputDecoration(labelText: 'Display name'),
      ),
      SwitchListTile(
        title: const Text('Show my ranked scores on leaderboards'),
        value: _visible,
        onChanged: (v) => setState(() => _visible = v),
      ),
      if (_message != null) Text(_message!),
      FilledButton(
        onPressed: !_loaded || _deleting
            ? null
            : () async {
                try {
                  await widget.repository.client.training.updateProfile(
                    _name.text,
                    _visible,
                  );
                  if (mounted) setState(() => _message = 'Profile saved.');
                } catch (e) {
                  if (mounted) setState(() => _message = readableError(e));
                }
              },
        child: const Text('Save profile'),
      ),
      if (!kIsWeb && Platform.isAndroid)
        TextButton(
          onPressed: _deleting
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DownloadsScreen(repository: widget.repository),
                  ),
                ),
          child: const Text('Manage downloads'),
        ),
      TextButton(
        onPressed: _deleting ? null : widget.onSignOut,
        child: const Text('Sign out'),
      ),
      TextButton(
        onPressed: _deleting ? null : _deleteAccount,
        child: Text(_deleting ? 'Deleting account…' : 'Delete account'),
      ),
    ],
  );
}
