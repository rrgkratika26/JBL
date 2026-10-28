
import '../../../ScannedItem/Loom/LoomModelClass.dart';

class ProductionModel {
final int orderNo;
final String bomNo;
final String partyName;
final String fabricCode;

final double actualRequiredKg;
final double actualRequiredMtr;
final double sumOutKg;
final double sumOutMtr;
final double balanceKg;
final double balanceMtr;

final String flatTubeGusset;

// NEW FIELDS
final String articleNo;
final String poNumber;
final String customerName;

final double requiredKg;
final double requiredMtr;

final double productionKg;
final double productionMtr;

final double balanceKgInt;
final double balanceMtrInt;

final String woNo;
final bool status;

ProductionModel({
required this.orderNo,
required this.bomNo,
required this.partyName,
required this.fabricCode,
required this.actualRequiredKg,
required this.actualRequiredMtr,
required this.sumOutKg,
required this.sumOutMtr,
required this.balanceKg,
required this.balanceMtr,
required this.flatTubeGusset,

// NEW
required this.articleNo,
required this.poNumber,
required this.customerName,
required this.requiredKg,
required this.requiredMtr,
required this.productionKg,
required this.productionMtr,
required this.balanceKgInt,
required this.balanceMtrInt,
required this.woNo,
required this.status,
});

// Safely convert API values to String.
static String _toStringValue(dynamic value) {
return value?.toString() ?? '';
}

// Safely convert API values to int.
static int _toInt(dynamic value) {
if (value is int) return value;
if (value is num) return value.toInt();
return int.tryParse(value?.toString() ?? '') ?? 0;
}

// Safely convert API values to double.
static double _toDouble(dynamic value) {
if (value is num) return value.toDouble();
return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

// Safely convert API values to bool.
static bool _toBool(dynamic value) {
if (value is bool) return value;
if (value is num) return value != 0;

final text = value?.toString().toLowerCase().trim() ?? '';

return text == 'true' ||
text == '1' ||
text == 'yes';
}

factory ProductionModel.fromJson(Map<String, dynamic> json) {
return ProductionModel(
orderNo: _toInt(json['orderNo']),

// API may return boM_NO, bomNo, or BOM_NO.
bomNo: _toStringValue(
json['boM_NO'] ?? json['bomNo'] ?? json['BOM_NO'],
),

partyName: _toStringValue(json['partyName']),
fabricCode: _toStringValue(json['fabricCode']),

actualRequiredKg: _toDouble(json['actualRequiredKg']),
actualRequiredMtr: _toDouble(json['actualRequiredMtr']),
sumOutKg: _toDouble(json['sumOutKg']),
sumOutMtr: _toDouble(json['sumOutMtr']),
balanceKg: _toDouble(json['balanceKg']),
balanceMtr: _toDouble(json['balanceMtr']),

flatTubeGusset: _toStringValue(json['flatTubeGusset']),

// NEW FIELDS
articleNo: _toStringValue(json['articleNo']),
poNumber: _toStringValue(json['poNumber']),
customerName: _toStringValue(json['customerName']),

requiredKg: _toDouble(json['requiredKg']),
requiredMtr: _toDouble(json['requiredMtr']),

productionKg: _toDouble(json['productionKg']),
productionMtr: _toDouble(json['productionMtr']),

balanceKgInt: _toDouble(json['balanceKg']),
balanceMtrInt: _toDouble(json['balanceMtr']),

woNo: _toStringValue(json['woNo']),
status: _toBool(json['status']),
);
}
}

ProductionModel convertToProduction(LoomOrder order) {
return ProductionModel(
orderNo: int.tryParse(order.loomOrderNo) ?? 0,
partyName: order.customerName,
bomNo: order.bom,

// Use fabricCode if available; otherwise use requiredFabricCode.
fabricCode: order.fabricCode.isNotEmpty
? order.fabricCode
    : order.requiredFabricCode,

actualRequiredKg: order.requiredQuantityKg.toDouble(),
actualRequiredMtr: order.requiredQuantityMtr.toDouble(),

sumOutKg: order.productionKg.toDouble(),
sumOutMtr: order.productionMtr.toDouble(),

balanceKg: order.balanceKg.toDouble(),
balanceMtr: order.balanceMtr.toDouble(),

flatTubeGusset: '',

// NEW FIELD MAPPINGS
articleNo: order.articleNo.toString(),
poNumber: order.poNumber,
customerName: order.customerName,

requiredKg: order.requiredQuantityKg.toDouble(),
requiredMtr: order.requiredQuantityMtr.toDouble(),

productionKg: order.productionKg.toDouble(),
productionMtr: order.productionMtr.toDouble(),

balanceKgInt: order.balanceKg.toDouble(),
balanceMtrInt: order.balanceMtr.toDouble(),

woNo: order.woNo,
status: order.status,
);
}
