import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app/core/configs/theme/colors.dart';
import 'package:app/features/home/options.dart';

class ControlsCard extends StatelessWidget {
  final String selectedTemaLabel;
  final String selectedSubareaLabel;
  final String selectedEstiloLabel;
  final String selectedAspect;
  final bool modoDidatico;
  final ValueChanged<String> onTemaChanged;
  final ValueChanged<String> onSubareaChanged;
  final ValueChanged<String> onEstiloChanged;
  final ValueChanged<String> onAspectChanged;
  final ValueChanged<bool> onModoDidaticoChanged;

  const ControlsCard({
    super.key,
    required this.selectedTemaLabel,
    required this.selectedSubareaLabel,
    required this.selectedEstiloLabel,
    required this.selectedAspect,
    required this.modoDidatico,
    required this.onTemaChanged,
    required this.onSubareaChanged,
    required this.onEstiloChanged,
    required this.onAspectChanged,
    required this.onModoDidaticoChanged,
  });

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightBlue, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temaValue = temaValueFromLabel(selectedTemaLabel);
    final subLabels = subareaLabelsForTemaValue(temaValue);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedTemaLabel,
                      items: temaOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['label'] as String,
                              child: Row(
                                children: [
                                  const Icon(Icons.category_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e['label'] as String,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        onTemaChanged(v);
                      },
                      decoration: _dec('Tema'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: subLabels.contains(selectedSubareaLabel)
                          ? selectedSubareaLabel
                          : subLabels.first,
                      items: subLabels
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.scatter_plot_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        onSubareaChanged(v);
                      },
                      decoration: _dec('Subárea'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedEstiloLabel,
                      items: estiloOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['label'] as String,
                              child: Row(
                                children: [
                                  const Icon(Icons.brush_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e['label'] as String,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        onEstiloChanged(v);
                      },
                      decoration: _dec('Estilo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedAspect,
                      items: aspectos
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  const Icon(Icons.aspect_ratio, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        onAspectChanged(v);
                      },
                      decoration: _dec('Proporção'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Switch(
                      value: modoDidatico,
                      onChanged: onModoDidaticoChanged,
                      activeThumbColor: AppColors.lightBlue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Modo Didático',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
