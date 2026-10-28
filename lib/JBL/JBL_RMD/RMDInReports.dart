// import 'package:IMS/Color/Colorclass.dart';
// import 'package:flutter/material.dart';
//
// import 'AllReportScreen.dart';
//
//
// class RmdInReportScreen extends StatelessWidget {
//   final String endpoint;
//   final Map<String, String> initialParams;
//
//   const RmdInReportScreen({
//     super.key,
//     required this.endpoint,
//     required this.initialParams,
//   });
//
//   static const List<String> _cols = [
//     'rolL_CODE',
//     'barcode',
//     'fabriC_CODE',
//     'grosS_WEIGHT',
//     'neT_WEIGHT',
//     'rolL_LENGTH',
//     'avG_WEIGHT',
//     'operatoR_NAME',
//     'supervisoR_NAME',
//     'worK_ORDER_NO',
//     'requireD_QUANTITY',
//     'requiredqtymtr',
//     'tarE_WEIGHT',
//     'status',
//     'fabriC_WIDTH',
//     'fabriC_GSM',
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return RmdReportView(
//       title: 'RMD IN',
//       type: 'IN',
//       endpoint: endpoint,
//       initialParams: initialParams,
//       columns: _cols,
//       gradient: [C.primary, C.headerBlue],
//       accent: C.primary,
//       accentLight: C.primaryLight,
//     );
//   }
// }