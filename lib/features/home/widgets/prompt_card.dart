import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app/core/configs/theme/colors.dart';

class PromptCard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const PromptCard({
    super.key,
    required this.controller,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  State<PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<PromptCard> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  InputDecoration _dec() {
    return InputDecoration(
      labelText: _focused ? null : 'Descreva sua imagem...',
      hintText: _focused
          ? 'Ex: Diagrama de ligação covalente H–H com pares de elétrons e rótulos'
          : null,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.lightBlue, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              TextField(
                controller: widget.controller,
                focusNode: _focus,
                minLines: 4,
                maxLines: 4,
                textAlignVertical: TextAlignVertical.top,
                textInputAction: TextInputAction.newline,
                enableSuggestions: true,
                autocorrect: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.isGenerating ? null : widget.onGenerate,
                  icon: Icon(
                    widget.isGenerating
                        ? Icons.hourglass_empty
                        : Icons.auto_awesome,
                  ),
                  label: Text(
                    widget.isGenerating ? 'Gerando...' : 'Gerar Imagem',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
