import 'package:rel_control/db.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';

class ClientService {
  final uuid = const Uuid();

  Future<List<Client>> getClients() async {
    final conn = await DB.connect();
    final resultado = await conn.query('SELECT id, codcli, name FROM client');
    return resultado.map((row) {
      return Client(
        id: row[0],
        codcli: row[1].toString(),
        name: row[2],
      );
    }).toList();
  }

  Future<void> addClient(String codcli, String name) async {
    final conn = await DB.connect();
    await conn.query(
      'INSERT INTO client (id, codcli, name) VALUES (@id, @codcli, @name)',
      substitutionValues: {
        'id': uuid.v4(),
        'codcli': codcli,
        'name': name,
      },
    );
  }
}
