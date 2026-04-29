class CategoryModel {
  final String name;
  final String icon;
  final int color;
  final String type; // 'income' or 'expense'

  CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}
