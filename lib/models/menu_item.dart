class MenuItem {
  final String originalName;
  final String translatedName;
  final String description;
  final bool isRecommended;

  MenuItem({
    required this.originalName,
    required this.translatedName,
    required this.description,
    required this.isRecommended,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      originalName: json['originalName'],
      translatedName: json['translatedName'],
      description: json['description'],
      isRecommended: json['isRecommended'],
    );
  }
}
