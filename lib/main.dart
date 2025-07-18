import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(MaterialApp(title: 'Cadastro de Cliente', home: MyApp()));
}

class Cliente {
  final int id;
  final String nome;
  final int telefone;

  Cliente({required this.id, required this.nome, required this.telefone});

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(id: map['id'], nome: map['nome'], telefone: map['telefone']);
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Database db;
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();

  List<Cliente> clientes = [];

  @override
  void initState() {
    super.initState();
    abrirBanco();
  }

  Future<void> abrirBanco() async {
    final execDir = File(Platform.resolvedExecutable).parent.path;
    final dbPath = p.join(execDir, 'teste_cervantes.db');
    final dbFile = File(dbPath);

    if (!dbFile.existsSync()) {
      final data = await rootBundle.load('assets/teste_cervantes.db');
      final bytes = data.buffer.asUint8List();
      await dbFile.writeAsBytes(bytes, flush: true);
      print('Banco copiado para: $dbPath');
    } else {
      print('Banco já existe em: $dbPath');
    }

    db = await databaseFactory.openDatabase(dbPath);
    print('Banco aberto em: $dbPath');

    await listarClientes();
  }

  Future<void> inserirCliente() async {
    String nome = nomeController.text.trim();
    String telefoneText = telefoneController.text.trim();

    int? telefone = int.tryParse(telefoneText);

    try {
      await db.insert('clientes', {'nome': nome, 'telefone': telefone});
      nomeController.clear();
      telefoneController.clear();
      await listarClientes();
    } catch (e) {
      _mostrarErro('Erro ao inserir cliente: $e');
    }
  }

  Future<void> listarClientes() async {
    final List<Map<String, dynamic>> maps = await db.query('clientes');
    clientes = maps.map((map) => Cliente.fromMap(map)).toList();
    setState(() {});
  }

  Future<void> excluirCliente(int id) async {
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    await listarClientes();
  }

  Future<void> editarCliente(Cliente cliente) async {
    nomeController.text = cliente.nome;
    telefoneController.text = cliente.telefone.toString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: telefoneController,
              decoration: InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nomeController.clear();
              telefoneController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              String nome = nomeController.text.trim();
              String telefoneText = telefoneController.text.trim();

              int? telefone = int.tryParse(telefoneText);

              try {
                await db.update(
                  'clientes',
                  {'nome': nome, 'telefone': telefone},
                  where: 'id = ?',
                  whereArgs: [cliente.id],
                );
                nomeController.clear();
                telefoneController.clear();
                Navigator.pop(context);
                await listarClientes();
              } catch (e) {
                _mostrarErro('Erro ao editar cliente: $e');
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _mostrarErro(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Erro'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ok'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    telefoneController.dispose();
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Cadastro de Cliente'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Cadastro'),
              Tab(text: 'Clientes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: InputDecoration(labelText: 'Digite seu nome'),
                  ),
                  TextField(
                    controller: telefoneController,
                    decoration: InputDecoration(
                      labelText:
                          'Digite seu telefone com DDD (somente números)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: inserirCliente,
                    child: Text('Salvar Cliente'),
                  ),
                ],
              ),
            ),
            clientes.isEmpty
                ? Center(child: Text('Nenhum cliente cadastrado'))
                : ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final c = clientes[index];
                      return ListTile(
                        title: Text(c.nome),
                        subtitle: Text('Telefone: ${c.telefone}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => excluirCliente(c.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => editarCliente(c),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
