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
      await conn.execute(
        'DELETE FROM archives WHERE client_id = @id',
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
        title: const Text('Bem-vindo'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(125, 192, 21, 21),
        foregroundColor: Colors.black,
        actions: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              tipoUsuario.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Provider.of<UserState>(context, listen: false).clearUser();
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
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: codcliController,
                            maxLength: 5,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Código',
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            onChanged: (value) {
                              final upperValue = value.toUpperCase();
                              if (value != upperValue) {
                                nameController.value = nameController.value.copyWith(
                                  text: upperValue,
                                  selection: TextSelection.collapsed(offset: upperValue.length),
                                );
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Nome do Cliente',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (tipoUsuario == 'admin')
                          ElevatedButton.icon(
                            onPressed: adicionarClient,
                            icon: const Icon(Icons.add, color: Color.fromARGB(125, 192, 21, 21)),
                            label: const Text('Adicionar Cliente', style: TextStyle(color: Color.fromARGB(125, 192, 21, 21)),),
                          ),
                          ElevatedButton.icon(
                            onPressed: carregarClients,
                            icon: const Icon(Icons.refresh, color: Color.fromARGB(125, 192, 21, 21)),
                            label: const Text('Recarregar', style: TextStyle(color: Color.fromARGB(125, 192, 21, 21)),),
                          ),
                          ElevatedButton.icon(
                            onPressed: abrirAllArchives,
                            icon: const Icon(Icons.search, color: Color.fromARGB(125, 192, 21, 21)),
                            label: const Text('Pesquisa Extendida', style: TextStyle(color: Color.fromARGB(125, 192, 21, 21)),),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: allClients.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum cliente cadastrado.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => abrirArchives(client),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${client.codcli} - ${client.name}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${client.archivesCount} registro(s)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Excluir cliente',
                                    onPressed: () => confirmDelete(client.id),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
