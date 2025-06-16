import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  runApp(const MyApp());
}

var uuid = const Uuid();

class Cliente {
  final String id;
  final String nome;
  List<Registro> registros;

  Cliente({
    required this.id,
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
  final TextEditingController nomeController = TextEditingController();

  void adicionarCliente() {
    if (nomeController.text.isEmpty) return;
    setState(() {
      clientes.add(
        Cliente(id: uuid.v4(), nome: nomeController.text, registros: []),
      );
      nomeController.clear();
    });
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
                    Expanded(
                      child: TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Cliente',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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

  void adicionarRegistro() {
    if (nomeController.text.isEmpty || descricaoController.text.isEmpty) return;
    setState(() {
      final registro = Registro(
        id: uuid.v4(),
        nome: nomeController.text,
        descricao: descricaoController.text,
        arquivo: arquivoSelecionado,
        dataCadastro: DateTime.now(),
        dataAlteracao: DateTime.now(),
      );
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
}
