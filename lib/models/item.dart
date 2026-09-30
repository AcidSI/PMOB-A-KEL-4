// Data satu laporan Lost & Found yang dikirim antarhalaman.
class Item {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String location;
  final String timeAgo;
  final bool isFound;

  const Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.isFound,
  });
}