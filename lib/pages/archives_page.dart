import 'dart:io';
import 'package:open_file/open_file.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/models/client.dart';
import 'package:uuid/uuid.dart';
import 'package:rel_control/models/archives.dart';

class ArchivesPage extends StatefulWidget {
  final Client client;
  final String tipoUsuario;

  const ArchivesPage({
    super.key, 
    required this.client, 
    required this.tipoUsuario,
  });

  @override
  State<ArchivesPage> createState() => _ArchivesPageState();
}

class _ArchivesPageState extends State<ArchivesPage> {
  final uuid = const Uuid();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedArchive;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final conn = await DB.connect();

    final result = await conn.query(
      '''
      SELECT id, name, description, archives_path, date_registered, date_updated
      FROM archives
      WHERE client_id = @clientId
      ''',
      substitutionValues: {
        'clientId': widget.client.id,
      },
    );

    final loadedArchives = result.map((row) {
      return Archives(
        id: row[0] as String,
        name: row[1] as String,
        description: row[2] as String,
        archive: row[3] as String?,
        dateRegistered: row[4] as DateTime,
        dateUpdated: row[5] as DateTime,
      );
    }).toList();

    setState(() {
      widget.client.archives = loadedArchives;
    });
  }

  void addArchives() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty) return;

    final archives = Archives(
      id: uuid.v4(),
      name: nameController.text,
      description: descriptionController.text,
      archive: selectedArchive,
      dateRegistered: DateTime.now(),
      dateUpdated: DateTime.now(),
    );

    final conn = await DB.connect();
    await conn.query(
      '''
      INSERT INTO archives (id, name, description, archives_path, date_registered, date_updated, client_id)
      VALUES (@id, @name, @description, @archives_path, @dateRegistered, @dateUpdated, @clientId)
      ''',
      substitutionValues: {
        'id': archives.id,
        'name': archives.name,
        'description': archives.description,
        'archives_path': archives.archive,
        'dateRegistered': archives.dateRegistered.toIso8601String(),
        'dateUpdated': archives.dateUpdated.toIso8601String(),
        'clientId': widget.client.id,
      },
    );

    setState(() {
      widget.client.archives.add(archives);
      nameController.clear();
      descriptionController.clear();
      selectedArchive = null;
    });
  }

  Future<void> selectArchive() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final origem = File(result.files.single.path!);
      final nomeArquivo = p.basename(origem.path);

      final pastaDestino = Directory('app_files');
      if (!pastaDestino.existsSync()) {
        pastaDestino.createSync(recursive: true);
      }

      final destino = File(p.join(pastaDestino.path, nomeArquivo));
      await origem.copy(destino.path);

      setState(() {
        selectedArchive = destino.path; // ← salva o caminho completo
      });
    }
  }

  String formatardate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> deleteArchive(String archiveId) async {
    final conn = await DB.connect();
    await conn.query(
      'DELETE FROM archives WHERE id = @id',
      substitutionValues: {'id': archiveId},
    );
  }

  void confirmDelete(String archiveId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja realmente excluir este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteArchive(archiveId);
      setState(() {
        widget.client.archives.removeWhere((a) => a.id == archiveId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('REGISTROS DE ${widget.client.name}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Titulo',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        final upperValue = value.toUpperCase();
                        if (value != upperValue) {
                          nameController.value = nameController.value.copyWith(
                            text: upperValue,
                            selection: TextSelection.collapsed(offset: upperValue.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        final upperValue = value.toUpperCase();
                        if (value != upperValue) {
                          descriptionController.value = descriptionController.value.copyWith(
                            text: upperValue,
                            selection: TextSelection.collapsed(offset: upperValue.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: selectArchive,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Anexar Arquivo'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedArchive ?? 'Nenhum arquivo selecionado',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: addArchives,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar registro'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.client.archives.isEmpty
                  ? const Center(child: Text('Nenhum registro cadastrado.'))
                  : ListView.builder(
                      itemCount: widget.client.archives.length,
                      itemBuilder: (context, index) {
                        final archives = widget.client.archives[index];
                        return Card(
                          child: ListTile(
                            title: Text(archives.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(archives.description),
                                Text('Arquivo: ${archives.archive ?? "Nenhum"} - ' + widget.tipoUsuario,),
                                Text('Cadastro: ${formatardate(archives.dateRegistered)}'),
                                Text('Alteração: ${formatardate(archives.dateUpdated)}'),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: widget.tipoUsuario == 'admin'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: () {
                                        if (archives.archive != null && File(archives.archive!).existsSync()) {
                                          OpenFile.open(archives.archive!);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Arquivo não encontrado.')),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => confirmDelete(archives.id),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () {
                                    if (archives.archive != null && File(archives.archive!).existsSync()) {
                                      OpenFile.open(archives.archive!);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Arquivo não encontrado.')),
                                      );
                                    }
                                  },
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
