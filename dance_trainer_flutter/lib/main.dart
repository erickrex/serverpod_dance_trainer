import 'package:dance_trainer_client/dance_trainer_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'screens/sign_in_screen.dart';
import 'training/repository.dart';
import 'training/screens.dart';

late final Client client;
late final TrainingRepository repository;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serverUrl = await getServerUrl();
  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();
  repository = TrainingRepository(client, serverUrl);
  try {
    await client.auth.initialize();
  } catch (_) {
    /* Sign-in remains available with a visible error on retry. */
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Dance Trainer',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff944563),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xfffaf7f2),
    ),
    home: Scaffold(
      body: SafeArea(
        child: SignInScreen(
          child: TrainingHome(
            repository: repository,
            onSignOut: client.auth.signOutDevice,
          ),
        ),
      ),
    ),
  );
}
