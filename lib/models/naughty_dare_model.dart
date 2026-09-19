class NaughtyDareModel {
  final String id;
  final String category; // 'Sweet', 'Romantic', 'Flirty', 'Sensual', 'Sexual — Mild', 'Couple’s Fantasy', 'Random Mix'
  final String intensity; // 'Sweet', 'Playful', 'Spicy'
  final String dareText;
  final bool isSaved;

  NaughtyDareModel({
    required this.id,
    required this.category,
    required this.intensity,
    required this.dareText,
    this.isSaved = false,
  });

  NaughtyDareModel copyWith({
    String? id,
    String? category,
    String? intensity,
    String? dareText,
    bool? isSaved,
  }) {
    return NaughtyDareModel(
      id: id ?? this.id,
      category: category ?? this.category,
      intensity: intensity ?? this.intensity,
      dareText: dareText ?? this.dareText,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
