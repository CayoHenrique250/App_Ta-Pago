class ExercicioModelo {
  String id;
  String nome;
  String series;
  String repeticoes;
  String peso;
  String? imageUrl; // Campo para URL da imagem/gif

  ExercicioModelo({
    required this.id,
    required this.nome,
    required this.series,
    required this.repeticoes,
    required this.peso,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'series': series,
      'repeticoes': repeticoes,
      'peso': peso,
      'imageUrl': imageUrl,
    };
  }

  factory ExercicioModelo.fromMap(Map<String, dynamic> map) {
    return ExercicioModelo(
      id: map['id'] as String,
      nome: map['nome'] as String,
      series: map['series'] as String,
      repeticoes: map['repeticoes'] as String,
      peso: map['peso'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}