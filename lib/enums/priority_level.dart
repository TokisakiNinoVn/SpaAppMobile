enum PriorityLevel {
  now('Cần ngay', 'now'),
  normal('Bình thường', 'normal');

  final String label;
  final String name;
  const PriorityLevel(this.label, this.name);
}