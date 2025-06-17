import 'package:rel_control/models/archives.dart';

class Client {
  final String id;
  final String codcli;
  final String name;
  List<Archives> archives;
  final int archivesCount;

  Client({
    required this.id,
    required this.codcli,
    required this.name,
    this.archives = const [],
    this.archivesCount = 0,
  });
}