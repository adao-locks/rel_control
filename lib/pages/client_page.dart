import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/pages/archives_page.dart';
import 'package:uuid/uuid.dart';
import 'package:rel_control/models/client.dart';

class ClientPage extends StatefulWidget {
  final String tipoUsuario;
  const ClientPage({super.key, required this.tipoUsuario, required username});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final uuid = const Uuid();
  final List<Client> clients = [];
  final TextEditingController codcliController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarclients();
    codcliController.addListener(aplicarFiltro);
    nameController.addListener(aplicarFiltro);
  }

  Future<void> carregarclients() async {
    final conn = await DB.connect();
    final resultado = await conn.query('SELECT id, codcli, name FROM client');

    setState(() {
      clients.clear();
      clients.addAll(resultado.map((row) {
        return Client(
          id: row[0],
          codcli: row[1].toString(),
          name: row[2],
          archives: [],
        );
      }));
    });
  }

  void aplicarFiltro() {
    final codcliFilter = codcliController.text.toUpperCase().trim();
    final nameFilter = nameController.text.toUpperCase().trim();

    setState(() {
      clients.retainWhere((client) {
        return client.codcli.contains(codcliFilter) && client.name.toUpperCase().contains(nameFilter);
      });
    });
  }

  void adicionarclient() async {
    if (nameController.text.isEmpty) return;

    final id = uuid.v4();
    final codcli = codcliController.text;
    final name = nameController.text;

    final conn = await DB.connect();
    await conn.query(
      'INSERT INTO client (id, codcli, name) VALUES (@id, @codcli, @name)',
      substitutionValues: {'id': id, 'codcli': codcli, 'name': name},
    );

    nameController.clear();
    codcliController.clear();
    await carregarclients();
  }

  void abrirarchives(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchivesPage(client: client, tipoUsuario: '',),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('clients'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: codcliController,
                        maxLength: 5,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Codcli',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        final upperValue = value.toUpperCase();
                        if (value != upperValue) {
                          codcliController.value = codcliController.value.copyWith(
                            text: upperValue,
                            selection: TextSelection.collapsed(offset: upperValue.length),
                          );
                        }
                      },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'nome do cliente',
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
                    ),
                    const SizedBox(width: 20),
                    if (widget.tipoUsuario == 'admin')
                      ElevatedButton.icon(
                        onPressed: adicionarclient,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: clients.isEmpty
                  ? const Center(
                      child: Text('Nenhum cliente cadastrado.'),
                    )
                  : ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return Card(
                          child: ListTile(
                            // ignore: prefer_interpolation_to_compose_strings
                            title: Text(client.codcli + ' - ' + client.name),
                            subtitle: Text('${client.archives.length} registro(s)'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => abrirarchives(client),
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
