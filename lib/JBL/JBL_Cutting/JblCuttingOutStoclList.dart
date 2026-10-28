import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Color/Colorclass.dart';
import '../../services/JBL_apis/jbl_api_bailing_reports.dart';

import 'CutOutformJbl.dart';
import 'ModelClass/cuttingOutStockJbl.dart';

class CutOutSavedListJbl extends StatefulWidget {
  final bool isNew; // initial tab: true = New barcode, false = Old barcode

  const CutOutSavedListJbl({super.key, this.isNew = false});

  @override
  State<CutOutSavedListJbl> createState() => _CutOutSavedListJblState();
}

class _CutOutSavedListJblState extends State<CutOutSavedListJbl> {
  final TextEditingController _searchController = TextEditingController();
  final List<CuttingOutstockJbl> _items = [];
  List<CuttingOutstockJbl> _filteredItems = [];

  late bool _isNew;
  String _searchText = '';
  String _status = '';
  bool _loading = false;
  Timer? _debounce;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _isNew = widget.isNew;
    _fetchData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── DATA ──

  Future<String> _getUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('unit') ?? '';
  }

  void _applyFilter(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchText = value.trim().toLowerCase();
        _refreshFilteredItems();
      });
    });
  }

  void _refreshFilteredItems() {
    final s = _searchText;
    if (s.isEmpty) {
      _filteredItems = List.from(_items);
      return;
    }
    _filteredItems = _items.where((i) {
      return i.srNo.toString().contains(s) ||
          i.rollCode.toString().contains(s) ||
          i.barcode.toLowerCase().contains(s) ||
          i.fabricCode.toLowerCase().contains(s);
    }).toList();
  }

  Future<void> _fetchData() async {
    final myRequest = ++_requestId;

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final unit = await _getUnit();
      final data = _isNew
          ? await JblApiService.fetchCuttingNewBarcodeList(
          plant: unit, department: 'CUTTING')
          : await JblApiService.fetchCuttingOldBarcodeList(
          plant: unit, department: 'CUTTING');

      if (!mounted || myRequest != _requestId) return;

      setState(() {
        _items
          ..clear()
          ..addAll(data);
        _refreshFilteredItems();
      });
    } catch (e) {
      if (mounted && myRequest == _requestId) {
        _setStatus("❌ Load error: $e");
      }
    }

    if (mounted && myRequest == _requestId) {
      setState(() => _loading = false);
    }
  }

  void _switchList(bool isNew) {
    if (_isNew == isNew) return;
    _searchController.clear();
    setState(() {
      _isNew = isNew;
      _items.clear();
      _filteredItems = [];
      _searchText = '';
    });
    _fetchData();
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _status = msg);
  }

  void _openForm(CuttingOutstockJbl r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CuttingOutStockFormJbl(production: r)),
    );
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.primary,
        iconTheme: const IconThemeData(color: C.bg),
        title: const Text(
          "Cutting OUT Stock",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: C.bg),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: Colors.white, size: 14),
                const SizedBox(width: 5),
                Text(
                  "${_filteredItems.length} / ${_items.length}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _toggleBar(),
          _searchBox(),
          if (_status.isNotEmpty) _statusBar(),
          Expanded(
            child: _loading && _items.isEmpty
                ? _initialLoader()
                : RefreshIndicator(
              onRefresh: _fetchData,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented toggle ──
  Widget _toggleBar() => Container(
    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      children: [
        Expanded(child: _toggleBtn("Old Barcode", false)),

        Expanded(child: _toggleBtn("New Barcode", true)),
      ],
    ),
  );

  Widget _toggleBtn(String label, bool isNew) {
    final active = _isNew == isNew;
    return GestureDetector(
      onTap: () => _switchList(isNew),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? C.actionOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : C.primary,
          ),
        ),
      ),
    );
  }

  Widget _searchBox() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
    child: TextField(
      controller: _searchController,
      onChanged: _applyFilter,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: "Search Sr No, Roll Code, Barcode or Fabric Code",
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: C.primary),
        suffixIcon: _searchText.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchText = '';
              _refreshFilteredItems();
            });
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.primary, width: 1.5),
        ),
      ),
    ),
  );

  Widget _initialLoader() => Center(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: C.appBar3),
          const SizedBox(height: 15),
          Text(
            "Fetching Out List...",
            style: TextStyle(color: C.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );

  Widget _buildList() {
    if (_filteredItems.isEmpty && !_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Center(
            child: Text("No data found",
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) => _card(_filteredItems[index]),
    );
  }

  // ── Simple card: limited data + Open button ──
  Widget _card(CuttingOutstockJbl r) {
    final isIn = r.inStock.toUpperCase() == "IN";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: barcode + stock chip
          Row(
            children: [
              Expanded(
                child: Text(
                  r.barcode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: C.success,
                  ),
                ),
              ),
              _chip(
                r.inStock.isEmpty ? "-" : r.inStock,
                isIn ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            r.fabricCode,
            style: TextStyle(fontSize: 12, color: C.textHigh),
          ),

          const SizedBox(height: 12),

          // Key stats
          Row(
            children: [
              _stat("Roll Code", r.rollCode.toString()),
              _stat("Weight", "${r.rollWeightKg} kg"),
              _stat("Length", "${r.rollLengthMtr} m"),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 8),

          // Footer: date + Open button
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "${r.date.split("T").first}  •  ${r.time}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openForm(r),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text("Open"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.actionOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );

  Widget _statusBar() => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(_status, style: const TextStyle(fontSize: 12)),
  );
}