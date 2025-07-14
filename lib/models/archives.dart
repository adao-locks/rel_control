class Archives {
  final String id;
  final String name;
  final String description;
  final String form;
  final String environment;
  final String? archive;
  final DateTime dateRegistered;
  final DateTime dateUpdated;

  Archives( {
    required this.id,
    required this.name,
    required this.description,
    required this.form,
    required this.environment,
    required this.archive,
    required this.dateRegistered,
    required this.dateUpdated,
  });
}
