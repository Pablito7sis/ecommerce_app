class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.rating,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final double rating;

  factory Product.fromJson(Map<String, dynamic> json) {
    final ratingData = json['rating'];

    return Product(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Producto sin nombre',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      category: json['category'] as String? ?? 'General',
      imageUrl: (json['image'] as String?) ?? (json['image_url'] as String?) ?? '',
      rating: ratingData is Map<String, dynamic>
          ? (ratingData['rate'] as num? ?? 0).toDouble()
          : (json['rating'] as num? ?? 0).toDouble(),
    );
  }
}
