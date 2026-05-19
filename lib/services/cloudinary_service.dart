import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadResult {
  final String url;
  final String publicId;

  CloudinaryUploadResult({required this.url, required this.publicId});
}

class CloudinaryService {
  static const String cloudName = "dz2fbydyu";
  static const String uploadPreset = "spendy_receipts";

  // TODO: Replace with your own Cloudinary API key and secret.
  // For production, move these values to a secure backend or environment source.
  static const String apiKey = "YOUR_CLOUDINARY_API_KEY";
  static const String apiSecret = "YOUR_CLOUDINARY_API_SECRET";

  static Future<CloudinaryUploadResult?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        return CloudinaryUploadResult(
          url: data['secure_url'] as String,
          publicId: data['public_id'] as String,
        );
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      final signaturePayload =
          'public_id=$publicId&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(signaturePayload)).toString();

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/destroy",
      );

      final response = await http.post(
        url,
        body: {
          'api_key': apiKey,
          'public_id': publicId,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static String? extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 1 >= segments.length) {
        return null;
      }

      final publicPath = segments.sublist(uploadIndex + 1).join('/');
      final withoutVersion = publicPath.replaceFirst(RegExp(r'^v\d+/'), '');
      return withoutVersion.replaceFirst(RegExp(r'\.[^./]+$'), '');
    } catch (_) {
      return null;
    }
  }
}
