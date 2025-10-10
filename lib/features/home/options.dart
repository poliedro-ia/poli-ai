import 'package:flutter/material.dart';

const temaOptions = [
  {'label': 'Física', 'value': 'fisica'},
  {'label': 'Química', 'value': 'quimica'},
];

const subareaOptions = {
  'fisica': [
    {'label': 'Mecânica', 'value': 'mecanica'},
    {'label': 'Óptica', 'value': 'optica'},
    {'label': 'Eletricidade', 'value': 'eletricidade'},
    {'label': 'Termodinâmica', 'value': 'termodinamica'},
  ],
  'quimica': [
    {'label': 'Atomística', 'value': 'atomistica'},
    {'label': 'Ligações', 'value': 'ligacoes'},
    {'label': 'Estequiometria', 'value': 'estequiometria'},
    {'label': 'Reações', 'value': 'reacoes'},
  ],
};

const estiloOptions = [
  {'label': 'Vetor', 'value': 'vetor'},
  {'label': 'Realista', 'value': 'realista'},
  {'label': 'Desenho Animado', 'value': 'desenho animado'},
];

const aspectos = ['1:1', '3:2', '4:3', '16:9', '9:16'];

String temaValueFromLabel(String label) {
  return temaOptions.firstWhere((e) => e['label'] == label)['value'] as String;
}

String temaLabelFromValue(String value) {
  return temaOptions.firstWhere((e) => e['value'] == value)['label'] as String;
}

List<String> subareaLabelsForTemaValue(String temaValue) {
  return subareaOptions[temaValue]!.map((e) => e['label'] as String).toList();
}

String subareaValueFromLabel(String temaValue, String label) {
  return (subareaOptions[temaValue]!.firstWhere(
        (e) => e['label'] == label,
      )['value'])
      as String;
}

String subareaLabelFromValue(String temaValue, String value) {
  return (subareaOptions[temaValue]!.firstWhere(
        (e) => e['value'] == value,
      )['label'])
      as String;
}

String estiloValueFromLabel(String label) {
  return estiloOptions.firstWhere((e) => e['label'] == label)['value']
      as String;
}

String estiloLabelFromValue(String value) {
  return estiloOptions.firstWhere((e) => e['value'] == value)['label']
      as String;
}

InputDecoration dropDeco(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1E6C86), width: 1.4),
    ),
  );
}
