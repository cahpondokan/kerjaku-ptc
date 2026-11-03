import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppShareService {
  static const MethodChannel _channel = MethodChannel(
    'com.niam.ayani.kerjakuptc/whatsapp',
  );

  Future<WhatsAppShareOutcome> shareFilesToAdmin({
    required List<File> files,
    required String adminNumber,
    required String message,
  }) async {
    if (files.isEmpty) {
      throw ArgumentError('Tidak ada file yang akan dikirim.');
    }

    final normalized = normalizeNumber(adminNumber);
    if (!isValidNumber(normalized)) {
      throw FormatException('Nomor WhatsApp admin belum valid.');
    }

    try {
      final result = await _channel
          .invokeMethod<bool>('shareFilesToAdmin', <String, Object>{
            'phone': normalized,
            'message': message,
            'filePaths': files.map((file) => file.path).toList(),
          });
      if (result == true) {
        return WhatsAppShareOutcome.directWhatsApp;
      }
    } on PlatformException {
      // Fallback di bawah tetap dapat membagikan file jika intent khusus
      // WhatsApp tidak tersedia pada perangkat pengguna.
    } on MissingPluginException {
      // Fallback dibutuhkan saat hot-reload belum memuat kode native terbaru.
    }

    await SharePlus.instance.share(
      ShareParams(
        files: files.map((file) => XFile(file.path)).toList(),
        text: '$message\n\nNomor admin: +$normalized',
        subject: 'Dokumen Lembur PTC',
        title: 'Kirim dokumen lembur',
      ),
    );
    return WhatsAppShareOutcome.systemShareFallback;
  }

  static String normalizeNumber(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    }
    return digits;
  }

  static bool isValidNumber(String value) {
    final digits = normalizeNumber(value);
    return digits.length >= 10 && digits.length <= 15;
  }
}

enum WhatsAppShareOutcome { directWhatsApp, systemShareFallback }
