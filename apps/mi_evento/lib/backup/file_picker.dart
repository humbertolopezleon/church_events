import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as fs;

/// Archivo elegido por el usuario.
class PickedFile {
  const PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Pide al usuario que elija un archivo (se sustituye en las pruebas).
abstract class FilePick {
  /// Pide un archivo CSV (datos o copia de seguridad: la app solo usa CSV).
  Future<PickedFile?> pick();
}

class PlatformFilePick implements FilePick {
  const PlatformFilePick();
  @override
  Future<PickedFile?> pick() async {
    final f = await fs.openFile(acceptedTypeGroups: [
      const fs.XTypeGroup(
          label: 'Hoja de cálculo (CSV)',
          extensions: ['csv', 'txt'],
          mimeTypes: ['text/csv', 'text/plain', 'application/vnd.ms-excel']),
    ]);
    if (f == null) return null;
    return PickedFile(f.name, await f.readAsBytes());
  }
}

class MemoryFilePick implements FilePick {
  MemoryFilePick([this.file]);
  PickedFile? file;
  @override
  Future<PickedFile?> pick() async => file;
}
