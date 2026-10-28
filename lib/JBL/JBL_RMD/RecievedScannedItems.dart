class ReceiveScannedItem {
  final int srNo;
  final int rollCode;
  final String barcode;
  final String supervisorName;
  final String partyName;
  final String workOrderNo;
  final String loomNo;
  final String loomType;
  final String fabricCode;
  final String color;
  final String fabricWidth;
  final String fabricGsm;
  final String grossWeightKg;
  final double netWeightKg;
  final double rollLengthMtr;
  final String tareWeightKg;
  final String department;
  final String inFromDept;
  final String issueToDept;
  final String status;
  final String inStock;
  final String location;
  final String remark;
  final DateTime? date;

  ReceiveScannedItem({
    required this.srNo,
    required this.rollCode,
    required this.barcode,
    required this.supervisorName,
    required this.partyName,
    required this.workOrderNo,
    required this.loomNo,
    required this.loomType,
    required this.fabricCode,
    required this.color,
    required this.fabricWidth,
    required this.fabricGsm,
    required this.grossWeightKg,
    required this.netWeightKg,
    required this.rollLengthMtr,
    required this.tareWeightKg,
    required this.department,
    required this.inFromDept,
    required this.issueToDept,
    required this.status,
    required this.inStock,
    required this.location,
    required this.remark,
    required this.date,
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static int _i(dynamic v) => int.tryParse(_s(v)) ?? 0;
  static double _d(dynamic v) => double.tryParse(_s(v)) ?? 0;

  factory ReceiveScannedItem.fromJson(Map<String, dynamic> j) {
    return ReceiveScannedItem(
      srNo: _i(j['srNo']),
      rollCode: _i(j['rollCode']),
      barcode: _s(j['barcode']),
      supervisorName: _s(j['supervisorName']),
      partyName: _s(j['partyName']),
      workOrderNo: _s(j['workOrderNo']),
      loomNo: _s(j['loomNo']),
      loomType: _s(j['loomType']),
      fabricCode: _s(j['fabricCode']),
      color: _s(j['color']),
      fabricWidth: _s(j['fabricWidth']),
      fabricGsm: _s(j['fabricGsm']),
      grossWeightKg: _s(j['grossWeightKg']),
      netWeightKg: _d(j['netWeightKg']),
      rollLengthMtr: _d(j['rollLengthMtr']),
      tareWeightKg: _s(j['tareWeightKg']),
      department: _s(j['department']),
      inFromDept: _s(j['inFromDept']),
      issueToDept: _s(j['issueToDept']),
      status: _s(j['status']),
      inStock: _s(j['inStock']),
      location: _s(j['location']),
      remark: _s(j['remark']),
      date: DateTime.tryParse(_s(j['date'])),
    );
  }
}