import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class ImageService {
  /// Convierte una imagen a base64 para guardar en Firestore
  static String imageToBase64(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    return base64Encode(bytes);
  }

  /// Convierte base64 a bytes para mostrar la imagen
  static Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  /// Verifica si una cadena es base64 válida
  static bool isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}
