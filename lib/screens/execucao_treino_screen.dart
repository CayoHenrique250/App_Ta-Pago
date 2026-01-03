import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/treino_model.dart';
import '../services/treino_service.dart';

class ExecucaoTreinoScreen extends StatefulWidget {
  final TreinoModelo treino;
  const ExecucaoTreinoScreen({super.key, required this.treino});

  @override
  State<ExecucaoTreinoScreen> createState() => _ExecucaoTreinoScreenState();
}

class _ExecucaoTreinoScreenState extends State<ExecucaoTreinoScreen> {
  Map<String, bool> exerciciosFeitos = {};
  Map<String, String> cargasNovas = {};
  File? _fotoTreino;

  @override
  void initState() {
    super.initState();
    for (var ex in widget.treino.exercicios) {
      cargasNovas[ex.id] = ex.peso;
      exerciciosFeitos[ex.id] = false;
    }
    _carregarEstadoSalvo();
  }


  void _carregarEstadoSalvo() async {
    final service = Provider.of<TreinoService>(context, listen: false);
    final checks = await service.carregarCheckpointsDoDia();
    final cargasSalvas = await service.carregarCargasTemporarias();
    if (mounted) {
      setState(() {
        for (var exId in checks) {
          if (exerciciosFeitos.containsKey(exId)) {
            exerciciosFeitos[exId] = true;
          }
        }
        for (var exId in cargasSalvas.keys) {
          if (cargasNovas.containsKey(exId)) {
            cargasNovas[exId] = cargasSalvas[exId]!;
          }
        }
      });
    }
  }

  Future<void> _tirarFoto(StateSetter setModalState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = await File(
        pickedFile.path,
      ).copy('${directory.path}/$fileName');

      setModalState(() {
        _fotoTreino = savedImage;
      });
      setState(() {
        _fotoTreino = savedImage;
      });
    }
  }

  void _expandirImagemExercicio(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarFinalizacao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Treino Concluído!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Registre seu shape!",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  if (_fotoTreino != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _fotoTreino!,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => _tirarFoto(setModalState),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            "Tirar Outra",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () => _tirarFoto(setModalState),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              size: 60,
                              color: Colors.white,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Toque para FOTO",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _finalizarRealmente();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F260),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        "SALVAR TUDO",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_fotoTreino == null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _finalizarRealmente();
                      },
                      child: const Text(
                        "Pular foto e finalizar",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _finalizarRealmente() {
    Provider.of<TreinoService>(
      context,
      listen: false,
    ).marcarTreinoComoConcluido(widget.treino, cargasNovas, _fotoTreino?.path);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Treino salvo! 💪')));
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosOrdenados = List.from(widget.treino.exercicios);
    exerciciosOrdenados.sort((a, b) {
      final aDone = exerciciosFeitos[a.id] == true;
      final bDone = exerciciosFeitos[b.id] == true;
      if (aDone == bDone) return 0;
      return aDone ? 1 : -1;
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.treino.nome)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exerciciosOrdenados.length,
              itemBuilder: (ctx, index) {
                final ex = exerciciosOrdenados[index];
                final isDone = exerciciosFeitos[ex.id] == true;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: isDone
                        // ignore: deprecated_member_use
                        ? const Color(0xFF00F260).withOpacity(0.2)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: isDone
                        ? Border.all(color: const Color(0xFF00F260), width: 2)
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (ex.imageUrl != null &&
                                    ex.imageUrl!.isNotEmpty) {
                                  _expandirImagemExercicio(ex.imageUrl!);
                                }
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(15),
                                  image:
                                      (ex.imageUrl != null &&
                                          ex.imageUrl!.isNotEmpty)
                                      ? DecorationImage(
                                          image: FileImage(File(ex.imageUrl!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child:
                                    (ex.imageUrl == null ||
                                        ex.imageUrl!.isEmpty)
                                    ? Icon(
                                        Icons.fitness_center,
                                        color: Colors.grey[700],
                                      )
                                    : const Icon(
                                        Icons.zoom_in,
                                        color: Colors.white70,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ex.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: isDone,
                                        activeColor: const Color(0xFF00F260),
                                        checkColor: Colors.black,
                                        onChanged: (val) {
                                          setState(
                                            () => exerciciosFeitos[ex.id] =
                                                val ?? false,
                                          );
                                          Provider.of<TreinoService>(
                                            context,
                                            listen: false,
                                          ).alternarCheckpoint(
                                            ex.id,
                                            val ?? false,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${ex.series}x${ex.repeticoes}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Carga (kg):",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  key: ValueKey(
                                    'carga_${ex.id}_${cargasNovas[ex.id]}',
                                  ),
                                  initialValue: cargasNovas[ex.id] ?? ex.peso,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  onChanged: (v) {
                                    cargasNovas[ex.id] = v;
                                    Provider.of<TreinoService>(
                                      context,
                                      listen: false,
                                    ).salvarCargaTemporaria(ex.id, v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _confirmarFinalizacao,
                child: const Text("FINALIZAR TREINO"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
