// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:path/path.dart' as path;
import '../services/treino_service.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  DateTime _focusedDay = DateTime.now();
  // ignore: unused_field
  DateTime? _selectedDay;

  void _mostrarOpcoesDiaComTreino(DateTime data, String? fotoPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: Text(
          "Treino do dia ${data.day}/${data.month}",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fotoPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(fotoPath),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Treino registrado sem foto.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              "O que deseja fazer?",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("FECHAR"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<TreinoService>(
                context,
                listen: false,
              ).removerHistorico(data);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Registro removido!")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("REMOVER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcoesDiaSemTreino(DateTime data) {
    if (data.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Você não pode prever o futuro, Monstro! 😂"),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: const Text(
          "Esqueceu de marcar?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Deseja marcar este dia como 'Pago' manualmente?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _adicionarFotoRetroativa(data);
            },
            child: const Text("SIM, MARCAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarFotoRetroativa(DateTime data) async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E38),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Adicionar Foto?",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text(
                "Escolher da Galeria",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  _salvarManual(data, picked.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text(
                "Só marcar como feito (Sem foto)",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _salvarManual(data, null);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarManual(DateTime data, String? tempPath) async {
    String? finalPath;

    if (tempPath != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = "manual_${data.millisecondsSinceEpoch}.jpg";
      final savedImage = await File(
        tempPath,
      ).copy('${directory.path}/$fileName');
      finalPath = savedImage.path;
    }

    if (mounted) {
      Provider.of<TreinoService>(
        context,
        listen: false,
      ).adicionarHistoricoManual(data, finalPath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Adicionado ao histórico!")));
    }
  }

  String _getTextoRequisitos(int min, int max) {
    if (max == 9999) {
      return '$min+ treinos';
    }
    final maxAjustado = max - 1;
    if (min == 0) {
      return '0-$maxAjustado treinos';
    }
    return '$min-$maxAjustado treinos';
  }

  void _mostrarSalaTrofeus(int totalTreinos) {
    final niveis = [
      {
        'nome': 'Frango',
        'min': 0,
        'max': 5,
        'desc': 'O início da jornada.',
        'color': const Color.fromARGB(255, 114, 158, 180),
      },
      {
        'nome': 'Em Construção',
        'min': 5,
        'max': 15,
        'desc': 'Saindo da inércia!',
        'color': Colors.tealAccent,
      },
      {
        'nome': 'Ratão de Academia',
        'min': 15,
        'max': 30,
        'desc': 'O shape tá vindo.',
        'color': Colors.orange,
      },
      {
        'nome': 'Monstro',
        'min': 30,
        'max': 60,
        'desc': 'Respeito total.',
        'color': Colors.redAccent,
      },
      {
        'nome': 'Olimpo',
        'min': 60,
        'max': 9999,
        'desc': 'Nível Deus Grego.',
        'color': const Color(0xFFFFD700),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121225),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sala de Troféus",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.emoji_events, color: Colors.amber[700]),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Você tem $totalTreinos treinos concluídos.",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  itemCount: niveis.length,
                  itemBuilder: (ctx, index) {
                    final nivel = niveis[index];
                    final min = nivel['min'] as int;
                    final cor = nivel['color'] as Color;

                    final alcancado = totalTreinos >= min;
                    final atual =
                        totalTreinos >= min &&
                        totalTreinos < (nivel['max'] as int);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: alcancado
                            ? cor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: atual
                            ? Border.all(color: cor, width: 2)
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: alcancado
                                  ? cor.withOpacity(0.2)
                                  : Colors.black26,
                            ),
                            child: Icon(
                              alcancado ? Icons.emoji_events : Icons.lock,
                              color: alcancado ? cor : Colors.grey[800],
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nivel['nome'] as String,
                                  style: TextStyle(
                                    color: alcancado ? cor : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nivel['desc'] as String,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getTextoRequisitos(min, nivel['max'] as int),
                                  style: TextStyle(
                                    color: alcancado
                                        ? cor.withOpacity(0.8)
                                        : Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (atual)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "ATUAL",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final treinoService = Provider.of<TreinoService>(context);
    final historicoMap = treinoService.historicoMap;
    final totalTreinos = treinoService.treinosTotais;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Histórico",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        "Total: $totalTreinos treinos",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarSalaTrofeus(totalTreinos),
                      icon: const Icon(Icons.emoji_events, color: Colors.black),
                      label: const Text(
                        "TROFÉUS",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: const Color(0xFF1E1E38),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar(
                      locale: 'pt_BR',
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      calendarStyle: const CalendarStyle(
                        defaultTextStyle: TextStyle(color: Colors.white),
                        weekendTextStyle: TextStyle(color: Colors.grey),
                        outsideDaysVisible: false,
                      ),

                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        final dateKey = DateTime(
                          selectedDay.year,
                          selectedDay.month,
                          selectedDay.day,
                        );

                        if (historicoMap.containsKey(dateKey)) {
                          _mostrarOpcoesDiaComTreino(
                            dateKey,
                            historicoMap[dateKey],
                          );
                        } else {
                          _mostrarOpcoesDiaSemTreino(dateKey);
                        }
                      },

                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final dateKey = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          if (historicoMap.containsKey(dateKey)) {
                            final fotoPath = historicoMap[dateKey];
                            return Positioned(
                              bottom: 1,
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00F260),
                                    width: 2,
                                  ),
                                  image: fotoPath != null
                                      ? DecorationImage(
                                          image: FileImage(File(fotoPath)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: fotoPath == null
                                      ? const Color(0xFF00F260)
                                      : Colors.transparent,
                                ),
                                child: fotoPath == null
                                    ? const Icon(
                                        Icons.check,
                                        size: 20,
                                        color: Colors.black,
                                      )
                                    : null,
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
