import 'package:flutter/material.dart';

import '../../Color/Colorclass.dart';
import '../../services/JBL_apis/jbl_api_bailing_reports.dart';
import 'LoomFormENtry.dart';
import 'modelClass/FIBCmodel.dart';

enum ReportType { all, process, finish }

extension ReportTypeX on ReportType {
  String get label => switch (this) {
    ReportType.all => 'All',
    ReportType.process => 'Process',
    ReportType.finish => 'Finish',
  };

  IconData get icon => switch (this) {
    ReportType.all => Icons.layers_outlined,
    ReportType.process => Icons.autorenew_rounded,
    ReportType.finish => Icons.check_circle_outline,
  };

  /// API ko jo value bhejni hai
  String get apiValue => name; // 'all' | 'process' | 'finish'
}

class LOOMList extends StatefulWidget {
  const LOOMList({super.key});

  @override
  State<LOOMList> createState() => _LOOMListState();
}

class _LOOMListState extends State<LOOMList> {
  static const _pageBg = Color(0xFFF4F6F9);
  static const _textHigh = Color(0xFF1F2937);
  static const _textLow = Color(0xFF6B7280);
  static const _green = Color(0xFF16A34A);
  static const _orange = Color(0xFFEA580C);
  static const _red = Color(0xFFDC2626);

  final _searchCtrl = TextEditingController();
  List<ProductionModel> list = [];
  bool isLoading = true;
  String? error;
  ReportType selectedType = ReportType.all;
  String search = '';
  int _reqId = 0; // fast switch pe purani response ignore karne ke liye

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final myReq = ++_reqId;
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await JblApiService.getProductionReport(
        type: selectedType.apiValue,
      );
      if (!mounted || myReq != _reqId) return;
      setState(() {
        list = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ UI ERROR: $e");
      if (!mounted || myReq != _reqId) return;
      setState(() {
        error = "Not loaded Data. Please try again later.";
        isLoading = false;
      });
    }
  }

  List<ProductionModel> get filtered {
    if (search.trim().isEmpty) return list;
    final q = search.trim().toLowerCase();
    return list.where((e) {
      return e.orderNo.toString().toLowerCase().contains(q) ||
          e.partyName.toLowerCase().contains(q) ||
          e.fabricCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filtered;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: C.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: C.bg),
        title: const Text(
          "Production Report",
          style: TextStyle(color: C.bg, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: C.bg),
            onPressed: loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (!isLoading && error == null) _buildCountRow(items.length),
          Expanded(child: _buildBody(items)),
        ],
      ),
    );
  }

  // ---------- Filter bar (search + chips) ----------
  Widget _buildFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => search = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: "Order / Party / Fabric search",
              hintStyle: const TextStyle(fontSize: 14, color: _textLow),
              prefixIcon: const Icon(Icons.search, size: 20, color: _textLow),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => search = '');
                },
              ),
              isDense: true,
              filled: true,
              fillColor: _pageBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: C.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ReportType.values.map((t) {
              final selected = t == selectedType;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(
                    t.icon,
                    size: 16,
                    color: selected ? Colors.white : _textLow,
                  ),
                  label: Text(t.label),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: C.primary,
                  backgroundColor: _pageBg,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _textHigh,
                  ),
                  onSelected: (_) {
                    if (selected) return;
                    setState(() => selectedType = t);
                    loadData();
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountRow(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$count ${count == 1 ? 'order' : 'orders'}",
          style: const TextStyle(
            fontSize: 12,
            color: _textLow,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------- Body states ----------
  Widget _buildBody(List<ProductionModel> items) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: C.appBar3));
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52, color: _red),
              const SizedBox(height: 10),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: C.primary),
                onPressed: loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 8),
            Center(
              child: Text("No Data Found", style: TextStyle(color: _textLow)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  // ---------- Card (flat + left accent strip) ----------
  Widget _buildCard(ProductionModel item) {
    final req = item.actualRequiredKg.toDouble();
    final prod = item.sumOutKg.toDouble();
    final progress = req > 0 ? (prod / req).clamp(0.0, 1.0) : 0.0;
    final isDone = item.balanceKg <= 0;
    final accent = isDone ? _green : _orange;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => _openForm(item),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Order #${item.orderNo}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textHigh,
                                ),
                              ),
                            ),
                            _statusChip(isDone, accent),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.partyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textHigh,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _tag(Icons.texture, item.fabricCode),
                            _tag(Icons.view_in_ar_outlined,
                                item.flatTubeGusset.toString()),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Progress
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  backgroundColor: Colors.grey.shade200,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${(progress * 100).toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Stats
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _pageBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                _stat("REQ", item.actualRequiredKg,
                                    item.actualRequiredMtr, _textHigh),
                                _vDivider(),
                                _stat(
                                  "PROD",
                                  item.sumOutKg,
                                  item.sumOutMtr,
                                  item.sumOutKg < 0 ? _red : _green,
                                ),
                                _vDivider(),
                                _stat(
                                  "BAL",
                                  item.balanceKg,
                                  item.balanceMtr,
                                  item.balanceKg < 0 ? _red : _orange,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Open
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: C.primaryblue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _openForm(item),
                            label: const Text(
                              "Open",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            iconAlignment: IconAlignment.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(ProductionModel item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoomForm(production: item)),
    );
    // form se wapas aane pe list refresh
    if (mounted) loadData();
  }

  Widget _statusChip(bool isDone, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.autorenew_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isDone ? "FINISH" : "PROCESS",
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _textLow),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: _textLow)),
        ],
      ),
    );
  }

  Widget _vDivider() => VerticalDivider(
    width: 1,
    thickness: 1,
    color: Colors.grey.shade300,
  );

  Widget _stat(String title, num kg, num mtr, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              color: _textLow,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${kg.toStringAsFixed(2)} kg",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${mtr.toStringAsFixed(2)} mtr",
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}