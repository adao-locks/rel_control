import 'package:postgres/postgres.dart';

class DB {
  static PostgreSQLConnection? _conn;


  static Future<PostgreSQLConnection> connect() async {
    if (_conn == null || _conn!.isClosed) {
      _conn = PostgreSQLConnection(
        'localhost', 
        5432, 
        'postgres',
        username: 'postgres',
        password: 'admin123',
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
