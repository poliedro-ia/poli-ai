class ImageEntry {
  final String id;
  final String downloadUrl;
  final String storagePath;
  final String? model;
  final String? prompt;
  final String? aspectRatio;
  final String? temaSelecionado;
  final String? subareaSelecionada;
  final String? temaResolvido;
  final String? subareaResolvida;
  final int createdAt;

  ImageEntry({
    required this.id,
    required this.downloadUrl,
    required this.storagePath,
    this.model,
    this.prompt,
    this.aspectRatio,
    this.temaSelecionado,
    this.subareaSelecionada,
    this.temaResolvido,
    this.subareaResolvida,
    required this.createdAt,
  });

  factory ImageEntry.fromMap(String id, Map<String, dynamic> map) {
    return ImageEntry(
      id: id,
      downloadUrl: map['downloadUrl'] as String,
      storagePath: map['storagePath'] as String,
      model: map['model'] as String?,
      prompt: map['prompt'] as String?,
      aspectRatio: map['aspectRatio'] as String?,
      temaSelecionado: map['temaSelecionado'] as String?,
      subareaSelecionada: map['subareaSelecionada'] as String?,
      temaResolvido: map['temaResolvido'] as String?,
      subareaResolvida: map['subareaResolvida'] as String?,
      createdAt: (map['createdAt'] as num).toInt(),
    );
  }
}
