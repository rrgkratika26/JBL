// import 'package:flutter/material.dart';
// import 'AllReportScreen.dart';
//
//
// const Color _tealDark = Color(0xFF00695C);
// const Color _tealMed = Color(0xFF00897B);
// const Color _tealLight = Color(0xFFE0F2F1);
//
// class RmdOutReportScreen extends StatelessWidget {
//   final String endpoint;
//   final Map<String, String> initialParams;
//
//   const RmdOutReportScreen({
//     super.key,
//     required this.endpoint,
//     required this.initialParams,
//   });
//
//   // OUT ke liye columns alag chahiye to yahan change karo
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
//       title: 'RMD OUT',
//       type: 'OUT',
//       endpoint: endpoint,
//       initialParams: initialParams,
//       columns: _cols,
//       gradient: const [_tealDark, _tealMed],
//       accent: _tealDark,
//       accentLight: _tealLight,
//     );
//   }
// }