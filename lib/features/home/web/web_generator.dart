import 'package:flutter/material.dart';
import 'package:app/features/home/options.dart';

class WebGenerator extends StatelessWidget {
  final String selectedTemaLabel;
  final String selectedSubareaLabel;
  final String selectedEstiloLabel;
  final String selectedAspect;
  final bool modoDidatico;

  final TextEditingController promptController;

  final ValueChanged<String> onTemaChanged;
  final ValueChanged<String> onSubareaChanged;
  final ValueChanged<String> onEstiloChanged;
  final ValueChanged<String> onAspectChanged;
  final ValueChanged<bool> onModoDidaticoChanged;

  final bool generating;
  final VoidCallback onGeneratePressed;

  final Widget result;
  final bool isDark;

  const WebGenerator({
    super.key,
    required this.selectedTemaLabel,
    required this.selectedSubareaLabel,
    required this.selectedEstiloLabel,
    required this.selectedAspect,
    required this.modoDidatico,
    required this.promptController,
    required this.onTemaChanged,
    required this.onSubareaChanged,
    required this.onEstiloChanged,
    required this.onAspectChanged,
    required this.onModoDidaticoChanged,
    required this.generating,
    required this.onGeneratePressed,
    required this.result,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final temaValue = temaValueFromLabel(selectedTemaLabel);
    final subs = subareaLabelsForTemaValue(temaValue);

    final pageBg = isDark ? const Color(0xff0B0E19) : const Color(0xffF8FAFC);
    final cardBg = isDark ? const Color(0xff121528) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xff1E2233)
        : const Color(0xffE5E7EB);
    final mainText = isDark ? Colors.white : const Color(0xff111827);
    final subText = isDark ? const Color(0xff97A0B5) : const Color(0xff6B7280);
    final fieldBg = isDark ? const Color(0xff0F1220) : const Color(0xffF9FAFB);
    final fieldBorder = isDark
        ? const Color(0xff23263A)
        : const Color(0xffE5E7EB);

    return Container(
      color: pageBg,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 960;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gerador de Imagens',
                            style: TextStyle(
                              color: mainText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Defina o tema, a subárea e o estilo. Depois descreva a imagem.',
                            style: TextStyle(color: subText),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: selectedTemaLabel,
                                  items: temaOptions
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e['label'] as String,
                                          child: Text(
                                            e['label'] as String,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => onTemaChanged(v!),
                                  decoration: _selectDec(
                                    'Tema',
                                    fieldBg,
                                    fieldBorder,
                                    isDark,
                                  ),
                                  dropdownColor: fieldBg,
                                  style: TextStyle(color: mainText),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: selectedSubareaLabel,
                                  items: subs
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => onSubareaChanged(v!),
                                  decoration: _selectDec(
                                    'Subárea',
                                    fieldBg,
                                    fieldBorder,
                                    isDark,
                                  ),
                                  dropdownColor: fieldBg,
                                  style: TextStyle(color: mainText),
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
                                  value: selectedEstiloLabel,
                                  items: estiloOptions
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e['label'] as String,
                                          child: Text(
                                            e['label'] as String,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => onEstiloChanged(v!),
                                  decoration: _selectDec(
                                    'Estilo Visual',
                                    fieldBg,
                                    fieldBorder,
                                    isDark,
                                  ),
                                  dropdownColor: fieldBg,
                                  style: TextStyle(color: mainText),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: selectedAspect,
                                  items: aspectos
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => onAspectChanged(v!),
                                  decoration: _selectDec(
                                    'Proporção',
                                    fieldBg,
                                    fieldBorder,
                                    isDark,
                                  ),
                                  dropdownColor: fieldBg,
                                  style: TextStyle(color: mainText),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Switch(
                                value: modoDidatico,
                                onChanged: onModoDidaticoChanged,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Modo didático',
                                      style: TextStyle(
                                        color: mainText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Otimize para uso em sala: contraste alto, rótulos claros e foco na compreensão.',
                                      style: TextStyle(
                                        color: subText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: promptController,
                            maxLines: 4,
                            textInputAction: TextInputAction.done,
                            decoration: _inputDec(
                              label: 'Descreva sua imagem',
                              hint:
                                  'Ex: Diagrama de ligação covalente H–H com elétrons e rótulos claros',
                              fieldBg: fieldBg,
                              fieldBorder: fieldBorder,
                              isDark: isDark,
                            ),
                            enableSuggestions: true,
                            autocorrect: true,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 18),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: promptController,
                            builder: (_, v, __) {
                              final can =
                                  v.text.trim().isNotEmpty && !generating;
                              return SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: can ? onGeneratePressed : null,
                                  icon: generating
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.auto_fix_high),
                                  label: Text(
                                    generating ? 'Gerando...' : 'Gerar Imagem',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xff2563EB),
                                    disabledBackgroundColor: const Color(
                                      0xff1B2A52,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resultado',
                            style: TextStyle(
                              color: mainText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sua imagem gerada aparecerá aqui',
                            style: TextStyle(color: subText),
                          ),
                          const SizedBox(height: 12),
                          result,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required String label,
    required String hint,
    required Color fieldBg,
    required Color fieldBorder,
    required bool isDark,
  }) {
    final focus = isDark ? const Color(0xff0092C9) : const Color(0xff2563EB);
    final labelColor = isDark
        ? const Color(0xff97A0B5)
        : const Color(0xff6B7280);
    final hintColor = isDark
        ? const Color(0xff6F7891)
        : const Color(0xff9CA3AF);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: labelColor),
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focus, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  InputDecoration _selectDec(
    String label,
    Color fieldBg,
    Color fieldBorder,
    bool isDark,
  ) {
    final focus = const Color(0xff2563EB);
    final labelColor = isDark
        ? const Color(0xff97A0B5)
        : const Color(0xff6B7280);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      filled: true,
      fillColor: fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focus, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
