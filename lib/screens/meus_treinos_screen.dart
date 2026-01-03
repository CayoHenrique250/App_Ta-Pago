import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/treino_service.dart';
import 'cadastro_treino_screen.dart';

class MeusTreinosScreen extends StatelessWidget {
  const MeusTreinosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TreinoService>(
      builder: (context, service, child) {
        final treinos = service.listaDeTreinos;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            centerTitle: true,
            title: Column(
              children: [
                const Text(
                  "MEUS TREINOS",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        service.rankAtual.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: treinos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: Colors.grey[800],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Nenhum treino montado ainda.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: treinos.length,
                  itemBuilder: (ctx, index) {
                    final treino = treinos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          treino.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              "${treino.exercicios.length} exercícios cadastrados",
                            ),
                            const SizedBox(height: 4),

                            Wrap(
                              spacing: 4,
                              children: treino.diasDaSemana.map((dia) {
                                final nomesDias = [
                                  'Seg',
                                  'Ter',
                                  'Qua',
                                  'Qui',
                                  'Sex',
                                  'Sáb',
                                  'Dom',
                                ];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    // ignore: deprecated_member_use
                                    color: Theme.of(
                                      context,
                                    // ignore: deprecated_member_use
                                    ).colorScheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    nomesDias[dia - 1],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => CadastroTreinoScreen(
                                    treinoParaEditar: treino,
                                  ),
                                ),
                              );
                            } else if (value == 'excluir') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Excluir Treino?"),
                                  content: Text(
                                    "Deseja apagar ${treino.nome} permanentemente?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("CANCELAR"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        service.removerTreino(treino.id);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text(
                                        "EXCLUIR",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 10),
                                    Text("Editar"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text("Excluir"),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const CadastroTreinoScreen(),
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text("NOVO TREINO"),
          ),
        );
      },
    );
  }
}
