import 'package:IMS/Color/Colorclass.dart';
import 'package:flutter/material.dart';

import 'LaminationReportscreen.dart';


class LaminationInReportScreen extends StatelessWidget {
  final String title;
  final String endpoint;
  final Map<String, String> initialParams;

  const LaminationInReportScreen({
    super.key,
    this.title = 'Lamination IN Report',
    required this.endpoint,
    required this.initialParams,
  });

  @override
  Widget build(BuildContext context) {
    return LaminationReportView(
      title: title,
      type: 'IN',
      initialParams: initialParams,
      fields: kLamReportFields, // IN ke liye alag fields chahiye to yahan list do

    );
  }
}