class Archives {
  final String id;
  String name;
  String description;
  String? arquivo;
  DateTime dateRegistered;
  DateTime dateUpdated;

  Archives({
    required this.id,
    required this.name,
    required this.description,
    this.arquivo,
    required this.dateRegistered,
    required this.dateUpdated, String? archives,
  });
}
