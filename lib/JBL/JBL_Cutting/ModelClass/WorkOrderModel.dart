class WorkOrderOption {
  final String work_order;


  const WorkOrderOption({required this.work_order});

  factory WorkOrderOption.fromJson(Map<String, dynamic> json) {
    final v = json['work_order']?.toString() ?? '';
    return WorkOrderOption( work_order: json['work_order']?.toString() ?? v);
  }

  // Dropdown me selected item pe check mark ke liye zaroori
  @override
  bool operator ==(Object other) =>
      other is WorkOrderOption && other.work_order == work_order;

  @override
  int get hashCode => work_order.hashCode;
}