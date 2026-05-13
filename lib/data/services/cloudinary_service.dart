import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/constants/cloudinary_config.dart';

class CloudinaryService {
  const CloudinaryService();

  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String folder = 'gastro_delivery',
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError(
        'Cloudinary no está configurado. Usa --dart-define=CLOUDINARY_CLOUD_NAME y --dart-define=CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'No se pudo subir la imagen a Cloudinary (${response.statusCode}): $body',
      );
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError('Cloudinary no devolvió secure_url. Respuesta: $body');
    }

    return secureUrl;
  }
}

