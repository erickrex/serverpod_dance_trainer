import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:yaml/yaml.dart';

/// Creates local-only secrets without printing or replacing existing values.
void main() {
  final server = Directory.fromUri(
    Platform.script.resolve('../dance_trainer_server/'),
  );
  final passwords = File('${server.path}/config/passwords.yaml');
  final random = Random.secure();
  String secret() =>
      base64UrlEncode(List.generate(48, (_) => random.nextInt(256)));
  if (!passwords.existsSync()) {
    final data = <String, Object>{};
    for (final mode in ['development', 'test']) {
      data[mode] = {
        for (final key in [
          'database',
          'serviceSecret',
          'emailSecretHashPepper',
          'jwtHmacSha512PrivateKey',
          'jwtRefreshTokenHashPepper',
        ])
          key: secret(),
      };
    }
    // JSON is valid YAML and avoids escaping secrets into handwritten YAML.
    passwords.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }
  final values = loadYaml(passwords.readAsStringSync()) as Map;
  final env = File('${server.path}/.env');
  if (!env.existsSync()) {
    final entries = {
      'DANCE_DEV_DB_PASSWORD': (values['development'] as Map)['database'],
      'DANCE_TEST_DB_PASSWORD': (values['test'] as Map)['database'],
    };
    for (final value in entries.values) {
      if (value is! String || !RegExp(r'^[A-Za-z0-9_+=/-]+$').hasMatch(value)) {
        throw StateError(
          'Configure Compose .env manually for this password format.',
        );
      }
    }
    env.writeAsStringSync(
      entries.entries.map((e) => '${e.key}=${e.value}').join('\n') + '\n',
    );
  }
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['600', passwords.path, env.path]);
  }
  stdout.writeln(
    'Local configuration is ready. Existing secrets were preserved.',
  );
}
