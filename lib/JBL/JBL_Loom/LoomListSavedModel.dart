
class LoomListModel {
  final int id;
  final int rollCode;

  final String barcode;
  final String operator;
  final String supervisor;
  final DateTime? date;
  final String time;

  final String partyName;
  final String workOrderNo;
  final String contNo;

  final double requiredNetWt;
  final double requiredQtyMtr;

  final String loomNo;
  final String modelNo;
  final String mesh;
  final String mash;

  final String fabricType;
  final String fabricConstruction;
  final String color;
  final String fabricWidth;
  final String gsm;
  final String laminationType;
  final String cutSlipType;
  final String specialIdentification;

  final String grossWeight;
  final double netWt;
  final double quantity;
  final String avgWeight;
  final String remark;
  final String department;
  final String flattubegusset;
  final String loomOperator1;

  LoomListModel({
    required this.id,
    required this.rollCode,
    required this.barcode,
    required this.operator,
    required this.supervisor,
    required this.date,
    required this.time,
    required this.partyName,
    required this.workOrderNo,
    required this.contNo,
    required this.requiredNetWt,
    required this.requiredQtyMtr,
    required this.loomNo,
    required this.modelNo,
    required this.mesh,
    required this.mash,
    required this.fabricType,
    required this.fabricConstruction,
    required this.color,
    required this.fabricWidth,
    required this.gsm,
    required this.laminationType,
    required this.cutSlipType,
    required this.specialIdentification,
    required this.grossWeight,
    required this.netWt,
    required this.quantity,
    required this.avgWeight,
    required this.remark,
    required this.department,
    required this.flattubegusset,
    required this.loomOperator1,
  });

  factory LoomListModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    String toText(dynamic value) {
      return value?.toString() ?? '';
    }

    DateTime? toDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    return LoomListModel(
      id: int.tryParse(
        toText(json['srNo'] ?? json['id']),
      ) ??
          0,

      rollCode: int.tryParse(
        toText(json['rollCode']),
      ) ??
          0,

      barcode: toText(json['barcode']),
      operator: toText(json['operatorName']),
      supervisor: toText(json['supervisorName']),
      date: toDate(json['date']),
      time: toText(json['time']),

      partyName: toText(json['partyName']),
      workOrderNo: toText(json['workOrderNo']),
      contNo: toText(json['contNo']),

      requiredNetWt: toDouble(json['requiredQuantityKg']),
      requiredQtyMtr: toDouble(json['requiredQuantityMtr']),

      loomNo: toText(json['loomNo']),
      modelNo: toText(json['loomType']),

      mesh: toText(json['mesh']),
      mash: toText(json['mash']),

      fabricType: toText(json['fabricType']),
      fabricConstruction: toText(json['fabricConstruction']),
      color: toText(json['color']),
      fabricWidth: toText(json['fabricWidth']),
      gsm: toText(json['fabricGsm']),

      laminationType: toText(json['laminationType']),
      cutSlipType: toText(json['cutSlipType']),
      specialIdentification: toText(json['specialIdentification']),

      grossWeight: toText(json['grossWeight']),
      netWt: toDouble(json['netWeight']),
      quantity: toDouble(json['rollLength']),
      avgWeight: toText(json['avgWeight']),

      remark: toText(json['remark']),
      department: toText(json['department']),
      flattubegusset: toText(json['fabricCode']),
      loomOperator1: toText(json['loomOperator1']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srNo': id,
      'rollCode': rollCode,
      'barcode': barcode,
      'supervisorName': supervisor,
      'operatorName': operator,
      'date': date?.toIso8601String(),
      'time': time,
      'partyName': partyName,
      'workOrderNo': workOrderNo,
      'contNo': contNo,
      'requiredQuantityKg': requiredNetWt,
      'requiredQuantityMtr': requiredQtyMtr,
      'loomNo': loomNo,
      'loomType': modelNo,
      'mesh': mesh,
      'mash': mash,
      'fabricType': fabricType,
      'fabricConstruction': fabricConstruction,
      'color': color,
      'fabricWidth': fabricWidth,
      'fabricGsm': gsm,
      'laminationType': laminationType,
      'cutSlipType': cutSlipType,
      'specialIdentification': specialIdentification,
      'grossWeight': grossWeight,
      'netWeight': netWt,
      'rollLength': quantity,
      'avgWeight': avgWeight,
      'remark': remark,
      'department': department,
      'fabricCode': flattubegusset,
      'loomOperator1': loomOperator1,
    };
  }
}
