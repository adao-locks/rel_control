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
import 'package:file_selector/file_selector.dart';

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
  final idEmpresaController = TextEditingController();

  String? editingArchiveId;
  String? selectedArchive;

  @override
  void initState() {
    super.initState();
    loadData();
    nameController.addListener(aplicarFiltro);
    descriptionController.addListener(aplicarFiltro);
    formController.addListener(aplicarFiltro);
    idEmpresaController.addListener(aplicarFiltro);
  }

  void aplicarFiltro() {
    final nameFilter = nameController.text.toUpperCase().trim();
    final descFilter = descriptionController.text.toUpperCase().trim();
    final formFilter = formController.text.toUpperCase().trim();
    final idEmpresaFilter = idEmpresaController.text.toUpperCase().trim();

    setState(() {
      filteredArchives.clear();
      filteredArchives.addAll(
        archivesList.where((client) {
          return client.name.toUpperCase().contains(nameFilter) &&
              client.description.toUpperCase().contains(descFilter) &&
              client.form.toUpperCase().contains(formFilter) &&
              client.emp_id.toUpperCase().contains(idEmpresaFilter);
        }),
      );
    });
  }

  Future<void> loadData() async {
    final conn = await DB.connect();

    final result = await conn.query(
      '''
      SELECT id, name, description, form, emp_id, archives_path, date_registered, date_updated
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
        emp_id: row[4] as String,
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

  //--------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------
  void addArchives() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty)
      return;

    final archives = Archives(
      id: uuid.v4(),
      name: nameController.text,
      description: descriptionController.text,
      form: formController.text,
      emp_id: idEmpresaController.text,
      archive: selectedArchive,
      dateRegistered: DateTime.now(),
      dateUpdated: DateTime.now(),
    );

    final conn = await DB.connect();
    await conn.query(
      '''
      INSERT INTO archives (id, name, description, form, emp_id, archives_path, date_registered, date_updated, client_id)
      VALUES (@id, @name, @description,  @form, @emp_id, @archives_path, @dateRegistered, @dateUpdated, @clientId)
      ''',
      substitutionValues: {
        'id': archives.id,
        'name': archives.name,
        'description': archives.description,
        'form': archives.form,
        'emp_id': archives.emp_id,
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
      idEmpresaController.clear();
      selectedArchive = null;
      aplicarFiltro();
    });
  }

  //--------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------
  void editArchive() async {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty)
      return;

    final conn = await DB.connect();

    if (editingArchiveId != null) {
      await conn.query(
        '''
        UPDATE archives 
        SET name = @name, description = @description, form = @form, emp_id = @emp_id, archives_path = @archives_path, date_updated = @dateUpdated
        WHERE id = @id
        ''',
        substitutionValues: {
          'id': editingArchiveId,
          'name': nameController.text,
          'description': descriptionController.text,
          'form': formController.text,
          'emp_id': idEmpresaController.text,
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
            emp_id: idEmpresaController.text,
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
      idEmpresaController.clear();
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

    Future<void> downloadArchive({required List<Archives> archive}) async {
      final directory = await getDirectoryPath();
      if (directory == null) return;

      final path = '$directory/$nomeArquivo';
      final byte = await File(archive.archive!).readAsBytes();
      final file = File(path);
      await file.writeAsBytes(byte);

      print('Arquivo salvo em: $path');
    }

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
                            selection: TextSelection.collapsed(
                              offset: upperValue.length,
                            ),
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
                          descriptionController.value = descriptionController
                              .value
                              .copyWith(
                                text: upperValue,
                                selection: TextSelection.collapsed(
                                  offset: upperValue.length,
                                ),
                              );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: formController,
                            decoration: const InputDecoration(
                              labelText: 'Form',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              final upperValue = value.toUpperCase();
                              if (value != upperValue) {
                                formController.value = formController.value
                                    .copyWith(
                                      text: upperValue,
                                      selection: TextSelection.collapsed(
                                        offset: upperValue.length,
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: idEmpresaController,
                            decoration: const InputDecoration(
                              labelText: 'ID Empresa',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              final upperValue = value.toUpperCase();
                              if (value != upperValue) {
                                idEmpresaController.value = idEmpresaController
                                    .value
                                    .copyWith(
                                      text: upperValue,
                                      selection: TextSelection.collapsed(
                                        offset: upperValue.length,
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (tipoUsuario == 'admin')
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
                    if (tipoUsuario == 'admin')
                      ElevatedButton(
                        onPressed: editingArchiveId == null
                            ? addArchives
                            : editArchive,
                        child: Text(
                          editingArchiveId == null
                              ? 'Salvar Registro'
                              : 'Atualizar Registro',
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
                                Text(archives.description),
                                Text(
                                  'Tela: ${archives.form} - Emp_ID: ${archives.emp_id}',
                                ),
                                Text(
                                  'Arquivo: ${archives.archive ?? "Nenhum"}',
                                ),
                                Text(
                                  'Cadastro: ${formatardate(archives.dateRegistered)}',
                                ),
                                Text(
                                  'Última Alteração: ${formatardate(archives.dateUpdated)}',
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: tipoUsuario == 'admin'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        //DownloadButton
                                        icon: const Icon(Icons.download),
                                        onPressed: () {
                                          if (archives.archive != null &&
                                              File(
                                                archives.archive!,
                                              ).existsSync()) {
                                            downloadArchive(archives.archive!);
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
                                        //EditButton
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            nameController.text = archives.name;
                                            descriptionController.text =
                                                archives.description;
                                            formController.text = archives.form;
                                            idEmpresaController.text =
                                                archives.emp_id;
                                            selectedArchive = archives.archive;
                                            editingArchiveId = archives.id;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        //DeleteButton
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            confirmDelete(archives.id),
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    //DownloadButton
                                    icon: const Icon(Icons.download),
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
