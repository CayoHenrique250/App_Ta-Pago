class UsuarioModelo {
  String nome;
  int idade;
  double altura;
  double peso;
  String? fotoPath;

  UsuarioModelo({
    required this.nome,
    required this.idade,
    required this.altura,
    required this.peso,
    this.fotoPath,
  });

  double get imc => peso / (altura * altura);
  String get imcString => imc.toStringAsFixed(1);

  String get classificacaoImc {
    if (imc < 18.5) return "Abaixo do Peso";
    if (imc < 25) return "Peso Normal";
    if (imc < 30) return "Sobrepeso";
    return "Obesidade";
  }
}
