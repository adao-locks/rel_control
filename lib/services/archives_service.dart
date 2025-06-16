import 'package:file_picker/file_picker.dart';
import 'package:rel_control/db.dart';
import 'package:uuid/uuid.dart';

class archivesService {
  final uuid = const Uuid();

  Future<void> addarchives({
    required String clientId,
    required String name,
    required String description,
    String? archives_path,
  }) async {
    final conn = await DB.connect();
    await conn.query(
      '''
      INSERT INTO archives (
        id, name, description, archives_path, date_registered, date_updated, client_id
      )
      VALUES (
        @id, @name, @description, @archives_path, @date_registered, @date_updated, @clientId
      )
      ''',
      substitutionValues: {
        'id': uuid.v4(),
        'name': name,
        'description': description,
        'archives_path': archives_path,
        'date_registered': DateTime.now().toIso8601String(),
        'date_updated': DateTime.now().toIso8601String(),
        'clientId': clientId,
      },
    );
  }

  Future<String?> selecionarArquivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return result.files.single.name;
    }
    return null;
  }
}
