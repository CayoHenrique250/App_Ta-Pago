import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/treino_model.dart';
import '../models/exercicio_model.dart';
import '../services/treino_service.dart';

class CadastroTreinoScreen extends StatefulWidget {
  final TreinoModelo? treinoParaEditar;

  const CadastroTreinoScreen({super.key, this.treinoParaEditar});

  @override
  State<CadastroTreinoScreen> createState() => _CadastroTreinoScreenState();
}

class _CadastroTreinoScreenState extends State<CadastroTreinoScreen> {
  final _nomeTreinoController = TextEditingController();
  List<int> diasSelecionados = [];
  List<ExercicioModelo> listaExercicios = [];

  final Map<int, String> diasSemana = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  @override
  void initState() {
    super.initState();
    if (widget.treinoParaEditar != null) {
      _nomeTreinoController.text = widget.treinoParaEditar!.nome;
      diasSelecionados = List.from(widget.treinoParaEditar!.diasDaSemana);
      listaExercicios = List.from(widget.treinoParaEditar!.exercicios);
    }
  }

  void toggleDia(int dia) {
    final service = Provider.of<TreinoService>(context, listen: false);

    String? treinoExistenteNome;

    for (var treino in service.listaDeTreinos) {
      if (widget.treinoParaEditar != null &&
          treino.id == widget.treinoParaEditar!.id) {
        continue;
      }

      if (treino.diasDaSemana.contains(dia)) {
        treinoExistenteNome = treino.nome;
        break;
      }
    }

    if (treinoExistenteNome != null && !diasSelecionados.contains(dia)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "O dia já está ocupado pelo treino '$treinoExistenteNome'.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      diasSelecionados.contains(dia)
          ? diasSelecionados.remove(dia)
          : diasSelecionados.add(dia);
    });
  }

  void salvarTreino() {
    if (_nomeTreinoController.text.isEmpty ||
        diasSelecionados.isEmpty ||
        listaExercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    final service = Provider.of<TreinoService>(context, listen: false);

    if (widget.treinoParaEditar == null) {
      final novoTreino = TreinoModelo(
        id: const Uuid().v1(),
        nome: _nomeTreinoController.text,
        diasDaSemana: diasSelecionados,
        exercicios: listaExercicios,
      );
      service.adicionarTreino(novoTreino);
    } else {
      final treinoAtualizado = TreinoModelo(
        id: widget.treinoParaEditar!.id,
        nome: _nomeTreinoController.text,
        diasDaSemana: diasSelecionados,
        exercicios: listaExercicios,
      );
      service.editarTreino(treinoAtualizado);
    }
    Navigator.of(context).pop();
  }

  void mostrarDialogoAdicionarExercicio() {
    final nomeExController = TextEditingController();
    final seriesController = TextEditingController();
    final repsController = TextEditingController();
    final pesoController = TextEditingController();

    File? imagemSelecionada;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pegarImagemGaleria() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: ImageSource.gallery,
            );

            if (pickedFile != null) {
              final directory = await getApplicationDocumentsDirectory();
              final fileName = path.basename(pickedFile.path);
              final savedImage = await File(
                pickedFile.path,
              ).copy('${directory.path}/$fileName');

              setDialogState(() {
                imagemSelecionada = savedImage;
              });
            }
          }

          return AlertDialog(
            title: const Text("Adicionar Exercício"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: pegarImagemGaleria,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                        image: imagemSelecionada != null
                            ? DecorationImage(
                                image: FileImage(imagemSelecionada!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imagemSelecionada == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                Text(
                                  "Toque para add Imagem",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nomeExController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: seriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Séries',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: repsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps'),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: pesoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Carga (kg)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nomeExController.text.isNotEmpty) {
                    setState(() {
                      listaExercicios.add(
                        ExercicioModelo(
                          id: const Uuid().v1(),
                          nome: nomeExController.text,
                          series: seriesController.text,
                          repeticoes: repsController.text,
                          peso: pesoController.text,
                          imageUrl: imagemSelecionada?.path,
                        ),
                      );
                    });
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text("Adicionar"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.treinoParaEditar == null ? "Novo Treino" : "Editar Treino",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeTreinoController,
              decoration: const InputDecoration(
                labelText: 'Nome do Treino',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Dias da Semana",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8.0,
              children: diasSemana.entries.map((entry) {
                final isSelected = diasSelecionados.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (_) => toggleDia(entry.key),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.black,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Exercícios",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: mostrarDialogoAdicionarExercicio,
                  icon: Icon(
                    Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: listaExercicios.length,
                itemBuilder: (ctx, index) {
                  final ex = listaExercicios[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black26,
                          image:
                              (ex.imageUrl != null && ex.imageUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: FileImage(File(ex.imageUrl!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (ex.imageUrl == null || ex.imageUrl!.isEmpty)
                            ? Icon(
                                Icons.fitness_center,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      title: Text(
                        ex.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${ex.series}x${ex.repeticoes} - ${ex.peso}kg",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => listaExercicios.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: salvarTreino,
                child: const Text("SALVAR"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
