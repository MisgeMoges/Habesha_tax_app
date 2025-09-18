import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dhtnouhkf'; // Replace with your cloud name
  static const String _apiKey = '934471512314645'; // Replace with your API key
  static const String _apiSecret =
      'ii1t0iOhqWA1t3INXdgl_QlvV0o'; // Replace with your API secret
  static const String _uploadPreset =
      'church_app_uploads'; // Replace with your actual preset name

  /// Upload image to Cloudinary
  static Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      // Add upload preset (for unsigned uploads)
      request.fields['upload_preset'] = _uploadPreset;

      // Add folder if specified
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      } else {
        print('Cloudinary upload failed: ${jsonData['error']}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Upload image with transformations
  static Future<String?> uploadImageWithTransformations(
    File imageFile, {
    String? folder,
    int? width,
    int? height,
    String? crop = 'fill',
    int? quality = 80,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      request.fields['upload_preset'] = _uploadPreset;

      if (folder != null) {
        request.fields['folder'] = folder;
      }

      // Add transformations
      if (width != null || height != null) {
        String transformation = '';
        if (width != null) transformation += 'w_$width,';
        if (height != null) transformation += 'h_$height,';
        if (crop != null) transformation += 'c_$crop,';
        if (quality != null) transformation += 'q_$quality';

        request.fields['transformation'] = transformation;
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      } else {
        print('Cloudinary upload failed: ${jsonData['error']}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      // Generate signature for signed requests
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(publicId, timestamp);

      var response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      var jsonData = json.decode(response.body);
      return jsonData['result'] == 'ok';
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  /// Generate signature for signed requests
  static String _generateSignature(String publicId, int timestamp) {
    // This is a simplified signature generation
    // In production, you should implement proper signature generation
    final params = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    return base64.encode(utf8.encode(params)).substring(0, 16);
  }

  /// Get optimized image URL
  static String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop = 'fill',
    int? quality = 80,
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    // Insert transformations into Cloudinary URL
    final parts = originalUrl.split('/');
    final versionIndex = parts.indexWhere((part) => part.startsWith('v'));

    if (versionIndex != -1) {
      String transformation = '';
      if (width != null) transformation += 'w_$width,';
      if (height != null) transformation += 'h_$height,';
      if (crop != null) transformation += 'c_$crop,';
      if (quality != null) transformation += 'q_$quality';

      if (transformation.isNotEmpty) {
        transformation = transformation.substring(
          0,
          transformation.length - 1,
        ); // Remove last comma
        parts.insert(versionIndex + 1, transformation);
      }
    }

    return parts.join('/');
  }

  /// List available upload presets
  static Future<List<String>> listUploadPresets() async {
    try {
      print('Fetching upload presets...');
      var response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/upload_presets'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_apiKey:$_apiSecret'))}',
        },
      );

      print('Upload presets response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final presets = List<String>.from(
          data['presets'].map((p) => p['name']),
        );
        print('Available presets: $presets');
        return presets;
      } else {
        print('Failed to fetch presets: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching presets: $e');
      return [];
    }
  }

  /// Test Cloudinary connection
  //   static Future<bool> testConnection() async {
  //     try {
  //       print('Testing Cloudinary connection...');
  //       print('Cloud Name: $_cloudName');
  //       print('API Key: $_apiKey');
  //       print('Upload Preset: $_uploadPreset');

  //       // Try to get account info
  //       var response = await http.get(
  //         Uri.parse(
  //           'https://api.cloudinary.com/v1_1/$_cloudName/resources/image',
  //         ),
  //         headers: {
  //           'Authorization':
  //               'Basic ${base64Encode(utf8.encode('$_apiKey:$_apiSecret'))}',
  //         },
  //       );

  //       print('Cloudinary test response: ${response.statusCode}');
  //       if (response.statusCode == 200) {
  //         print('Cloudinary connection successful!');
  //         return true;
  //       } else {
  //         print('Cloudinary test failed: ${response.body}');
  //         return false;
  //       }
  //     } catch (e) {
  //       print('Cloudinary test error: $e');
  //       return false;
  //     }
  //   }
}
