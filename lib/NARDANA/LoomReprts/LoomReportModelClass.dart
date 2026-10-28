import 'package:intl/intl.dart';

class LoomReport {
  final int srNo;
  final int rollCode;
  final String bomNo;
  final String barcode;
  final String batchNo;
  final String loomType;
  final int loomNo;
  final String fabricCode;
  final double grossWeight;
  final double netWeight;
  final int rollLength;
  final double avgWeight;
  final String operatorName;
  final DateTime date;
  final String time;

  final String loomOperator1;
  final String supervisorName;
  final String partyName;
  final String workOrderNo;
  final String machineNo;

  final double requiredQty;
  final double requiredQtyMtr;
  final double tareWeight;

  final String department;
  final String issueToDept;
  final String status;
  final String entryIn;
  final String entryOut;

  final String mesh;
  final String fabricType;
  final String fabricConstruction;
  final String color;
  final String fabricWidth;
  final String fabricGsm;
  final String laminationType;
  final String cutSlipType;
  final String specialIdentification;

  LoomReport({
    required this.srNo,
    required this.rollCode,
    required this.barcode,
    required this.batchNo,
    required this.loomType,
    required this.loomNo,
    required this.fabricCode,
    required this.grossWeight,
    required this.netWeight,
    required this.rollLength,
    required this.avgWeight,
    required this.operatorName,
    required this.date,
    required this.time,
    required this.loomOperator1,
    required this.supervisorName,
    required this.partyName,
    required this.workOrderNo,
    required this.machineNo,
    required this.requiredQty,
    required this.requiredQtyMtr,
    required this.tareWeight,
    required this.department,
    required this.issueToDept,
    required this.status,
    required this.entryIn,
    required this.entryOut,
    required this.mesh,
    required this.fabricType,
    required this.fabricConstruction,
    required this.color,
    required this.fabricWidth,
    required this.fabricGsm,
    required this.laminationType,
    required this.cutSlipType,
    required this.specialIdentification, required this.bomNo,
  });

  factory LoomReport.fromJson(Map<String, dynamic> json) {
    return LoomReport(
      srNo: int.tryParse(json['id'].toString()) ?? 0,
      rollCode: int.tryParse(json['rolL_CODE'].toString()) ?? 0,
      barcode: json['barcode'] ?? '',
      batchNo: json['batcH_NO'] ?? '',
      loomType: json['looM_TYPE'] ?? '',
      loomNo: int.tryParse(json['looM_NO'].toString()) ?? 0,
      fabricCode: json['fabriC_CODE'] ?? '',

      grossWeight: double.tryParse(json['grosS_WEIGHT'].toString()) ?? 0,
      netWeight: double.tryParse(json['neT_WEIGHT'].toString()) ?? 0,
      rollLength: int.tryParse(json['rolL_LENGTH'].toString()) ?? 0,
      avgWeight: double.tryParse(json['avG_WEIGHT'].toString()) ?? 0,

      operatorName: json['operatoR_NAME'] ?? '',
      // date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      date: DateTime.tryParse(
        json['date']?.toString() ?? '',
      ) ??
          DateTime.now(),
      time: json['time'] ?? '',

      loomOperator1: json['loomoparetoR1'] ?? '',
      supervisorName: json['supervisoR_NAME'] ?? '',
      partyName: json['partyname'] ?? '',
      workOrderNo: json['worK_ORDER_NO'] ?? '',
      machineNo: json['machineno'] ?? '',

      requiredQty: double.tryParse(json['requireD_QUANTITY'].toString()) ?? 0,
      requiredQtyMtr: double.tryParse(json['requireD_QUANTITY_MTR'].toString()) ?? 0,
      tareWeight: double.tryParse(json['tarE_WEIGHT'].toString()) ?? 0,

      department: json['department'] ?? '',
      issueToDept: json['issuE_TO_DEPT'] ?? '',
      status: json['status'] ?? '',
      entryIn: json['entryin'] ?? '',
      entryOut: json['entryout'] ?? '',

      mesh: json['mash'] ?? '',
      fabricType: json['fabriC_TYPE'] ?? '',
      fabricConstruction: json['fabriC_CONSTRUCTION'] ?? '',
      color: json['color'] ?? '',
      fabricWidth: json['fabriC_WIDTH'] ?? '',
      fabricGsm: json['fabriC_GSM'] ?? '',
      laminationType: json['laminatioN_TYPE'] ?? '',
      cutSlipType: json['cuT_SLIP_TYPE'] ?? '',
      specialIdentification: json['speciaL_IDENTIFICATION'] ?? '',
      bomNo: json['boM_NO'] ?? '',
    );
  }
}




class LoomReportjBL {
  final int srNo;
  final int rollCode;
  final String barcode;
  final String loomType;
  final String loomNo;
  final String fabricCode;

  final double grossWeight;
  final double netWeight;
  final double rollLength;
  final double avgWeight;

  final String operatorName;
  final DateTime date;
  final String time;
  final String loomOperator1;
  final String fabricGsm;
  final String supervisorName;

  final String partyName;
  final String workOrderNo;
  final String contNo;

  final double requiredQty;
  final double requiredQtyMtr;
  final double tareWeight;

  final String department;
  final String issueToDept;
  final String status;
  final String entryIn;
  final String entryOut;
  final String mesh;
  final String fabricType;
  final String fabricConstruction;
  final String color;
  final String fabricWidth;
  final String laminationType;
  final String cutSlipType;
  final String specialIdentification;

  const LoomReportjBL({
    required this.srNo,
    required this.rollCode,
    required this.barcode,
    required this.loomType,
    required this.loomNo,
    required this.fabricCode,
    required this.grossWeight,
    required this.netWeight,
    required this.rollLength,
    required this.avgWeight,
    required this.operatorName,
    required this.date,
    required this.time,
    required this.loomOperator1,
    required this.fabricGsm,
    required this.supervisorName,
    required this.partyName,
    required this.workOrderNo,
    required this.contNo,
    required this.requiredQty,
    required this.requiredQtyMtr,
    required this.tareWeight,
    required this.department,
    required this.issueToDept,
    required this.status,
    required this.entryIn,
    required this.entryOut,
    required this.mesh,
    required this.fabricType,
    required this.fabricConstruction,
    required this.color,
    required this.fabricWidth,
    required this.laminationType,
    required this.cutSlipType,
    required this.specialIdentification,
  });

  static String _string(dynamic value) {
    return value?.toString() ?? '';
  }

  static double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    return double.tryParse(
      value.toString().replaceAll(',', '').trim(),
    ) ??
        0;
  }

  static int _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory LoomReportjBL.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'];

    return LoomReportjBL(
      srNo: _integer(json['srNo']),
      rollCode: _integer(json['rollCode']),
      barcode: _string(json['barcode']),
      loomType: _string(json['loomType']),
      loomNo: _string(json['loomNo']),
      fabricCode: _string(json['fabricCode']),

      grossWeight: _number(json['grossWeightKg']),
      netWeight: _number(json['netWeightKg']),
      rollLength: _number(json['rollLengthMtr']),
      avgWeight: _number(json['avgWeightGm']),

      operatorName: _string(json['operatorName']),
      date: DateTime.tryParse(_string(dateValue)) ??
          DateTime(2000),
      time: _string(json['time']),
      loomOperator1: _string(json['loomOperator1']),
      fabricGsm: _string(json['gsmMtrGm']),
      supervisorName: _string(json['supervisorName']),

      partyName: _string(json['partyName']),
      workOrderNo: _string(json['workOrderNo']),
      contNo: _string(json['contNo']),

      requiredQty: _number(json['requiredQuantityKg']),
      requiredQtyMtr: _number(json['requiredQuantityMtr']),
      tareWeight: _number(json['tareWeightKg']),

      department: _string(json['department']),
      issueToDept: _string(json['issueToDept']),
      status: _string(json['status']),
      entryIn: _string(json['entryIn']),
      entryOut: _string(json['entryOut']),
      mesh: _string(json['mash']),
      fabricType: _string(json['fabricTypeFabricUse']),
      fabricConstruction: _string(json['fabricConstruction']),
      color: _string(json['color']),
      fabricWidth: _string(json['fabricWidth']),
      laminationType: _string(json['laminationType']),
      cutSlipType: _string(json['cutSlipType']),
      specialIdentification: _string(json['specialIdentification']),
    );
  }

  static List<LoomReportjBL> fromApiResponse(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(LoomReportjBL.fromJson)
          .toList();
    }

    if (response is Map<String, dynamic>) {
      final data = response['data'];

      if (response['success'] == false) {
        throw Exception(
          response['message']?.toString() ?? 'API request failed',
        );
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(LoomReportjBL.fromJson)
            .toList();
      }
    }

    throw const FormatException(
      'Invalid Loom Out Report API response',
    );
  }

  // Retain compatibility with code that uses these existing names.
  String get machineNo => contNo;
}
