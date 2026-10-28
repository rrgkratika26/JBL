
class Roll {
final int id;
final bool active;
final int srNo;
final String rollCode;
final String bomNo;

final String barcode;
final String fabricCode;
final String grossWeight;
final String tareWeight;
final String netWeight;
final String rollLength;
final String avgWeight;

// New API fields
final String requrdqtymtr;
final String requrdqtkg;
final String loomtype;
final String loomno;

Roll({
required this.id,
required this.active,
required this.srNo,
required this.rollCode,
required this.barcode,
required this.fabricCode,
required this.grossWeight,
required this.tareWeight,
required this.netWeight,
required this.rollLength,
required this.avgWeight,
required this.bomNo,
required this.requrdqtymtr,
required this.requrdqtkg,
required this.loomtype,
required this.loomno,
});

factory Roll.fromJson(Map<String, dynamic> json) => Roll(
id: json['id'] is int
? json['id']
    : int.tryParse(json['id']?.toString() ?? '') ?? 0,

active: json['active'] ?? false,

srNo: json['srNo'] is int
? json['srNo']
    : int.tryParse(json['srNo']?.toString() ?? '') ?? 0,

rollCode: json['rollCode']?.toString() ?? '',
barcode: json['barcode']?.toString() ?? '',
fabricCode: json['fabricCode']?.toString() ?? '',
grossWeight: json['grossWeight']?.toString() ?? '',
tareWeight: json['tareWeight']?.toString() ?? '',
netWeight: json['netWeight']?.toString() ?? '',
rollLength: json['rollLength']?.toString() ?? '',
avgWeight: json['avgWeight']?.toString() ?? '',

// Existing field
bomNo: json['boM_NO']?.toString() ?? '',

// New API fields
requrdqtymtr: json['requrdqtymtr']?.toString() ?? '',
requrdqtkg: json['requrdqtkg']?.toString() ?? '',
loomtype: json['loomtype']?.toString() ?? '',
loomno: json['loomno']?.toString() ?? '',
);
}
