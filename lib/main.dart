import 'package:flutter/material.dart';
import 'package:rel_control/db.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  runApp(const MyApp());
  DB.connect();
}

var uuid = const Uuid();

class Cliente {
  final String id;
  final String codcli;
  final String nome;
  List<Registro> registros;

  Cliente({
    required this.id,
    required this.codcli,
    required this.nome,
    this.registros = const [],
  });
}

class Registro {
  final String id;
  String nome;
  String descricao;
  String? arquivo;
  DateTime dataCadastro;
  DateTime dataAlteracao;

  Registro({
    required this.id,
    required this.nome,
    required this.descricao,
    this.arquivo,
    required this.dataCadastro,
    required this.dataAlteracao,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Clientes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ClientePage(),
    );
  }
}

class ClientePage extends StatefulWidget {
  const ClientePage({super.key});
  @override
  State<ClientePage> createState() => _ClientePageState();
}

class _ClientePageState extends State<ClientePage> {
  final List<Cliente> clientes = [];
  final TextEditingController codcliController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarClientes();
  }

  Future<void> carregarClientes() async {
    final conn = await DB.connect();
    final resultado = await conn.query('SELECT id, codcli, nome FROM cliente');

    setState(() {
      clientes.clear();
      clientes.addAll(resultado.map((row) {
        return Cliente(
          id: row[0],
          codcli: row[1].toString(),
          nome: row[2],
          registros: [],
        );
      }));
    });
  }

  void adicionarCliente() async {
    if (nomeController.text.isEmpty) return;

    final String id = uuid.v4();
    final String codcli = codcliController.text;
    final String nome = nomeController.text;

    final conn = await DB.connect();

    await conn.query(
      'INSERT INTO cliente (id, codcli, nome) VALUES (@id, @codcli, @nome)',
      substitutionValues: {
        'id': id,
        'codcli': codcli,
        'nome': nome,
      },
    );

    nomeController.clear();
    codcliController.clear();
    await carregarClientes();
  }


  void abrirRegistros(Cliente cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroPage(cliente: cliente),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: codcliController,
                        decoration: const InputDecoration(
                          labelText: 'Codcli',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Cliente',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: adicionarCliente,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: clientes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum cliente cadastrado.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: clientes.length,
                      itemBuilder: (context, index) {
                        final cliente = clientes[index];
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(cliente.nome),
                            subtitle: Text(
                              '${cliente.registros.length} registro(s)',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => abrirRegistros(cliente),
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

class RegistroPage extends StatefulWidget {
  final Cliente cliente;

  const RegistroPage({super.key, required this.cliente});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  String? arquivoSelecionado;

  void adicionarRegistro() async {
    if (nomeController.text.isEmpty || descricaoController.text.isEmpty) return;

    final registro = Registro(
      id: uuid.v4(),
      nome: nomeController.text,
      descricao: descricaoController.text,
      arquivo: arquivoSelecionado,
      dataCadastro: DateTime.now(),
      dataAlteracao: DateTime.now(),
    );

    await DB.connect();
    final conn = await DB.connect();
    await conn.query(
      '''
      INSERT INTO registro (
        id, nome, descricao, arquivo_path, data_cadastro, data_alteracao, cliente_id
      )
      VALUES (
        @id, @nome, @descricao, @arquivo, @dataCadastro, @dataAlteracao, @clienteId
      )
      ''',
      substitutionValues: {
        'id': registro.id,
        'nome': registro.nome,
        'descricao': registro.descricao,
        'arquivo': registro.arquivo,
        'dataCadastro': registro.dataCadastro.toIso8601String(),
        'dataAlteracao': registro.dataAlteracao.toIso8601String(),
        'clienteId': widget.cliente.id,
      },
    );

    setState(() {
      widget.cliente.registros.add(registro);
      nomeController.clear();
      descricaoController.clear();
      arquivoSelecionado = null;
    });
  }


  Future<void> selecionarArquivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        arquivoSelecionado = result.files.single.name;
      });
    }
  }

  String formatarData(DateTime data) {
    return '${data.day}/${data.month}/${data.year} ${data.hour}:${data.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registros - ${widget.cliente.nome}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
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
                            arquivoSelecionado ?? 'Nenhum arquivo selecionado',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: adicionarRegistro,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Registro'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.cliente.registros.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum registro cadastrado.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.cliente.registros.length,
                      itemBuilder: (context, index) {
                        final registro = widget.cliente.registros[index];
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(registro.nome),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(registro.descricao),
                                const SizedBox(height: 4),
                                Text('Arquivo: ${registro.arquivo ?? "Nenhum"}'),
                                Text(
                                  'Cadastro: ${formatarData(registro.dataCadastro)}',
                                ),
                                Text(
                                  'Alteração: ${formatarData(registro.dataAlteracao)}',
                                ),
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
  
  @override
  void dispose() {
    DB.close();
    super.dispose();
  }
}
