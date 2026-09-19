import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// SMTP credentials are runtime environment variables, never source or logs.
/// Local development uses an SMTP capture service on loopback.
class VerificationMail {
  static Future<void> sendCode({
    required String email,
    required String code,
    required bool reset,
  }) async {
    final env = Platform.environment;
    final host = env['DANCE_SMTP_HOST'];
    final sender = env['DANCE_SMTP_FROM'];
    if (host == null || host.isEmpty || sender == null || sender.isEmpty) {
      throw StateError(
        'Email delivery is not configured. Set DANCE_SMTP_HOST and DANCE_SMTP_FROM.',
      );
    }
    final local = host == 'localhost' || host == '127.0.0.1';
    final smtp = SmtpServer(
      host,
      port: int.parse(env['DANCE_SMTP_PORT'] ?? '587'),
      username: env['DANCE_SMTP_USER'],
      password: env['DANCE_SMTP_PASSWORD'],
      ssl: env['DANCE_SMTP_SSL'] == 'true',
      allowInsecure: local,
    );
    final message = Message()
      ..from = Address(sender, 'Dance Trainer')
      ..recipients.add(email)
      ..subject = reset
          ? 'Reset your Dance Trainer password'
          : 'Verify your Dance Trainer account'
      ..text =
          'Your verification code is $code.\n\nIf you did not request this, ignore this email.';
    try {
      await send(message, smtp, timeout: const Duration(seconds: 15));
    } catch (_) {
      throw StateError('Email could not be delivered. Please try again later.');
    }
  }
}
