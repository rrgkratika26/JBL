class JBLSaveRollModel {
  final int srNo;
  final String rollCode;
  final String barcode;
  final String supervisorName;
  final String operatorName;
  final String date;
  final String time;
  final String partyName;
  final String workOrderNo;
  final String contNo;
  final String loomNo;
  final String loomType;
  final String fabricType;
  final String fabricConstruction;
  final String color;
  final String fabricWidth;
  final String gsm;
  final String laminationType;
  final String cutType;
  final String specialIdentification;
  final String rollWeight;
  final String rollLength;
  final String avgWeight;
  final String tareWeight;
  final String grossWeight;
  final String fabricCode;
  final String department;
  final String hold;

  final String? requiredQuantityKg;
  final String? requiredQuantityMtr;
  final String? rollWeightKg;
  final String? rollLengthMtr;
  final String? avgWeightGm;
  final String? tareWeightKg;
  final String? grossWeightKg;
  final String? remark;
  final String? issueToDept;
  final String? inStock;
  final String? status;
  final String? location;

  const JBLSaveRollModel({
    this.srNo = 0,
    this.rollCode = '',
    this.barcode = '',
    this.supervisorName = '',
    this.operatorName = '',
    this.date = '',
    this.time = '',
    this.partyName = '',
    this.workOrderNo = '',
    this.contNo = '',
    this.loomNo = '',
    this.loomType = '',
    this.fabricType = '',
    this.fabricConstruction = '',
    this.color = '',
    this.fabricWidth = '',
    this.gsm = '',
    this.laminationType = '',
    this.cutType = '',
    this.specialIdentification = '',
    this.rollWeight = '',
    this.rollLength = '',
    this.avgWeight = '',
    this.tareWeight = '',
    this.grossWeight = '',
    this.fabricCode = '',
    this.department = '',
    this.hold = '',
    this.requiredQuantityKg,
    this.requiredQuantityMtr,
    this.rollWeightKg,
    this.rollLengthMtr,
    this.avgWeightGm,
    this.tareWeightKg,
    this.grossWeightKg,
    this.remark,
    this.issueToDept,
    this.inStock,
    this.status,
    this.location,
  });

  factory JBLSaveRollModel.fromJson(Map<String, dynamic> json) {
    // Handle API property names regardless of casing.
    final normalized = <String, dynamic>{
      for (final entry in json.entries)
        entry.key.toLowerCase(): entry.value,
    };

    String str(String key, [String fallback = '']) {
      final value = normalized[key.toLowerCase()];
      return value?.toString() ?? fallback;
    }

    return JBLSaveRollModel(
      srNo: int.tryParse(str('srNo', '0')) ?? 0,
      rollCode: str('rollcode'),
      barcode: str('barcode'),
      supervisorName: str('supervisorname'),
      operatorName: str('operatorname'),
      date: str('date'),
      time: str('time'),
      partyName: str('partyname'),
      workOrderNo: str('workorderno'),
      contNo: str('contno'),
      loomNo: str('loomno'),
      loomType: str('loomtype'),
      fabricType: str('fabrictype'),
      fabricConstruction: str('fabricconstruction'),
      color: str('color'),
      fabricWidth: str('fabricwidth'),
      gsm: str('fabricgsm'),
      laminationType: str('laminationtype'),
      cutType: str('cuttype'),
      specialIdentification: str('specialidentification'),
      rollWeight: str('rollweightkg'),
      rollLength: str('rolllengthmtr'),
      avgWeight: str('avgweightgm'),
      tareWeight: str('tareweightkg'),
      grossWeight: str('grossweightkg'),
      fabricCode: str('fabriccode'),
      department: str('department'),
      hold: str('hold'),
      requiredQuantityKg: str('requiredquantitykg'),
      requiredQuantityMtr: str('requiredquantitymtr'),
      rollWeightKg: str('rollweightkg'),
      rollLengthMtr: str('rolllengthmtr'),
      avgWeightGm: str('avgweightgm'),
      tareWeightKg: str('tareweightkg'),
      grossWeightKg: str('grossweightkg'),
      remark: str('remark'),
      issueToDept: str('issuetodept'),
      inStock: str('instock'),
      status: str('status'),
      location: str('location'),
    );
  }
}