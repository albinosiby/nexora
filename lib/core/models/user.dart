class User {
  final String id;
  final String name;
  final String phone;
  final String year;
  final String major;
  final String bio;
  final List<String> interests;
  final String imageUrl;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.year,
    required this.major,
    this.bio = '',
    this.interests = const [],
    this.imageUrl = '',
  });
}
