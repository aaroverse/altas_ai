class MenuItem {
  final String originalName;
  final String translatedName;
  final String description;
  final bool isRecommended;
  final String? category;
  final List<String>? potentialAllergens;

  MenuItem({
    required this.originalName,
    required this.translatedName,
    required this.description,
    required this.isRecommended,
    this.category,
    this.potentialAllergens,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      originalName: json['originalName'],
      translatedName: json['translatedName'],
      description: json['description'],
      isRecommended: json['isRecommended'],
      category: json['category'],
      potentialAllergens: json['potentialAllergens'] != null
          ? List<String>.from(json['potentialAllergens'])
          : null,
    );
  }
}
