import 'package:postgres/postgres.dart';

class DB {
  static PostgreSQLConnection? _conn;


  static Future<PostgreSQLConnection> connect() async {
    if (_conn == null || _conn!.isClosed) {
      _conn = PostgreSQLConnection(
    '172.20.20.81', // IP
    5432,           // Porta
    'rel_control',  // Nome do banco
    username: 'postgres',
    password: 'GodNareba',
  );
      await _conn!.open();
    }
    return _conn!;
  }

  static Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }
}
