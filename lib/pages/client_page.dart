import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rel_control/db.dart';
import 'package:rel_control/pages/all_archives_page.dart';
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
    codcliController.addListener(() {
      aplicarFiltro();
    });
    nameController.addListener(() {
      aplicarFiltro();
    });
  }

  void confirmDelete(String id) async {
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
      final conn = await DB.connect();
      await conn.execute(
        'DELETE FROM client WHERE id = @id',
        substitutionValues: {'id': id},
      );
    }
    carregarClients();
  }

  Future<void> carregarClients() async {
    final conn = await DB.connect();
    final resultado = await conn.query('''
      SELECT c.id, c.codcli, c.name, 
      (SELECT COUNT(*) FROM archives a WHERE a.client_id = c.id) as archive_count
      FROM client c
      ORDER BY CODCLI
    ''');

    setState(() {
      allClients.clear();
      filteredClients.clear();

      allClients.addAll(resultado.map((row) {
        return Client(
          id: row[0],
          codcli: row[1].toString(),
          name: row[2],
          archivesCount: row[3] as int,
        );
      }));

      filteredClients.addAll(allClients);
    });
  }

  Future<void> aplicarFiltro() async {
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

  void abrirAllArchives() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllArchivesPage(tipoUsuario: '',),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserState>(context);
    final tipoUsuario = user.tipoUsuario;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(125, 192, 21, 21),
        foregroundColor: Colors.black,
        actions: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              tipoUsuario.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
          Padding(padding: const EdgeInsets.all(8),),
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
                          labelText: 'Codigo',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        onChanged: (value) {
                              final upperValue = value.toUpperCase();
                              if (value != upperValue) {
                                nameController.value = nameController.value
                                  .copyWith(
                                    text: upperValue,
                                    selection: TextSelection.collapsed(
                                      offset: upperValue.length,
                                    ),
                                  );
                              }
                            },
                        decoration: const InputDecoration(
                          labelText: 'Nome...',
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
                      Padding(padding: const EdgeInsets.all(8),),
                      ElevatedButton.icon(
                        onPressed: carregarClients,
                        icon: const Icon(Icons.replay_outlined),
                        label: Text('Recarregar'),
                      ),
                      Padding(padding: const EdgeInsets.all(8),),
                      ElevatedButton.icon(
                        onPressed: abrirAllArchives,
                        icon: const Icon(Icons.search),
                        label: Text('Pesquisa Extendida'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12), // ajuste conforme necessário
                        ),
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
                            trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Excluir',
                                onPressed: () => confirmDelete(client.id),
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
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
