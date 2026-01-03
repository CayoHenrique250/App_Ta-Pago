class CargaModelo {
  int? id;
  String exercicioId;
  String exercicioNome;
  DateTime data;
  double carga;
  String? treinoId;

  CargaModelo({
    this.id,
    required this.exercicioId,
    required this.exercicioNome,
    required this.data,
    required this.carga,
    this.treinoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercicio_id': exercicioId,
      'exercicio_nome': exercicioNome,
      'data': data.toIso8601String(),
      'carga': carga,
      'treino_id': treinoId,
    };
  }

  factory CargaModelo.fromMap(Map<String, dynamic> map) {
    return CargaModelo(
      id: map['id'] as int?,
      exercicioId: map['exercicio_id'] as String,
      exercicioNome: map['exercicio_nome'] as String? ?? '',
      data: DateTime.parse(map['data'] as String),
      carga: (map['carga'] as num).toDouble(),
      treinoId: map['treino_id'] as String?,
    );
  }
}
