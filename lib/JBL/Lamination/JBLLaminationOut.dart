import 'package:flutter/material.dart';
import 'LaminationReportscreen.dart';




class LaminationOutReportScreen extends StatelessWidget {
  final String title;
  final String endpoint;
  final Map<String, String> initialParams;

  const LaminationOutReportScreen({
    super.key,
    this.title = 'Lamination OUT Report',
    required this.endpoint,
    required this.initialParams,
  });

  @override
  Widget build(BuildContext context) {
    return LaminationReportView(
      title: title,
      type: 'OUT',
      initialParams: initialParams,
      fields: kLamReportFields, // OUT ke liye alag fields chahiye to yahan list do


    );
  }
}