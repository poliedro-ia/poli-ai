import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/features/home/ui/home_ui.dart';

class GeneratorPanel extends StatelessWidget {
  final HomePalette p;
  final String tema;
  final String subarea;
  final String estilo;
  final String aspect;
  final bool didatico;

  final List<String> temaOptions;
  final List<String> subareaOptions;
  final List<String> estiloOptions;
  final List<String> aspectOptions;

  final void Function(String) onTema;
  final void Function(String) onSubarea;
  final void Function(String) onEstilo;
  final void Function(String) onAspect;
  final void Function(bool) onDidatico;

  final TextEditingController prompt;
  final bool loading;
  final VoidCallback onGenerate;

  const GeneratorPanel({
    super.key,
    required this.p,
    required this.tema,
    required this.subarea,
    required this.estilo,
    required this.aspect,
    required this.didatico,
    required this.temaOptions,
    required this.subareaOptions,
    required this.estiloOptions,
    required this.aspectOptions,
    required this.onTema,
    required this.onSubarea,
    required this.onEstilo,
    required this.onAspect,
    required this.onDidatico,
    required this.prompt,
    required this.loading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalGap = kIsWeb ? 32.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: p.layer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      padding: p.blockPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gerador de Imagens',
            style: TextStyle(
              color: p.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: kIsWeb ? 12 : 8),
          Text(
            'Defina as opções e descreva sua imagem.',
            style: TextStyle(color: p.subText),
          ),
          SizedBox(height: kIsWeb ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: tema,
                  items: temaOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => v != null ? onTema(v) : null,
                  decoration: HomeDeco.select('Tema', p),
                  dropdownColor: p.fieldBg,
                  style: TextStyle(color: p.text),
                ),
              ),
              SizedBox(width: horizontalGap),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: subarea,
                  items: subareaOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => v != null ? onSubarea(v) : null,
                  decoration: HomeDeco.select('Subárea', p),
                  dropdownColor: p.fieldBg,
                  style: TextStyle(color: p.text),
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: estilo,
                  items: estiloOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => v != null ? onEstilo(v) : null,
                  decoration: HomeDeco.select('Estilo', p),
                  dropdownColor: p.fieldBg,
                  style: TextStyle(color: p.text),
                ),
              ),
              SizedBox(width: horizontalGap),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: aspect,
                  items: aspectOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => v != null ? onAspect(v) : null,
                  decoration: HomeDeco.select('Proporção', p),
                  dropdownColor: p.fieldBg,
                  style: TextStyle(color: p.text),
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          Row(
            children: [
              Switch(value: didatico, onChanged: onDidatico),
              const SizedBox(width: 8),
              Text(
                'Modo Didático',
                style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          TextFormField(
            controller: prompt,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            cursorColor: p.cta,
            style: TextStyle(color: p.text),
            decoration: HomeDeco.input(
              label: 'Descreva sua imagem',
              hint: 'Ex: Diagrama de ligação covalente H–H com rótulos claros',
              p: p,
            ),
            enableSuggestions: true,
            autocorrect: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          SizedBox(height: kIsWeb ? 22 : 18),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: prompt,
            builder: (_, v, __) {
              final can = v.text.trim().isNotEmpty && !loading;
              final fg = p.dark
                  ? (can ? Colors.white : const Color(0xFF2B3347))
                  : null;
              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: can ? onGenerate : null,
                  icon: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(loading ? 'Gerando...' : 'Gerar Imagem'),
                  style: FilledButton.styleFrom(
                    foregroundColor: fg,
                    backgroundColor: p.cta,
                    disabledBackgroundColor: p.dark
                        ? const Color(0xff1B2A52)
                        : const Color(0xffC8D7FE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(vertical: kIsWeb ? 20 : 18),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
