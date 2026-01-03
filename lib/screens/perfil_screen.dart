import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/treino_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pesoController = TextEditingController();
  String? _novoFotoPath;

  @override
  void initState() {
    super.initState();
    final usuario = Provider.of<TreinoService>(context, listen: false).usuario;
    _nomeController.text = usuario.nome;
    _idadeController.text = usuario.idade.toString();
    _alturaController.text = usuario.altura.toString();
    _pesoController.text = usuario.peso.toString();
    _novoFotoPath = usuario.fotoPath;
  }

  Future<void> _alterarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${directory.path}/profile_$fileName');
      setState(() {
        _novoFotoPath = savedImage.path;
      });
    }
  }

  void _removerFoto() {
    setState(() {
      _novoFotoPath = null;
    });
  }

  void _salvar() {
    final nome = _nomeController.text;
    final idade = int.tryParse(_idadeController.text) ?? 0;
    final altura = double.tryParse(_alturaController.text.replaceAll(',', '.')) ?? 0.0;
    final peso = double.tryParse(_pesoController.text.replaceAll(',', '.')) ?? 0.0;

    // Atualize seu Service para aceitar a fotoPath também!
    Provider.of<TreinoService>(context, listen: false).atualizarPerfil(nome, idade, altura, peso, _novoFotoPath);
    Navigator.of(context).pop();
  }

  // WIDGET DA RÉGUA DE IMC
  Widget _buildIMCRuler(double imc, String? fotoPath) {
    // Limites para a barra visual (15 a 40)
    double minIMC = 15.0;
    double maxIMC = 40.0;
    double percent = (imc - minIMC) / (maxIMC - minIMC);
    if (percent < 0) percent = 0;
    if (percent > 1) percent = 1;

    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  // A Barra Colorida
                  Container(
                    height: 15,
                    width: width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.red],
                        stops: [0.1, 0.3, 0.5, 0.7, 1.0]
                      ),
                    ),
                  ),
                  // O Indicador (Foto do Usuário)
                  Positioned(
                    left: (width * percent) - 20, // -20 para centralizar o avatar de 40px
                    top: -12, // Subir um pouco
                    child: Column(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            image: fotoPath != null 
                              ? DecorationImage(image: FileImage(File(fotoPath)), fit: BoxFit.cover)
                              : null,
                            color: Colors.grey
                          ),
                          child: fotoPath == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                          child: Text(imc.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Magreza", style: TextStyle(fontSize: 10, color: Colors.blue)),
            Text("Normal", style: TextStyle(fontSize: 10, color: Colors.green)),
            Text("Sobrepeso", style: TextStyle(fontSize: 10, color: Colors.orange)),
            Text("Obesidade", style: TextStyle(fontSize: 10, color: Colors.red)),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Recalcula IMC em tempo real para visualização se mudar peso/altura nos inputs
    final currentAltura = double.tryParse(_alturaController.text.replaceAll(',', '.')) ?? 1.70;
    final currentPeso = double.tryParse(_pesoController.text.replaceAll(',', '.')) ?? 70.0;
    final imcCalculado = currentPeso / (currentAltura * currentAltura);

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto Editável
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _novoFotoPath != null ? FileImage(File(_novoFotoPath!)) : null,
                    child: _novoFotoPath == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _alterarFoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  if (_novoFotoPath != null)
                    Positioned(
                      top: 0, right: 0,
                      child: GestureDetector(
                        onTap: _removerFoto,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Nova Área de IMC Visual
            Text("Seu Status Atual", style: Theme.of(context).textTheme.titleMedium),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
              child: _buildIMCRuler(imcCalculado, _novoFotoPath),
            ),
            
            const SizedBox(height: 20),
            _buildInput("Nome", _nomeController, TextInputType.name),
            _buildInput("Idade", _idadeController, TextInputType.number),
            Row(
              children: [
                Expanded(child: _buildInput("Altura (ex: 1.75)", _alturaController, TextInputType.number)),
                const SizedBox(width: 15),
                Expanded(child: _buildInput("Peso (kg)", _pesoController, TextInputType.number)),
              ],
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _salvar, child: const Text("SALVAR DADOS")),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller, keyboardType: type,
        onChanged: (_) => setState(() {}), // Atualiza a régua ao digitar
        decoration: InputDecoration(
          labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.black26
        ),
      ),
    );
  }
}