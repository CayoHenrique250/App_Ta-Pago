// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/treino_service.dart';
import '../models/treino_model.dart';
import 'execucao_treino_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _metaAgua = 2000;
  int _aguaAtual = 0;
  int _ultimoTamanhoCopo = 250;

  late AnimationController _waveController;

  Timer? _stopwatchTimer;
  Duration _elapsedTime = Duration.zero;
  bool _isRunning = false;

  final Color _goldColor = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _carregarDadosAgua();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarDadosAgua() async {
    final prefs = await SharedPreferences.getInstance();

    final String? ultimoDiaSalvo = prefs.getString('ultimo_dia_agua');
    final String hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (ultimoDiaSalvo != null && ultimoDiaSalvo != hoje) {
      final aguaDiaAnterior = prefs.getInt('agua_atual') ?? 0;
      if (aguaDiaAnterior > 0) {
        await _salvarConsumoAguaNoHistorico(
          prefs,
          ultimoDiaSalvo,
          aguaDiaAnterior,
        );
      }
      await prefs.setString('ultimo_dia_agua', hoje);
      await prefs.setInt('agua_atual', 0);
    } else if (ultimoDiaSalvo == null) {
      await prefs.setString('ultimo_dia_agua', hoje);
    }

    setState(() {
      _metaAgua = prefs.getInt('meta_agua') ?? 2000;
      _ultimoTamanhoCopo = prefs.getInt('ultimo_tamanho_copo') ?? 250;
      _aguaAtual = prefs.getInt('agua_atual') ?? 0;
    });
  }

  Future<void> _salvarConsumoAguaNoHistorico(
    SharedPreferences prefs,
    String data,
    int consumo,
  ) async {
    try {
      final historicoJson = prefs.getString('historico_agua') ?? '{}';
      final Map<String, dynamic> historico = json.decode(historicoJson);
      historico[data] = consumo;
      await prefs.setString('historico_agua', json.encode(historico));
    } catch (e) {
      await prefs.setString('historico_agua', json.encode({data: consumo}));
    }
  }

  Future<void> _adicionarAguaComDialogo() async {
    final TextEditingController controller = TextEditingController(
      text: _ultimoTamanhoCopo.toString(),
    );

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void somarValor(int valor) {
              int atual = int.tryParse(controller.text) ?? 0;
              int novoTotal = atual + valor;
              controller.text = novoTotal.toString();

              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }

            Widget buildPresetButton(int valor) {
              return GestureDetector(
                onTap: () => somarValor(valor),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _goldColor.withOpacity(0.15),
                    border: Border.all(color: _goldColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "+${valor}ml",
                    style: TextStyle(
                      color: _goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              titlePadding: const EdgeInsets.fromLTRB(24, 20, 10, 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Registrar Hidratação",
                    style: TextStyle(color: _goldColor, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(ctx).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.grey[400],
                          size: 22,
                        ),
                        onPressed: () {
                          controller.text = '0';
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                        },
                        tooltip: 'Zerar',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          cursorColor: _goldColor,
                          decoration: InputDecoration(
                            suffixText: "ml",
                            suffixStyle: TextStyle(
                              color: _goldColor,
                              fontSize: 20,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _goldColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Center(
                    child: Text(
                      "Adicionar rápido:",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildPresetButton(100),
                      const SizedBox(width: 8),
                      buildPresetButton(250),
                      const SizedBox(width: 8),
                      buildPresetButton(500),
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final quantidade = int.tryParse(controller.text);
                          if (quantidade != null && quantidade > 0) {
                            _processarAgua(quantidade, adicionar: false);
                            Navigator.of(ctx).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.remove, size: 18),
                        label: const Text("Remover"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          "Adicionar",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final quantidade = int.tryParse(controller.text);
                          if (quantidade != null && quantidade > 0) {
                            _processarAgua(quantidade, adicionar: true);
                            Navigator.of(ctx).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processarAgua(int quantidade, {required bool adicionar}) async {
    final prefs = await SharedPreferences.getInstance();
    final String hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      if (adicionar) {
        _aguaAtual += quantidade;
        _ultimoTamanhoCopo = quantidade;
      } else {
        _aguaAtual -= quantidade;
        if (_aguaAtual < 0) _aguaAtual = 0;
      }
    });

    await prefs.setInt('agua_atual', _aguaAtual);
    await prefs.setInt('ultimo_tamanho_copo', _ultimoTamanhoCopo);
    await prefs.setString('ultimo_dia_agua', hoje);

    await _salvarConsumoAguaNoHistorico(prefs, hoje, _aguaAtual);

    if (adicionar &&
        _aguaAtual >= _metaAgua &&
        (_aguaAtual - quantidade) < _metaAgua) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _goldColor,
          duration: const Duration(seconds: 3),
          content: const Text(
            "META BATIDA! Hidratação nível Monstro! 💧🦍",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Future<void> _editarMeta() async {
    final TextEditingController controller = TextEditingController(
      text: _metaAgua.toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: Text(
          "Definir Meta Diária (ml)",
          style: TextStyle(color: _goldColor),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          cursorColor: _goldColor,
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _goldColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _goldColor),
            child: const Text("Salvar", style: TextStyle(color: Colors.black)),
            onPressed: () async {
              final novaMeta = int.tryParse(controller.text);
              if (novaMeta != null && novaMeta > 0) {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  _metaAgua = novaMeta;
                });
                await prefs.setInt('meta_agua', novaMeta);
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getEstiloRank(String rankNome) {
    final nome = rankNome.toLowerCase();

    if (nome.contains('frango')) {
      return {
        'cor': const Color.fromARGB(255, 114, 158, 180),
        'icon': Icons.child_care,
      };
    } else if (nome.contains('construção')) {
      return {'cor': Colors.tealAccent, 'icon': Icons.handyman};
    } else if (nome.contains('ratão')) {
      return {'cor': Colors.orange, 'icon': Icons.fitness_center};
    } else if (nome.contains('monstro')) {
      return {'cor': Colors.redAccent, 'icon': Icons.local_fire_department};
    } else if (nome.contains('olimpo')) {
      return {'cor': _goldColor, 'icon': Icons.emoji_events};
    }
    return {'cor': const Color(0xFF00F260), 'icon': Icons.star};
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = DateTime.now();
    final diaSemanaHoje = dataHoje.weekday;
    final treinoService = Provider.of<TreinoService>(context);
    final usuario = treinoService.usuario;

    TreinoModelo? treinoDoDia;
    try {
      treinoDoDia = treinoService.listaDeTreinos.firstWhere(
        (treino) => treino.diasDaSemana.contains(diaSemanaHoje),
      );
    } catch (e) {
      treinoDoDia = null;
    }

    final jaTreinouHoje = treinoService.treinoDeHojeConcluido;
    final estiloRank = _getEstiloRank(treinoService.rankAtual);
    final Color corRank = estiloRank['cor'];
    final IconData iconRank = estiloRank['icon'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121225), Color(0xFF1E1E38)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, color: _goldColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'TÁ PAGO!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: _goldColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, d MMM',
                            'pt_BR',
                          ).format(dataHoje).toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Olá, ${usuario.nome}!",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const PerfilScreen(),
                        ),
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5),
                              blurRadius: 15,
                            ),
                          ],
                          image:
                              (usuario.fotoPath != null &&
                                  usuario.fotoPath!.isNotEmpty)
                              ? DecorationImage(
                                  image: FileImage(File(usuario.fotoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            (usuario.fotoPath == null ||
                                usuario.fotoPath!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.black)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: corRank.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: corRank.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: corRank.withOpacity(0.2),
                          border: Border.all(color: corRank, width: 2),
                        ),
                        child: Icon(iconRank, color: corRank, size: 30),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Nível Atual",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${(treinoService.progressoRank * 100).toInt()}%",
                                  style: TextStyle(
                                    color: corRank,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              treinoService.rankAtual.toUpperCase(),
                              style: TextStyle(
                                color: corRank,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: treinoService.progressoRank,
                                minHeight: 6,
                                backgroundColor: Colors.grey[800],
                                color: corRank,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Próximo: ${treinoService.proximoRank}",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (treinoDoDia == null)
                          _buildCardDescanso(context)
                        else if (jaTreinouHoje)
                          _buildCardConcluido(context, treinoDoDia)
                        else
                          _buildCardTreino(context, treinoDoDia),

                        const SizedBox(height: 30),
                        _buildCardAgua(context),
                        const SizedBox(height: 30),
                        _buildCardCardio(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardAgua(BuildContext context) {
    double porcentagem = (_aguaAtual / _metaAgua).clamp(0.0, 1.0);

    Color corOnda = porcentagem >= 1.0
        ? const Color(0xFF00F260)
        : Colors.blueAccent;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "HIDRATAÇÃO",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              InkWell(
                onTap: _editarMeta,
                child: const Icon(Icons.edit, size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 60,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(color: Colors.transparent),
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: WavePainter(
                              animationValue: _waveController.value,
                              percentage: porcentagem,
                              color: corOnda,
                            ),
                            size: const Size(60, 100),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // CONTROLES E TEXTOS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$_aguaAtual / $_metaAgua ml",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      porcentagem >= 1.0
                          ? "Meta batida!"
                          : "Falta pouco para a meta!",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _adicionarAguaComDialogo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withOpacity(0.15),
                          foregroundColor: Colors.blueAccent,
                          elevation: 0,
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                        icon: const Icon(Icons.local_drink),
                        label: const Text("Registrar"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startStopwatch() {
    if (_isRunning) {
      _stopwatchTimer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _elapsedTime = _elapsedTime + const Duration(milliseconds: 100);
        });
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _resetStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() {
      _elapsedTime = Duration.zero;
      _isRunning = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = (duration.inMilliseconds.remainder(1000) / 100).floor();

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}.${milliseconds}';
  }

  Widget _buildCardCardio(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CRONÔMETRO",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Icon(
                Icons.timer,
                color: Colors.redAccent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            _formatDuration(_elapsedTime),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetStopwatch,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text("Resetar"),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _startStopwatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning
                        ? Colors.redAccent.withOpacity(0.15)
                        : Colors.redAccent,
                    foregroundColor: _isRunning ? Colors.redAccent : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: _isRunning ? 0 : 5,
                    side: _isRunning
                        ? const BorderSide(color: Colors.redAccent)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 24),
                  label: Text(
                    _isRunning ? "Pausar" : "Iniciar",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardConcluido(BuildContext context, TreinoModelo treino) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00F260), Color(0xFF0575E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0575E6).withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            "TÁ PAGO!",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Você destruiu o ${treino.nome} hoje.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTreino(BuildContext context, TreinoModelo treino) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PRÓXIMA MISSÃO",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(treino.nome, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              "${treino.exercicios.length} Exercícios",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ExecucaoTreinoScreen(treino: treino),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shadowColor: Theme.of(context).colorScheme.primary,
                  elevation: 15,
                ),
                icon: const Icon(Icons.play_arrow, color: Colors.black),
                label: const Text("INICIAR TREINO"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDescanso(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: const [
              Icon(Icons.nightlight_round, size: 50, color: Colors.blueGrey),
              SizedBox(height: 16),
              Text(
                "Descanso Merecido",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final double percentage;
  final Color color;

  WavePainter({
    required this.animationValue,
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    final double baseHeight = size.height * (1 - percentage);

    if (percentage == 0) return;

    path.moveTo(0, baseHeight);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        baseHeight +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 4,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}
