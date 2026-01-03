import 'exercicio_model.dart';

class TreinoModelo {
  String id;
  String nome; // Ex: "Treino A - Peito"
  List<ExercicioModelo> exercicios;
  List<int> diasDaSemana; // 1 = Segunda, 7 = Domingo

  TreinoModelo({
    required this.id,
    required this.nome,
    required this.exercicios,
    required this.diasDaSemana,
  });
}