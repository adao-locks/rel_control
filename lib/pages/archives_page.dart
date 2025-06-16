import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/models/client.dart';
import 'package:uuid/uuid.dart';
import 'package:rel_control/models/archives.dart';

class ArchivesPage extends StatefulWidget {
  final Client client;
  const ArchivesPage({super.key, required this.client});

  @override
  State<ArchivesPage> createState() => _ArchivesPageState();
}

class _ArchivesPageState extends State<ArchivesPage> {
  final uuid = const Uuid();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedArchive;

  void adicionararchives() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty) return;

    final archives = Archives(
      id: uuid.v4(),
      name: nameController.text,
      description: descriptionController.text,
      archives: selectedArchive,
      dateRegistered: DateTime.now(),
      dateUpdated: DateTime.now(),
    );

    final conn = await DB.connect();
    await conn.query(
      '''
      INSERT INTO archives (id, name, description, archives_path, date_registered, date_updated, cliente_id)
      VALUES (@id, @name, @description, @archives_path, @dateRegistered, @dateUpdated, @clienteId)
      ''',
      substitutionValues: {
        'id': archives.id,
        'name': archives.name,
        'description': archives.description,
        'archives_path': archives.arquivo,
        'dateRegistered': archives.dateRegistered.toIso8601String(),
        'dateUpdated': archives.dateUpdated.toIso8601String(),
        'clienteId': widget.client.id,
      },
    );

    setState(() {
      widget.client.archives.add(archives);
      nameController.clear();
      descriptionController.clear();
      selectedArchive = null;
    });
  }

  Future<void> selecionarArquivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedArchive = result.files.single.name;
      });
    }
  }

  String formatardate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registros - ${widget.client.name}'),
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
                        labelText: 'Nome',
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
                          onPressed: selecionarArquivo,
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
                      onPressed: adicionararchives,
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
                                Text('Arquivo: ${archives.arquivo ?? "Nenhum"}'),
                                Text('Cadastro: ${formatardate(archives.dateRegistered)}'),
                                Text('Alteração: ${formatardate(archives.dateUpdated)}'),
                              ],
                            ),
                            isThreeLine: true,
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
