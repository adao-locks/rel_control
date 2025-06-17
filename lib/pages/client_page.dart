import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/models/archives.dart';
import 'package:rel_control/pages/archives_page.dart';
import 'package:rel_control/providers/user_state.dart';
import 'package:uuid/uuid.dart';
import 'package:rel_control/models/client.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final uuid = const Uuid();
  final List<Client> allClients = [];
  final List<Client> filteredClients = [];

  final TextEditingController codcliController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarClients();
    codcliController.addListener(aplicarFiltro);
    nameController.addListener(aplicarFiltro);
  }

  Future<void> carregarClients() async {
    final conn = await DB.connect();
    final resultado = await conn.query('''
      SELECT c.id, c.codcli, c.name, 
      (SELECT COUNT(*) FROM archives a WHERE a.client_id = c.id) as archive_count
      FROM client c
    ''');

    setState(() {
      allClients.clear();
      filteredClients.clear();

      allClients.addAll(resultado.map((row) {
        return Client(
          id: row[0],
          codcli: row[1].toString(),
          name: row[2],
          archivesCount: row[3] as int, // 👈 Aqui
        );
      }));

      filteredClients.addAll(allClients);
    });
  }

  void aplicarFiltro() {
    final codcliFilter = codcliController.text.toUpperCase().trim();
    final nameFilter = nameController.text.toUpperCase().trim();

    setState(() {
      filteredClients.clear();
      filteredClients.addAll(allClients.where((client) {
        return client.codcli.contains(codcliFilter) &&
            client.name.toUpperCase().contains(nameFilter);
      }));
    });
  }

  void adicionarClient() async {
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
    await carregarClients();
  }

  void abrirArchives(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchivesPage(client: client, tipoUsuario: '',),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserState>(context);
    final tipoUsuario = user.tipoUsuario;
    final username = user.username;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo $username'),
        centerTitle: true,
        actions: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              tipoUsuario.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<UserState>(context, listen: false).clearUser();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
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
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Codcli',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Cliente',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (tipoUsuario == 'admin')
                      ElevatedButton.icon(
                        onPressed: adicionarClient,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: allClients.isEmpty
                  ? const Center(
                      child: Text('Nenhum cliente cadastrado.'),
                    )
                  : ListView.builder(
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        return Card(
                          child: ListTile(
                            title: Text('${client.codcli} - ${client.name}'),
                            subtitle: Text('${client.archivesCount} registro(s)'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => abrirArchives(client),
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
