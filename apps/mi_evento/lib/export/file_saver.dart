import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:share_plus/share_plus.dart';

/// Entrega un archivo generado al usuario. En Android abre «Compartir» (WhatsApp, Bluetooth,
/// guardar en el teléfono…); en Windows abre «Guardar como…». Se puede sustituir en las pruebas.
abstract class FileSaver {
  /// Devuelve true si se guardó/compartió, false si el usuario canceló.
  Future<bool> save(String filename, Uint8List bytes,
      {required String mimeType});
}

class PlatformFileSaver implements FileSaver {
  const PlatformFileSaver();

  @override
  Future<bool> save(String filename, Uint8List bytes,
      {required String mimeType}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final r = await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType)],
        fileNameOverrides: [filename],
      ));
      return r.status != ShareResultStatus.dismissed;
    }
    final ext = filename.contains('.') ? filename.split('.').last : '';
    final loc = await fs.getSaveLocation(
      suggestedName: filename,
      acceptedTypeGroups: [
        fs.XTypeGroup(
            label: ext.toUpperCase(), extensions: [ext], mimeTypes: [mimeType])
      ],
    );
    if (loc == null) return false;
    await fs.XFile.fromData(bytes, mimeType: mimeType, name: filename)
        .saveTo(loc.path);
    return true;
  }
}

/// Para pruebas: guarda en memoria lo que se «exportó».
class MemoryFileSaver implements FileSaver {
  final saved = <String, Uint8List>{};
  @override
  Future<bool> save(String filename, Uint8List bytes,
      {required String mimeType}) async {
    saved[filename] = bytes;
    return true;
  }
}
