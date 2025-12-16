class Genre {
  final String id;
  final String name;
  final String? imageUrl;

  Genre({required this.id, required this.name, this.imageUrl});

  factory Genre.fromMap(Map<String, dynamic> m) {
    return Genre(
      id: m['id'].toString(),
      name: m['name']?.toString() ?? '',
      imageUrl: m['image_url']?.toString(),
    );
  }
}
