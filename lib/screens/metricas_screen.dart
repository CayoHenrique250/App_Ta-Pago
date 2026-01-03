// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/treino_service.dart';
import '../models/usuario_model.dart';
import '../models/peso_model.dart';
import '../models/carga_model.dart';

class MetricasScreen extends StatefulWidget {
  const MetricasScreen({super.key});

  @override
  State<MetricasScreen> createState() => _MetricasScreenState();
}

class _MetricasScreenState extends State<MetricasScreen> {
  final Map<String, bool> _exerciciosExpandidos = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<TreinoService>(
          builder: (context, treinoService, child) {
            final usuario = treinoService.usuario;
            final historicoPeso = treinoService.historicoPeso;
            final treinosPorMes = treinoService.getTreinosPorMes();
            final treinosTotais = treinoService.treinosTotais;
            final treinosMesAtual = treinoService.getTreinosMesAtual();
            final todosExercicios = treinoService.getTodosExercicios();
            final rankAtual = treinoService.rankAtual;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF121225), Color(0xFF1E1E38)],
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Métricas',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardPesoIMCAtual(context, usuario),
                          const SizedBox(height: 16),

                          if (historicoPeso.isNotEmpty)
                            _buildCardEvolucaoPesoIMC(context, historicoPeso),
                          if (historicoPeso.isNotEmpty)
                            const SizedBox(height: 16),

                          if (historicoPeso.isNotEmpty)
                            _buildCardRegistrosPeso(context, historicoPeso),
                          if (historicoPeso.isNotEmpty)
                            const SizedBox(height: 16),

                          _buildCardEvolucaoCargas(context, treinoService),

                          _buildCardEvolucaoTreinos(context, treinosPorMes),
                          const SizedBox(height: 16),

                          _buildCardEstatisticas(
                            context,
                            treinosTotais,
                            treinosMesAtual,
                            todosExercicios.length,
                            rankAtual,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardPesoIMCAtual(BuildContext context, UsuarioModelo usuario) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_weight,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Peso e IMC Atual',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${usuario.peso.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Peso',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: Colors.grey[800]),
              Column(
                children: [
                  Text(
                    usuario.imcString,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    usuario.classificacaoImc,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardEvolucaoPesoIMC(
    BuildContext context,
    List<PesoModelo> historico,
  ) {
    final historicoOrdenado = List<PesoModelo>.from(historico)
      ..sort((a, b) => a.data.compareTo(b.data));

    final historicoLimitado = historicoOrdenado.length > 30
        ? historicoOrdenado.sublist(historicoOrdenado.length - 30)
        : historicoOrdenado;

    final pesos = historicoLimitado.map((p) => p.peso).toList();
    final imcs = historicoLimitado.map((p) => p.imc).toList();
    final datas = historicoLimitado.map((p) => p.data).toList();

    final minPeso = pesos.isEmpty
        ? 0.0
        : pesos.reduce((a, b) => a < b ? a : b) - 5;
    final maxPeso = pesos.isEmpty
        ? 100.0
        : pesos.reduce((a, b) => a > b ? a : b) + 5;
    final minIMC = imcs.isEmpty
        ? 0.0
        : imcs.reduce((a, b) => a < b ? a : b) - 2;
    final maxIMC = imcs.isEmpty
        ? 30.0
        : imcs.reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Evolução de Peso e IMC',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[800]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < datas.length &&
                            index % (datas.length > 10 ? 5 : 2) == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(datas[index]),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 25,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[800]!),
                ),
                minX: 0,
                maxX: (historicoLimitado.length - 1).toDouble(),
                minY: minPeso < minIMC ? minPeso : minIMC,
                maxY: maxPeso > maxIMC ? maxPeso : maxIMC,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      pesos.length,
                      (index) => FlSpot(index.toDouble(), pesos[index]),
                    ),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      imcs.length,
                      (index) => FlSpot(index.toDouble(), imcs[index]),
                    ),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> spots) {
                      return spots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < datas.length) {
                          return LineTooltipItem(
                            spot.y.toStringAsFixed(1),
                            TextStyle(
                              color: spot.barIndex == 0
                                  ? Colors.blue
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '\n${DateFormat('dd/MM/yy').format(datas[index])}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, Colors.blue, 'Peso (kg)'),
              const SizedBox(width: 20),
              _buildLegendItem(
                context,
                Theme.of(context).colorScheme.primary,
                'IMC',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildCardRegistrosPeso(
    BuildContext context,
    List<PesoModelo> historico,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Registros de Peso',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: historico.length,
              itemBuilder: (context, index) {
                final registro = historico[index];
                return _buildItemRegistro(context, registro);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRegistro(BuildContext context, PesoModelo registro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(registro.data),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${registro.peso.toStringAsFixed(1)} kg',
                      style: TextStyle(color: Colors.blue[300], fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'IMC: ${registro.imc.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () => _editarRegistro(context, registro),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _removerRegistro(context, registro),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _editarRegistro(BuildContext context, PesoModelo registro) {
    final pesoController = TextEditingController(
      text: registro.peso.toStringAsFixed(1),
    );
    final alturaController = TextEditingController(
      text: registro.altura.toStringAsFixed(2),
    );
    DateTime dataSelecionada = registro.data;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E38),
          title: const Text(
            'Editar Registro',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pesoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Peso (kg)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: alturaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Altura (m)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (data != null) {
                      setState(() => dataSelecionada = data);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(dataSelecionada),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final peso =
                    double.tryParse(pesoController.text.replaceAll(',', '.')) ??
                    0.0;
                final altura =
                    double.tryParse(
                      alturaController.text.replaceAll(',', '.'),
                    ) ??
                    0.0;
                if (peso > 0 && altura > 0 && registro.id != null) {
                  Provider.of<TreinoService>(
                    context,
                    listen: false,
                  ).editarRegistroPeso(
                    registro.id!,
                    peso,
                    altura,
                    dataSelecionada,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registro atualizado!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _removerRegistro(BuildContext context, PesoModelo registro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: const Text(
          'Remover Registro',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja remover o registro de ${DateFormat('dd/MM/yyyy').format(registro.data)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (registro.id != null) {
                Provider.of<TreinoService>(
                  context,
                  listen: false,
                ).removerRegistroPeso(registro.id!);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registro removido!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardEvolucaoTreinos(
    BuildContext context,
    Map<String, int> treinosPorMes,
  ) {
    final valores = treinosPorMes.values.toList();
    final labels = treinosPorMes.keys.toList();
    final maxY =
        valores.isNotEmpty && valores.reduce((a, b) => a > b ? a : b) > 0
        ? valores.reduce((a, b) => a > b ? a : b).toDouble() + 2
        : 10.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Evolução de Treinos (últimos 3 meses)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: valores.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[800]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    labels[index],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 25,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              );
                            },
                            reservedSize: 25,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      minX: 0,
                      maxX: (labels.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            valores.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              valores[index].toDouble(),
                            ),
                          ),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Ainda não há dados suficientes',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardEstatisticas(
    BuildContext context,
    int treinosTotais,
    int treinosMesAtual,
    int totalExercicios,
    String rankAtual,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Estatísticas Gerais',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Total de Treinos',
                treinosTotais.toString(),
                Icons.calendar_today,
              ),
              _buildStatItem(
                context,
                'Treinos (Mês)',
                treinosMesAtual.toString(),
                Icons.calendar_month,
              ),
              _buildStatItem(
                context,
                'Exercícios',
                totalExercicios.toString(),
                Icons.fitness_center,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rank: $rankAtual',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 100,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildCardEvolucaoCargas(
    BuildContext context,
    TreinoService treinoService,
  ) {
    return FutureBuilder<List<String>>(
      future: treinoService.getExerciciosComHistorico(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final exerciciosIds = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Evolução de Cargas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...exerciciosIds.map(
                (exercicioId) => _buildCardExercicioCarga(
                  context,
                  exercicioId,
                  treinoService,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardExercicioCarga(
    BuildContext context,
    String exercicioId,
    TreinoService treinoService,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: treinoService.getResumoCargasExercicio(exercicioId),
      builder: (context, resumoSnapshot) {
        if (!resumoSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final resumo = resumoSnapshot.data!;
        final nome = resumo['nome'] as String? ?? 'Exercício';
        final ultima = resumo['ultima'] as double;
        final melhor = resumo['melhor'] as double;
        final primeira = resumo['primeira'] as double;
        final tendencia = resumo['tendencia'] as int;
        final percentualProgresso = resumo['percentualProgresso'] as double;

        final isExpandido = _exerciciosExpandidos[exercicioId] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tendencia == 1
                  ? Colors.green
                  : tendencia == -1
                  ? Colors.red
                  : Colors.grey,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _exerciciosExpandidos[exercicioId] = !isExpandido;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoCarga(
                                  context,
                                  'Última',
                                  ultima,
                                  Colors.blue[300]!,
                                ),
                                const SizedBox(width: 16),
                                _buildInfoCarga(
                                  context,
                                  'Melhor',
                                  melhor,
                                  Colors.green[300]!,
                                ),
                                const SizedBox(width: 16),
                                _buildInfoCarga(
                                  context,
                                  'Primeira',
                                  primeira,
                                  Colors.grey[400]!,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  tendencia == 1
                                      ? Icons.arrow_upward
                                      : tendencia == -1
                                      ? Icons.arrow_downward
                                      : Icons.remove,
                                  size: 16,
                                  color: tendencia == 1
                                      ? Colors.green
                                      : tendencia == -1
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  percentualProgresso >= 0
                                      ? '+${percentualProgresso.toStringAsFixed(1)}%'
                                      : '${percentualProgresso.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: tendencia == 1
                                        ? Colors.green
                                        : tendencia == -1
                                        ? Colors.red
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpandido ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpandido)
                Column(
                  children: [
                    FutureBuilder<List<CargaModelo>>(
                      future: treinoService.getHistoricoCargasExercicio(
                        exercicioId,
                      ),
                      builder: (context, historicoSnapshot) {
                        if (!historicoSnapshot.hasData ||
                            historicoSnapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final historico = historicoSnapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildGraficoCarga(context, historico),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _removerHistoricoCarga(
                              context,
                              exercicioId,
                              nome,
                              treinoService,
                            ),
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            label: const Text(
                              'Remover Histórico',
                              style: TextStyle(color: Colors.red, fontSize: 12),
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
      },
    );
  }

  Widget _buildInfoCarga(
    BuildContext context,
    String label,
    double valor,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        Text(
          '${valor.toStringAsFixed(1)} kg',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _removerHistoricoCarga(
    BuildContext context,
    String exercicioId,
    String nomeExercicio,
    TreinoService treinoService,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: const Text(
          'Remover Histórico',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja remover todo o histórico de cargas do exercício "$nomeExercicio"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              treinoService.removerHistoricoCargasExercicio(exercicioId);
              Navigator.pop(ctx);
              setState(() {
                _exerciciosExpandidos[exercicioId] = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Histórico removido!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoCarga(BuildContext context, List<CargaModelo> historico) {
    final historicoLimitado = historico.length > 20
        ? historico.sublist(historico.length - 20)
        : historico;

    final cargas = historicoLimitado.map((c) => c.carga).toList();
    final datas = historicoLimitado.map((c) => c.data).toList();

    final minCarga = cargas.isEmpty
        ? 0.0
        : cargas.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxCarga = cargas.isEmpty
        ? 100.0
        : cargas.reduce((a, b) => a > b ? a : b) * 1.1;

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxCarga - minCarga) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[800]!, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 &&
                      index < datas.length &&
                      index % (datas.length > 10 ? 5 : 2) == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('dd/MM').format(datas[index]),
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxCarga - minCarga) / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 8),
                  );
                },
                reservedSize: 25,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[800]!),
          ),
          minX: 0,
          maxX: (historicoLimitado.length - 1).toDouble(),
          minY: minCarga,
          maxY: maxCarga,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                cargas.length,
                (index) => FlSpot(index.toDouble(), cargas[index]),
              ),
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 2.5,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> spots) {
                return spots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < datas.length) {
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)} kg',
                      TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '\n${DateFormat('dd/MM/yy').format(datas[index])}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
