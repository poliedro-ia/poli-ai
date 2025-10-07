class Validators {
  static String? requiredField(String? v, {String label = 'Campo'}) {
    if (v == null || v.trim().isEmpty) return '$label é obrigatório';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email é obrigatório';
    final r = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!r.hasMatch(v.trim())) return 'Email inválido';
    return null;
  }

  static String? password(String? v, {int min = 6}) {
    if (v == null || v.isEmpty) return 'Senha é obrigatória';
    if (v.length < min) return 'Senha deve ter ao menos $min caracteres';
    return null;
  }

  static bool emailDomainAllowed(String email) {
    final e = email.trim().toLowerCase();
    return e.endsWith('@sistemapoliedro.com.br') || e.endsWith('@p4ed.com');
  }
}
