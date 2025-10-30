import 'package:flutter/material.dart';
import 'package:app/features/history/ui/history_ui.dart';

class DetailsPaneMobile extends StatelessWidget {
  final HistoryPalette palette;
  final String src;
  final String prompt;
  final String model;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const DetailsPaneMobile({
    super.key,
    required this.palette,
    required this.src,
    required this.prompt,
    required this.model,
    required this.onDownload,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.dark ? const Color(0xFF0E1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),

      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes',
            style: TextStyle(
              color: palette.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (model.isNotEmpty) ...[
            Text(
              'Modelo',
              style: TextStyle(
                color: palette.textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(model, style: TextStyle(color: palette.textMain)),
            const SizedBox(height: 10),
          ],
          Text(
            'Prompt utilizado',
            style: TextStyle(
              color: palette.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prompt.isEmpty ? 'Indisponível' : prompt,
            style: TextStyle(color: palette.textMain, height: 1.35),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onDownload,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Baixar'),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    backgroundColor: palette.dark
                        ? const Color(0x332255FF)
                        : const Color(0x33FF5252),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Excluir'),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailsPaneWeb extends StatelessWidget {
  final HistoryPalette palette;
  final String prompt;
  final String model;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const DetailsPaneWeb({
    super.key,
    required this.palette,
    required this.prompt,
    required this.model,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.dark ? const Color(0xff0F1220) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes',
            style: TextStyle(
              color: palette.textMain,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (model.isNotEmpty) ...[
            Text(
              'Modelo',
              style: TextStyle(
                color: palette.textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(model, style: TextStyle(color: palette.textMain)),
            const SizedBox(height: 14),
          ],
          Text(
            'Prompt utilizado',
            style: TextStyle(
              color: palette.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                prompt.isEmpty ? 'Indisponível' : prompt,
                style: TextStyle(
                  color: palette.textMain,
                  height: 1.35,
                  fontSize: 15.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onDownload,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Baixar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Excluir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
