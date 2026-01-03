// ignore_for_file: deprecated_member_use

import 'dart:io'; // <--- IMPORTANTE: Adicionado para ler o arquivo da foto
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/treino_service.dart';
import '../models/treino_model.dart';
import 'execucao_treino_screen.dart';
import 'perfil_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- FUNÇÃO DE ESTILO (Apenas Visual) ---
  Map<String, dynamic> _getEstiloRank(String rankNome) {
    final nome = rankNome.toLowerCase();
    
    if (nome.contains('frango')) {
      return {'cor': Colors.blueGrey, 'icon': Icons.child_care}; 
    } else if (nome.contains('construção')) {
      return {'cor': Colors.tealAccent, 'icon': Icons.handyman};
    } else if (nome.contains('ratão')) {
      return {'cor': Colors.orange, 'icon': Icons.fitness_center};
    } else if (nome.contains('monstro')) {
      return {'cor': Colors.redAccent, 'icon': Icons.local_fire_department};
    } else if (nome.contains('olimpo')) {
      return {'cor': const Color(0xFFFFD700), 'icon': Icons.emoji_events};
    }
    return {'cor': const Color(0xFF00F260), 'icon': Icons.star};
  }

  @override
  Widget build(BuildContext context) {
    final dataHoje = DateTime.now();
    final diaSemanaHoje = dataHoje.weekday;
    final treinoService = Provider.of<TreinoService>(context); // O Provider escuta as mudanças aqui
    final usuario = treinoService.usuario;
    
    // Lógica para pegar o treino do dia
    TreinoModelo? treinoDoDia;
    try {
      treinoDoDia = treinoService.listaDeTreinos.firstWhere(
        (treino) => treino.diasDaSemana.contains(diaSemanaHoje)
      );
    } catch (e) {
      treinoDoDia = null;
    }

    final jaTreinouHoje = treinoService.treinoDeHojeConcluido;

    // Pega o estilo visual baseado no rank atual
    final estiloRank = _getEstiloRank(treinoService.rankAtual);
    final Color corRank = estiloRank['cor'];
    final IconData iconRank = estiloRank['icon'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF121225), Color(0xFF1E1E38)]
          )
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER COM FOTO DE PERFIL CORRIGIDA ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('EEEE, d MMM', 'pt_BR').format(dataHoje).toUpperCase(), style: TextStyle(color: Colors.grey[400], letterSpacing: 1.5)),
                        const SizedBox(height: 5),
                        Text("Olá, ${usuario.nome}!", style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PerfilScreen())),
                      child: Container(
                        width: 50, // Tamanho fixo para garantir que fique redondo
                        height: 50,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 15)],
                            // LÓGICA NOVA: Se tiver foto, usa ela como imagem de fundo
                            image: (usuario.fotoPath != null && usuario.fotoPath!.isNotEmpty)
                                ? DecorationImage(
                                    image: FileImage(File(usuario.fotoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        ),
                        // Se NÃO tiver foto, mostra o ícone, se tiver, mostra nada (null)
                        child: (usuario.fotoPath == null || usuario.fotoPath!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.black)
                            : null,
                      ),
                    )
                  ],
                ),
                // ---------------------------------------------
                
                const SizedBox(height: 30),

                // --- CARD DE RANK (Visual Novo) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: corRank.withOpacity(0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: corRank.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
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
                                Text("Nível Atual", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                Text(
                                  "${(treinoService.progressoRank * 100).toInt()}%", 
                                  style: TextStyle(color: corRank, fontWeight: FontWeight.bold)
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
                              style: const TextStyle(color: Colors.white54, fontSize: 10)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                
                // --- CONTEÚDO SCROLLÁVEL (Cards de Treino) ---
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
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // WIDGETS AUXILIARES (Cards)
   Widget _buildCardConcluido(BuildContext context, TreinoModelo treino) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00F260), Color(0xFF0575E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF0575E6).withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text("TÁ PAGO!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text("Você destruiu o ${treino.nome} hoje.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 1),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("PRÓXIMA MISSÃO", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            const SizedBox(height: 15),
            Text(treino.nome, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text("${treino.exercicios.length} Exercícios", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => ExecucaoTreinoScreen(treino: treino)));
                },
                style: ElevatedButton.styleFrom(
                  shadowColor: Theme.of(context).colorScheme.primary,
                  elevation: 15,
                ),
                icon: const Icon(Icons.play_arrow, color: Colors.black),
                label: const Text("INICIAR TREINO"),
              ),
            )
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
               Text("Descanso Merecido", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}