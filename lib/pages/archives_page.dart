import 'dart:io';
import 'package:open_file/open_file.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/models/client.dart';
import 'package:uuid/uuid.dart';
import 'package:rel_control/models/archives.dart';
import 'package:rel_control/providers/user_state.dart';
import 'package:path_provider/path_provider.dart';

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

  final List<Archives> archivesList = [];
  final List<Archives> filteredArchives = [];

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final formController = TextEditingController();
  final environmentController = TextEditingController();

  String? editingArchiveId;
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
    final environmentFilter = environmentController.text.toUpperCase().trim();

    setState(() {
      filteredArchives.clear();
      filteredArchives.addAll(
        archivesList.where((client) {
          return client.name.toUpperCase().contains(nameFilter) &&
              client.description.toUpperCase().contains(descFilter) &&
              client.form.toUpperCase().contains(formFilter) &&
              client.environment.toUpperCase().contains(environmentFilter);
        }),
      );
    });
  }

  Future<void> loadData() async {
    final conn = await DB.connect();

    final result = await conn.query(
      '''
      SELECT id, name, description, form, environment, archives_path, date_registered, date_updated
      FROM archives
      WHERE client_id = @clientId
      ''',
      substitutionValues: {'clientId': widget.client.id},
    );

    final loadedArchives = result.map((row) {
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
      widget.client.archives = loadedArchives;
      archivesList.clear();
      archivesList.addAll(loadedArchives);
      filteredArchives.clear();
      filteredArchives.addAll(loadedArchives);
    });
  }

  void addArchives() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty)
      return;

    final archives = Archives(
      id: uuid.v4(),
      name: nameController.text,
      description: descriptionController.text,
      form: formController.text,
      environment: environmentController.text,
      archive: selectedArchive,
      dateRegistered: DateTime.now(),
      dateUpdated: DateTime.now(),
    );

    final conn = await DB.connect();
    await conn.query(
      '''
      INSERT INTO archives (id, name, description, form, environment, archives_path, date_registered, date_updated, client_id)
      VALUES (@id, @name, @description,  @form, @environment, @archives_path, @dateRegistered, @dateUpdated, @clientId)
      ''',
      substitutionValues: {
        'id': archives.id,
        'name': archives.name,
        'description': archives.description,
        'form': archives.form,
        'environment': archives.environment,
        'archives_path': archives.archive,
        'dateRegistered': archives.dateRegistered.toIso8601String(),
        'dateUpdated': archives.dateUpdated.toIso8601String(),
        'clientId': widget.client.id,
      },
    );

    setState(() {
      widget.client.archives.add(archives);
      archivesList.add(archives);
      nameController.clear();
      descriptionController.clear();
      formController.clear();
      environmentController.clear();
      selectedArchive = null;
      aplicarFiltro();
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

      Directory? downloadsDir;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        downloadsDir = await getDownloadsDirectory();
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final newPath = p.join(downloadsDir!.path, fileName);
      final newFile = await File(filePath).copy(newPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arquivo salvo em ${newFile.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao baixar o arquivo: $e')));
    }
  }

  void editArchive() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty)
      return;

    final conn = await DB.connect();

    if (editingArchiveId != null) {
      await conn.query(
        '''
        UPDATE archives 
        SET name = @name, description = @description, form = @form, environment = @environment, archives_path = @archives_path, date_updated = @dateUpdated
        WHERE id = @id
        ''',
        substitutionValues: {
          'id': editingArchiveId,
          'name': nameController.text,
          'description': descriptionController.text,
          'form': formController.text,
          'environment': environmentController.text,
          'archives_path': selectedArchive,
          'dateUpdated': DateTime.now().toIso8601String(),
        },
      );

      final index = widget.client.archives.indexWhere(
        (a) => a.id == editingArchiveId,
      );
      if (index != -1) {
        setState(() {
          widget.client.archives[index] = Archives(
            id: editingArchiveId!,
            name: nameController.text,
            description: descriptionController.text,
            form: formController.text,
            environment: environmentController.text,
            archive: selectedArchive,
            dateRegistered: widget.client.archives[index].dateRegistered,
            dateUpdated: DateTime.now(),
          );
        });
      }
    }

    setState(() {
      nameController.clear();
      descriptionController.clear();
      formController.clear();
      environmentController.clear();
      selectedArchive = null;
      editingArchiveId = null;
      aplicarFiltro();
      loadData();
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

      final destino = File(
        p.join(pastaDestino.path, widget.client.codcli, nomeArquivo),
      );
      if (!destino.existsSync()) {
        destino.createSync(recursive: true);
      }
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

    final result = await conn.query(
      'SELECT archives_path FROM archives WHERE id = @id',
      substitutionValues: {'id': archiveId},
    );

    String? archivePath;
    if (result.isNotEmpty && result.first[0] != null) {
      archivePath = result.first[0] as String;
    }
    if (archivePath != null && File(archivePath).existsSync()) {
      try {
        await File(archivePath).delete();
        await conn.execute(
          'DELETE FROM archives WHERE id = @id',
          substitutionValues: {'id': archiveId},
        );
      } catch (e) {
        debugPrint('Erro ao excluir arquivo: $e');
      }
    }
    
    setState(() {
      nameController.clear();
      descriptionController.clear();
      formController.clear();
      environmentController.clear();
      selectedArchive = null;
      editingArchiveId = null;
      aplicarFiltro();
      loadData();
    });
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
    final user = Provider.of<UserState>(context);
    final tipoUsuario = user.tipoUsuario;
    return Scaffold(
      appBar: AppBar(
        title: Text('REGISTROS DE ${widget.client.name}'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(125, 192, 21, 21),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.grey.shade300,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        prefixIcon: Icon(Icons.title),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(Icons.description),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: formController,
                            decoration: const InputDecoration(
                              labelText: 'Local',
                              prefixIcon: Icon(Icons.map_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              final upperValue = value.toUpperCase();
                              if (value != upperValue) {
                                formController.value = formController.value.copyWith(
                                  text: upperValue,
                                  selection: TextSelection.collapsed(offset: upperValue.length),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: environmentController,
                            decoration: const InputDecoration(
                              labelText: 'Ambiente',
                              prefixIcon: Icon(Icons.dashboard_customize_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              final upperValue = value.toUpperCase();
                              if (value != upperValue) {
                                environmentController.value = environmentController.value.copyWith(
                                  text: upperValue,
                                  selection: TextSelection.collapsed(offset: upperValue.length),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (tipoUsuario == 'admin') ...[
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: selectArchive,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Anexar Arquivo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (selectedArchive != null)
                        Row(
                          children: [
                            const Icon(Icons.insert_drive_file, size: 20, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                selectedArchive!.split(Platform.pathSeparator).last,
                                style: const TextStyle(fontStyle: FontStyle.italic),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        const Center(
                          child: Text(
                            'Nenhum arquivo selecionado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                    if (tipoUsuario == 'admin')
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: editingArchiveId == null ? addArchives : editArchive,
                          icon: Icon(editingArchiveId == null ? Icons.save : Icons.update),
                          label: Text(editingArchiveId == null ? 'Salvar Registro' : 'Atualizar Registro'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            backgroundColor: editingArchiveId == null ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
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
                      itemCount: filteredArchives.length,
                      itemBuilder: (context, index) {
                        final archives = filteredArchives[index];
                        return Card(
                          child: ListTile(
                            title: Text(archives.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📄 Descricao: ${archives.description}'),
                                Text('🧭 Tela: ${archives.form} | Ambiente: ${archives.environment}',),
                                Text('📁 Arquivo: ${archives.archive?.split(Platform.pathSeparator).last ?? "Nenhum arquivo"}',),
                                Text('📅 Criado: ${formatardate(archives.dateRegistered)}',),
                                Text('🔄 Atualizado: ${formatardate(archives.dateUpdated)}',),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: tipoUsuario == 'admin'
                                ? Row(
                                    //admins
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new, color: Colors.green),
                                        onPressed: () {
                                          if (archives.archive != null &&
                                              File(
                                                archives.archive!,
                                              ).existsSync()) {
                                            OpenFile.open(archives.archive!);
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Arquivo não encontrado.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download, color: Colors.indigo),
                                        onPressed: () {
                                          if (archives.archive != null &&
                                              File(
                                                archives.archive!,
                                              ).existsSync()) {
                                            downloadFile(
                                              archives.archive!,
                                              context,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Arquivo não encontrado.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () {
                                          setState(() {
                                            nameController.text = archives.name;
                                            descriptionController.text =
                                                archives.description;
                                            formController.text = archives.form;
                                            environmentController.text =
                                                archives.environment;
                                            selectedArchive = archives.archive;
                                            editingArchiveId = archives.id;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => confirmDelete(archives.id),
                                      ),
                                    ],
                                  )
                                : Row(
                                    //users
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        //OpenButton
                                        icon: const Icon(Icons.open_in_new),
                                        onPressed: () {
                                          if (archives.archive != null &&
                                              File(
                                                archives.archive!,
                                              ).existsSync()) {
                                            OpenFile.open(archives.archive!);
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Arquivo não encontrado.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        //DownloadButton
                                        icon: const Icon(Icons.download),
                                        onPressed: () {
                                          if (archives.archive != null &&
                                              File(
                                                archives.archive!,
                                              ).existsSync()) {
                                            downloadFile(
                                              archives.archive!,
                                              context,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Arquivo não encontrado.',
                                                ),
                                              ),
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
