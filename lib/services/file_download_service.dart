import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class FileDownloadService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.finsify/file_download',
  );

  Future<String?> saveToDownloads({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Saving directly to the Android Downloads folder is supported only on Android.',
      );
    }

    try {
      final result = await _channel.invokeMethod<String>('saveToDownloads', {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': mimeType,
      });

      return result;
    } on PlatformException catch (error) {
      throw Exception(
        '[${error.code}] ${error.message ?? 'Unable to save the XLSX file to Downloads.'}',
      );
    }
  }
}
