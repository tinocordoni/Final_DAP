String? requiredField(String? value) {
  if (value == null || value.trim().isEmpty) return 'Completá este campo.';
  return null;
}

String? emailValidator(String? value) {
  final requiredError = requiredField(value);
  if (requiredError != null) return requiredError;

  final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!emailPattern.hasMatch(value!.trim())) return 'Ingresá un email válido.';
  return null;
}

String? coverUrlValidator(String? value) {
  final requiredError = requiredField(value);
  if (requiredError != null) return requiredError;

  final url = Uri.tryParse(value!.trim());
  if (url == null || url.scheme != 'https' || url.host.isEmpty) {
    return 'Ingresá una URL de imagen que empiece con https://.';
  }
  return null;
}

String? yearValidator(String? value) {
  final requiredError = requiredField(value);
  if (requiredError != null) return requiredError;
  if (int.tryParse(value!.trim()) == null) return 'Ingresá un año válido.';
  return null;
}
