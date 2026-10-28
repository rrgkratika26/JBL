class CuttingOutstockJbl {
  final bool active;
  final int srNo;
  final int rollCode;
  final String barcode;
  final String supervisorName;
  final String operatorName;
  final String date;
  final String time;
  final String weekNo;
  final String partyName;
  final String workOrderNo;
  final String orderType;
  final double requiredQuantityKg;
  final double requiredQuantityMtr;
  final String loomNo;
  final String loomType;
  final String fabricTypeFabricUse;
  final String fabricConstruction;
  final String color;
  final String fabricWidth;
  final String fabricGsm;
  final String laminationType;
  final String cutSlipType;
  final String specialIdentification;
  final double rollWeightKg;
  final double rollLengthMtr;
  final String remark;
  final String department;
  final String fabricCode;
  final String inFromDept;
  final String issueToDept;
  final String status;
  final String inStock;
  final String location;
  final String component;
  final String productionType;

  const CuttingOutstockJbl({
    required this.active,
    required this.srNo,
    required this.rollCode,
    required this.barcode,
    required this.supervisorName,
    required this.operatorName,
    required this.date,
    required this.time,
    required this.weekNo,
    required this.partyName,
    required this.workOrderNo,
    required this.orderType,
    required this.requiredQuantityKg,
    required this.requiredQuantityMtr,
    required this.loomNo,
    required this.loomType,
    required this.fabricTypeFabricUse,
    required this.fabricConstruction,
    required this.color,
    required this.fabricWidth,
    required this.fabricGsm,
    required this.laminationType,
    required this.cutSlipType,
    required this.specialIdentification,
    required this.rollWeightKg,
    required this.rollLengthMtr,
    required this.remark,
    required this.department,
    required this.fabricCode,
    required this.inFromDept,
    required this.issueToDept,
    required this.status,
    required this.inStock,
    required this.location,
    required this.component,
    required this.productionType,
  });

  factory CuttingOutstockJbl.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => v?.toString() ?? '';
    int i(dynamic v) => v is num ? v.toInt() : int.tryParse(s(v)) ?? 0;
    double d(dynamic v) => v is num ? v.toDouble() : double.tryParse(s(v)) ?? 0.0;

    return CuttingOutstockJbl(
      active: s(j['active']).toLowerCase() == 'true',
      srNo: i(j['srNo']),
      rollCode: i(j['rollCode']),
      barcode: s(j['barcode']),
      supervisorName: s(j['supervisorName']),
      operatorName: s(j['operatorName']),
      date: s(j['date']),
      time: s(j['time']),
      weekNo: s(j['weekNo']),
      partyName: s(j['partyName']),
      workOrderNo: s(j['workOrderNo']),
      orderType: s(j['orderType']),
      requiredQuantityKg: d(j['requiredQuantityKg']),
      requiredQuantityMtr: d(j['requiredQuantityMtr']),
      loomNo: s(j['loomNo']),
      loomType: s(j['loomType']),
      fabricTypeFabricUse: s(j['fabricTypeFabricUse']),
      fabricConstruction: s(j['fabricConstruction']),
      color: s(j['color']),
      fabricWidth: s(j['fabricWidth']),
      fabricGsm: s(j['fabricGsm']),
      laminationType: s(j['laminationType']),
      cutSlipType: s(j['cutSlipType']),
      specialIdentification: s(j['specialIdentification']),
      rollWeightKg: d(j['rollWeightKg']),
      rollLengthMtr: d(j['rollLengthMtr']),
      remark: s(j['remark']),
      department: s(j['department']),
      fabricCode: s(j['fabricCode']),
      inFromDept: s(j['inFromDept']),
      issueToDept: s(j['issueToDept']),
      status: s(j['status']),
      inStock: s(j['inStock']),
      location: s(j['location']),
      component: s(j['component']),
      productionType: s(j['productionType']),
    );
  }
}