class PesoModelo {
  int? id;
  DateTime data;
  double peso;
  double altura;
  double imc;

  PesoModelo({
    this.id,
    required this.data,
    required this.peso,
    required this.altura,
    required this.imc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'peso': peso,
      'altura': altura,
      'imc': imc,
    };
  }

  factory PesoModelo.fromMap(Map<String, dynamic> map) {
    return PesoModelo(
      id: map['id'] as int?,
      data: DateTime.parse(map['data'] as String),
      peso: map['peso'] as double,
      altura: map['altura'] as double,
      imc: map['imc'] as double,
    );
  }
}
