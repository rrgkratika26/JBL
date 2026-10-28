
import 'package:flutter/foundation.dart';
import '../../services/getSupervisors/getSupervisors.dart';

class InStockWebController {
  List<String> operators = [];
  List<String> supervisors = [];
  List<String> locations = [];

  String? selectedOperator;
  String? selectedSupervisor;
  String? selectedLocation;

  /// Webbing OUT dropdown data
  Future<void> loadLookupData() async {
    debugPrint('Loading Webbing OUT dropdown data...');

    final data = await InStockService.fetchWebbingOutLookup();

    if (data != null) {
      operators = data.operators.toSet().toList();
      supervisors = data.supervisors.toSet().toList();
      locations = data.locations.toSet().toList();

      debugPrint('OUT OPERATORS: $operators');
      debugPrint('OUT SUPERVISORS: $supervisors');
      debugPrint('OUT LOCATIONS: $locations');
    } else {
      debugPrint('Webbing OUT dropdown API returned null');
    }
  }

  /// Webbing IN dropdown data
  Future<void> loadWebInitialData() async {
    debugPrint('Loading Webbing IN dropdown data...');

    final data = await InStockService.webbFetchDropdowns();

    if (data != null) {
      operators = data.operators.toSet().toList();
      supervisors = data.supervisors.toSet().toList();
      locations = data.locations.toSet().toList();

      debugPrint('OPERATORS: $operators');
      debugPrint('SUPERVISORS: $supervisors');
      debugPrint('LOCATIONS: $locations');
    } else {
      debugPrint('Webbing IN dropdown API returned null');
    }
  }

  bool isFormValid() {
    return selectedOperator != null &&
        selectedSupervisor != null &&
        selectedLocation != null;
  }
}
