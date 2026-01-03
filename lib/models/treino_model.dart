import 'exercicio_model.dart';

class TreinoModelo {
  String id;
  String nome;
  List<ExercicioModelo> exercicios;
  List<int> diasDaSemana;

  TreinoModelo({
    required this.id,
    required this.nome,
    required this.exercicios,
    required this.diasDaSemana,
  });
}
