// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/models/archives.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AllArchivesPage extends StatefulWidget {
  final String tipoUsuario;

  const AllArchivesPage({super.key, required this.tipoUsuario});

  @override
  State<AllArchivesPage> createState() => _AllArchivesPageState();
}

class _AllArchivesPageState extends State<AllArchivesPage> {
  final uuid = const Uuid();

  final List<Archives> archivesList = [];
  final List<Archives> filteredArchives = [];

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final formController = TextEditingController();
  final environmentController = TextEditingController();

  String? selectedArchive;

  @override
  void initState() {
    super.initState();
    loadData();
    nameController.addListener(aplicarFiltro);
    descriptionController.addListener(aplicarFiltro);
    formController.addListener(aplicarFiltro);
    environmentController.addListener(aplicarFiltro);
  }

  void aplicarFiltro() {
    final nameFilter = nameController.text.toUpperCase().trim();
    final descFilter = descriptionController.text.toUpperCase().trim();
    final formFilter = formController.text.toUpperCase().trim();
    final idEmpresaFilter = environmentController.text.toUpperCase().trim();

    setState(() {
      filteredArchives.clear();
      filteredArchives.addAll(
        archivesList.where((a) {
          return a.name.toUpperCase().contains(nameFilter) &&
              a.description.toUpperCase().contains(descFilter) &&
              a.form.toUpperCase().contains(formFilter) &&
              a.environment.toUpperCase().contains(idEmpresaFilter);
        }),
      );
    });
  }

  Future<void> loadData() async {
    final conn = await DB.connect();

    final result = await conn.query('''
      SELECT id, name, description, form, environment, archives_path, date_registered, date_updated
      FROM archives
    ''');

    final loaded = result.map((row) {
      return Archives(
        id: row[0] as String,
        name: row[1] as String,
        description: row[2] as String,
        form: row[3] as String,
        environment: row[4] as String,
        archive: row[5] as String?,
        dateRegistered: row[6] as DateTime,
        dateUpdated: row[7] as DateTime,
      );
    }).toList();

    setState(() {
      archivesList.clear();
      archivesList.addAll(loaded);
      filteredArchives.clear();
      filteredArchives.addAll(loaded);
    });
  }

  Future<void> downloadFile(String filePath, BuildContext context) async {
    try {
      if (!File(filePath).existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo não encontrado.')),
        );
        return;
      }

      final fileName = p.basename(filePath);
      final downloadsDir = await getDownloadsDirectory();
      final newPath = p.join(downloadsDir!.path, fileName);
      final newFile = await File(filePath).copy(newPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arquivo salvo em ${newFile.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar o arquivo: $e')),
      );
    }
  }

  String formatarDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODOS OS REGISTROS'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(125, 192, 21, 21),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Titulo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: formController,
                    decoration: const InputDecoration(
                      labelText: 'Tela',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: environmentController,
                    decoration: const InputDecoration(
                      labelText: 'Ambiente',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredArchives.isEmpty
                  ? const Center(child: Text('Nenhum registro encontrado.'))
                  : ListView.builder(
                      itemCount: filteredArchives.length,
                      itemBuilder: (context, index) {
                        final archive = filteredArchives[index];
                        return Card(
                          child: ListTile(
                            title: Text(archive.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Descrição: ${archive.description}'),
                                Text('Tela: ${archive.form} - Ambiente: ${archive.environment}'),
                                Text('Arquivo: ${archive.archive ?? "Nenhum"}'),
                                Text('Atualizado: ${formatarDate(archive.dateUpdated)}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () {
                                    if (archive.archive != null && File(archive.archive!).existsSync()) {
                                      OpenFile.open(archive.archive!);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Arquivo não encontrado.')),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () {
                                    if (archive.archive != null && File(archive.archive!).existsSync()) {
                                      downloadFile(archive.archive!, context);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Arquivo não encontrado.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
