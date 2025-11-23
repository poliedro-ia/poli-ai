import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/features/home/ui/home_ui.dart';

class GeneratorPanel extends StatefulWidget {
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
  State<GeneratorPanel> createState() => _GeneratorPanelState();
}

class _GeneratorPanelState extends State<GeneratorPanel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final horizontalGap = kIsWeb ? 32.0 : 12.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: p.layer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(p.dark ? 0.35 : 0.14),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(p.dark ? 0.22 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
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
                    value: widget.tema,
                    items: widget.temaOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.science_rounded,
                                  size: 18,
                                  color: p.subText,
                                ),
                                const SizedBox(width: 8),
                                Text(s),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => v != null ? widget.onTema(v) : null,
                    decoration: HomeDeco.select('Tema', p),
                    dropdownColor: p.fieldBg,
                    style: TextStyle(color: p.text),
                    icon: Icon(Icons.expand_more_rounded, color: p.subText),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                SizedBox(width: horizontalGap),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: widget.subarea,
                    items: widget.subareaOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_rounded,
                                  size: 18,
                                  color: p.subText,
                                ),
                                const SizedBox(width: 8),
                                Text(s),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => v != null ? widget.onSubarea(v) : null,
                    decoration: HomeDeco.select('Subárea', p),
                    dropdownColor: p.fieldBg,
                    style: TextStyle(color: p.text),
                    icon: Icon(Icons.expand_more_rounded, color: p.subText),
                    borderRadius: BorderRadius.circular(16),
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
                    value: widget.estilo,
                    items: widget.estiloOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.brush_rounded,
                                  size: 18,
                                  color: p.subText,
                                ),
                                const SizedBox(width: 8),
                                Text(s),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => v != null ? widget.onEstilo(v) : null,
                    decoration: HomeDeco.select('Estilo', p),
                    dropdownColor: p.fieldBg,
                    style: TextStyle(color: p.text),
                    icon: Icon(Icons.expand_more_rounded, color: p.subText),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                SizedBox(width: horizontalGap),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: widget.aspect,
                    items: widget.aspectOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.crop_rounded,
                                  size: 18,
                                  color: p.subText,
                                ),
                                const SizedBox(width: 8),
                                Text(s),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => v != null ? widget.onAspect(v) : null,
                    decoration: HomeDeco.select('Proporção', p),
                    dropdownColor: p.fieldBg,
                    style: TextStyle(color: p.text),
                    icon: Icon(Icons.expand_more_rounded, color: p.subText),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
            SizedBox(height: kIsWeb ? 16 : 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: p.dark
                    ? const Color(0x221E293B)
                    : const Color(0x11BFDBFE),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: widget.didatico,
                    onChanged: widget.onDidatico,
                    activeColor: Colors.white,
                    activeTrackColor: p.cta,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Modo Didático',
                    style: TextStyle(
                      color: p.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: kIsWeb ? 16 : 12),
            TextFormField(
              controller: widget.prompt,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              cursorColor: p.cta,
              style: TextStyle(color: p.text),
              decoration: HomeDeco.input(
                label: 'Descreva sua imagem',
                hint:
                    'Ex: Diagrama de ligação covalente H–H com rótulos claros',
                p: p,
              ),
              enableSuggestions: true,
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: kIsWeb ? 22 : 18),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.prompt,
              builder: (_, v, __) {
                final can = v.text.trim().isNotEmpty && !widget.loading;
                final fg = p.dark
                    ? (can ? Colors.white : const Color(0xFF2B3347))
                    : null;
                return AnimatedScale(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  scale: can ? 1.0 : 0.97,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: can ? widget.onGenerate : null,
                      icon: widget.loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high_rounded),
                      label: Text(
                        widget.loading ? 'Gerando...' : 'Gerar Imagem',
                      ),
                      style: FilledButton.styleFrom(
                        foregroundColor: fg,
                        backgroundColor: p.cta,
                        disabledBackgroundColor: p.dark
                            ? const Color(0xff1B2A52)
                            : const Color(0xffC8D7FE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: kIsWeb ? 20 : 18,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
