class AppValidators {
  AppValidators._();

  static String? required(String? value, [String fieldName = 'Campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'E-mail é obrigatório';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'E-mail inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória';
    if (value.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty)
      return 'Confirmação de senha é obrigatória';
    if (value != password) return 'As senhas não coincidem';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) return 'Valor é obrigatório';
    final cleaned = value
        .replaceAll(RegExp(r'[R\$\s\.]'), '')
        .replaceAll(',', '.');
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return 'Valor inválido';
    if (parsed <= 0) return 'Valor deve ser maior que zero';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nome é obrigatório';
    if (value.trim().length < 2) return 'Nome muito curto';
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) return 'Valor é obrigatório';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Número inválido';
    if (parsed <= 0) return 'Deve ser positivo';
    return null;
  }
}

