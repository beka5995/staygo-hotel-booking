class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    required this.dateText,
    this.isCompleted = false,
  });
  final String id;
  final String title;
  final String dateText;
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dateText': dateText,
    'isCompleted': isCompleted,
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        (json['id'] as String).isEmpty ||
        json['title'] is! String ||
        (json['title'] as String).trim().isEmpty ||
        json['dateText'] is! String ||
        json['isCompleted'] is! bool) {
      throw const FormatException('Invalid saved note');
    }
    return NoteItem(
      id: json['id'] as String,
      title: json['title'] as String,
      dateText: json['dateText'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  NoteItem toggle() => NoteItem(
    id: id,
    title: title,
    dateText: dateText,
    isCompleted: !isCompleted,
  );
}
