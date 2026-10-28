import 'package:IMS/services/JBL_apis/jbl_api_bailing_reports.dart';
import 'package:IMS/Color/Colorclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Column config: label, base width, numeric ────────────────────────────────
class _ColDef {
  final String label;
  final double width;
  final bool numeric;
  const _ColDef(this.label, this.width, {this.numeric = false});
}

const Map<String, _ColDef> _colDefs = {
  'rolL_CODE': _ColDef('Roll Code', 80),
  'barcode': _ColDef('Barcode', 90),
  'looM_TYPE': _ColDef('Loom Type', 90),
  'fabriC_CODE': _ColDef('Fabric Code', 170),
  'grosS_WEIGHT': _ColDef('Gross Wt', 90, numeric: true),
  'neT_WEIGHT': _ColDef('Net Wt', 70, numeric: true),
  'rolL_LENGTH': _ColDef('Length', 70, numeric: true),
  'avG_WEIGHT': _ColDef('Avg Wt', 70, numeric: true),
  'operatoR_NAME': _ColDef('Operator', 90),
  'supervisoR_NAME': _ColDef('Supervisor', 90),
  'worK_ORDER_NO': _ColDef('Work Order', 120),
  'requireD_QUANTITY': _ColDef('Req Qty', 70, numeric: true),
  'requiredqtymtr': _ColDef('Req Qty (m)', 80, numeric: true),
  'tarE_WEIGHT': _ColDef('Tare Wt', 95, numeric: true),
  'status': _ColDef('Status', 105),
  'fabriC_WIDTH': _ColDef('Width', 60, numeric: true),
  'fabriC_GSM': _ColDef('GSM', 70, numeric: true),
};

// ── Responsive dimensions ────────────────────────────────────────────────────
// Base design = 400dp wide phone. scale 0.9x → 1.3x.
class _Dim {
  final double scale;
  final double stretch; // extra column stretch on wide screens
  const _Dim(this.scale, [this.stretch = 1]);

  double f(double v) => v * scale; // fonts / spacing
  double colW(_ColDef c) => c.width * scale * stretch;
  double get serialW => 48 * scale;
  double get rowH => 46 * scale;
  double get headH => 44 * scale;

  _Dim withStretch(double s) => _Dim(scale, s);

  static _Dim of(double width) => _Dim((width / 400).clamp(0.9, 1.3));
}

// ─────────────────────────────────────────────────────────────────────────────
class DynamicReportScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  final Map<String, String> initialParams;

  const DynamicReportScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.initialParams,
  });

  @override
  State<DynamicReportScreen> createState() => _DynamicReportScreenState();
}

class _DynamicReportScreenState extends State<DynamicReportScreen> {
  final JblApiService _api = JblApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _data = [];
  bool _loading = true;
  String _search = '';

  late Map<String, String> _baseParams;
  late String _type;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isRangeFiltered = false;

  // set in build() from MediaQuery
  _Dim _d = const _Dim(1);
  double _hPad = 14;
  double _maxContentW = double.infinity;

  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _baseParams = Map<String, String>.from(widget.initialParams);
    _type = (_baseParams['type'] ?? 'IN').toUpperCase();
    _fetchReport();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _num(dynamic v) {
    final d = double.tryParse(v.toString());
    if (d == null) return v.toString();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(2);
  }

  double _sum(List<dynamic> rows, String key) => rows.fold<double>(
    0,
    (s, r) => s + (double.tryParse('${(r as Map)[key]}') ?? 0),
  );

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((row) {
      try {
        return (row as Map).values.join(' ').toLowerCase().contains(q);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> _fetchReport() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final params = Map<String, String>.from(_baseParams);
    params['type'] = _type;
    params['fromDate'] = _fmt(_startDate);
    params['toDate'] = _fmt(_endDate);

    try {
      final result = await _api.getDynamicReport(
        endpoint: widget.endpoint,
        params: params,
      );
      if (!mounted) return;
      setState(() => _data = result);
    } catch (e) {
      debugPrint('API ERROR [$_type]: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      saveText: 'APPLY',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: C.primary,
            onPrimary: Colors.white,
            surface: C.bg,
            onSurface: C.textHigh,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isRangeFiltered = true;
      });
      _fetchReport();
    }
  }

  void _resetToToday() {
    HapticFeedback.lightImpact();
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
      _isRangeFiltered = false;
    });
    _fetchReport();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;

    _d = _Dim.of(w);
    _hPad = w >= 900 ? 24 : (w >= 600 ? 18 : 14);
    _maxContentW = 1400;

    return MediaQuery(
      // text scale clamp: system font bada ho to bhi rows ka layout na toote
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2)),
      child: Scaffold(
        backgroundColor: C.pageBg,
        appBar: _buildAppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxContentW),
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: C.primary,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: _d.f(20), color: C.bg),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: _d.f(22),
          fontWeight: FontWeight.w800,
          color: C.bg,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Select date range',
          icon: Icon(Icons.calendar_today, size: _d.f(22), color: C.bg),
          onPressed: _pickDateRange,
        ),
        IconButton(
          tooltip: _isRangeFiltered ? 'Reset to Today' : 'Refresh',
          icon: Icon(Icons.refresh_rounded, color: C.textMid, size: _d.f(21)),
          onPressed: _resetToToday,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: C.borderLight),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final count = _filtered.length;
    final h = _d.f(42);
    final badgeW = _d.f(46);

    return Container(
      color: C.bg,
      padding: EdgeInsets.fromLTRB(_hPad, 10, _hPad, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: C.brand50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.borderLight),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(
                  fontSize: _d.f(13),
                  color: C.textHigh,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search records…',
                  hintStyle: TextStyle(color: C.textLow, fontSize: _d.f(13)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: C.textMid,
                    size: _d.f(18),
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setState(() => _search = '');
                            _searchCtrl.clear();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: C.textMid,
                            size: _d.f(16),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: (h - _d.f(18)) / 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _loading
                ? SizedBox(
                    key: const ValueKey('spin'),
                    width: badgeW,
                    height: h,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: C.appBar3,
                        ),
                      ),
                    ),
                  )
                : Container(
                    key: ValueKey('$_type-$count'),
                    width: badgeW,
                    height: h,
                    decoration: BoxDecoration(
                      color: C.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.primary.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: _d.f(14),
                            fontWeight: FontWeight.w900,
                            color: C.primary,
                          ),
                        ),
                        Text(
                          'rows',
                          style: TextStyle(
                            fontSize: _d.f(8),
                            fontWeight: FontWeight.w600,
                            color: C.primary.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3, color: C.appBar3),
            const SizedBox(height: 14),
            Text(
              'Loading $_type data…',
              style: TextStyle(
                color: C.textMid,
                fontSize: _d.f(13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final rows = _filtered;
    if (rows.isEmpty) return _buildEmpty();

    final allCols = (rows.first as Map<String, dynamic>).keys.toList();
    final cols = _colDefs.keys.where(allCols.contains).toList();

    return Column(
      children: [
        _buildSummary(rows, allCols),
        Expanded(child: _buildTable(cols, rows)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _d.f(68),
              height: _d.f(68),
              decoration: BoxDecoration(
                color: C.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: C.primary.withOpacity(0.18)),
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: _d.f(30),
                color: C.primary.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _search.isNotEmpty
                  ? 'No results for "$_search"'
                  : 'No Data Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _d.f(15),
                fontWeight: FontWeight.w700,
                color: C.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _search.isNotEmpty
                  ? 'Try a different keyword'
                  : 'No $_type records for the selected date range',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: _d.f(12), color: C.textMid),
            ),
            if (_isRangeFiltered) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _resetToToday,
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Reset to Today'),
                style: TextButton.styleFrom(foregroundColor: C.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Summary strip ──────────────────────────────────────────────────────────
  Widget _buildSummary(List<dynamic> rows, List<String> allCols) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, 6, _hPad, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (allCols.contains('neT_WEIGHT'))
              _chip(
                'Roll wt(Kg): ${_sum(rows, 'neT_WEIGHT').toStringAsFixed(2)}',
              ),
            if (allCols.contains('rolL_LENGTH'))
              _chip(
                'Roll Mtr: ${_sum(rows, 'rolL_LENGTH').toStringAsFixed(2)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: _d.f(10), vertical: _d.f(6)),
    decoration: BoxDecoration(
      color: C.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: C.borderLight),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: _d.f(12),
        fontWeight: FontWeight.w700,
        color: C.textHigh,
      ),
    ),
  );

  // ── Table (sticky header + lazy rows, auto-stretch on wide screens) ────────
  Widget _buildTable(List<String> cols, List<dynamic> rows) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(_hPad, 0, _hPad, 14 + bottomInset),
      decoration: BoxDecoration(
        color: C.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.borderLight),
        boxShadow: [
          BoxShadow(
            color: C.brand300,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          final base = _d;
          final colsBase = cols.fold<double>(
            0,
            (s, c) => s + _colDefs[c]!.width * base.scale,
          );
          final availForCols = box.maxWidth - base.serialW;

          // screen badi hai to columns ko proportionally stretch karo
          final stretch = colsBase > 0
              ? (availForCols / colsBase).clamp(1.0, 3.0)
              : 1.0;
          final d = base.withStretch(stretch.toDouble());

          final totalW =
              d.serialW +
              cols.fold<double>(0, (s, c) => s + d.colW(_colDefs[c]!));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalW,
              child: Column(
                children: [
                  Container(
                    height: d.headH,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [C.primary, C.headerBlue],
                      ),
                    ),
                    child: Row(
                      children: [
                        _HeadCell(
                          label: '#',
                          width: d.serialW,
                          center: true,
                          d: d,
                        ),
                        ...cols.map(
                          (c) => _HeadCell(
                            label: _colDefs[c]!.label,
                            width: d.colW(_colDefs[c]!),
                            right: _colDefs[c]!.numeric,
                            d: d,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemExtent: d.rowH,
                      padding: EdgeInsets.zero,
                      itemBuilder: (_, i) {
                        final row = rows[i] as Map<String, dynamic>;
                        return _DataRow(
                          index: i,
                          cols: cols,
                          row: row,
                          highlight: _search,
                          fmtNum: _num,
                          d: d,
                          onTap: () => _showDetail(row),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Row detail bottom sheet ────────────────────────────────────────────────
  void _showDetail(Map<String, dynamic> row) {
    HapticFeedback.selectionClick();
    final title = (row['rolL_CODE'] ?? row['barcode'] ?? 'Details').toString();
    final mq = MediaQuery.of(context);
    final landscape = mq.orientation == Orientation.landscape;
    final d = _d;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: C.bg,
      // tablet / desktop pe sheet center me 600 wide
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: landscape ? 0.9 : 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, sc) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: C.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: C.primary,
                    size: d.f(20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: d.f(16),
                        fontWeight: FontWeight.w800,
                        color: C.textHigh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: C.divider),
            Expanded(
              child: ListView.separated(
                controller: sc,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                itemCount: row.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: C.divider),
                itemBuilder: (_, i) {
                  final k = row.keys.elementAt(i);
                  final def = _colDefs[k];
                  final v = row[k];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            def?.label ?? k,
                            style: TextStyle(
                              fontSize: d.f(12.5),
                              color: C.textMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            v == null
                                ? '—'
                                : (def?.numeric ?? false)
                                ? _num(v)
                                : v.toString(),
                            style: TextStyle(
                              fontSize: d.f(13),
                              color: C.textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header cell ──────────────────────────────────────────────────────────────
class _HeadCell extends StatelessWidget {
  final String label;
  final double width;
  final bool right;
  final bool center;
  final _Dim d;

  const _HeadCell({
    required this.label,
    required this.width,
    required this.d,
    this.right = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    alignment: center
        ? Alignment.center
        : (right ? Alignment.centerRight : Alignment.centerLeft),
    padding: EdgeInsets.symmetric(horizontal: d.f(10)),
    child: Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: d.f(11),
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.4,
      ),
    ),
  );
}

// ── Data row ─────────────────────────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final int index;
  final List<String> cols;
  final Map<String, dynamic> row;
  final String highlight;
  final String Function(dynamic) fmtNum;
  final VoidCallback onTap;
  final _Dim d;

  const _DataRow({
    required this.index,
    required this.cols,
    required this.row,
    required this.highlight,
    required this.fmtNum,
    required this.onTap,
    required this.d,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: index.isEven ? C.cardBg : C.brand50,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: C.divider)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: d.serialW,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: d.f(11.5),
                      color: C.textLow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ...cols.map((c) {
                final def = _colDefs[c]!;
                final raw = row[c];
                final text = raw == null
                    ? '—'
                    : (def.numeric ? fmtNum(raw) : raw.toString());
                return _Cell(
                  width: d.colW(def),
                  value: text,
                  right: def.numeric,
                  isStatus: c == 'status',
                  highlight: highlight,
                  d: d,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cell ─────────────────────────────────────────────────────────────────────
class _Cell extends StatelessWidget {
  final double width;
  final String value;
  final bool right;
  final bool isStatus;
  final String highlight;
  final _Dim d;

  const _Cell({
    required this.width,
    required this.value,
    required this.right,
    required this.isStatus,
    required this.highlight,
    required this.d,
  });

  Color _statusColor() {
    final v = value.toLowerCase();
    if (v.contains('complete') ||
        v.contains('done') ||
        v.contains('approved')) {
      return const Color(0xFF2E7D32);
    }
    if (v.contains('pending') || v.contains('hold')) {
      return const Color(0xFFEF6C00);
    }
    if (v.contains('reject') || v.contains('cancel')) {
      return const Color(0xFFC62828);
    }
    return C.primary;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (isStatus && value != '—') {
      final col = _statusColor();
      child = Container(
        padding: EdgeInsets.symmetric(horizontal: d.f(8), vertical: d.f(3)),
        decoration: BoxDecoration(
          color: col.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: col.withOpacity(0.35)),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: d.f(11),
            fontWeight: FontWeight.w800,
            color: col,
          ),
        ),
      );
    } else if (highlight.isNotEmpty &&
        value.toLowerCase().contains(highlight.toLowerCase())) {
      child = _HighlightText(
        text: value,
        query: highlight,
        fontSize: d.f(12.5),
      );
    } else {
      child = Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: d.f(12.5),
          color: value == '—' ? C.textLow : C.textHigh,
          fontWeight: right ? FontWeight.w700 : FontWeight.w500,
        ),
      );
    }

    return Container(
      width: width,
      alignment: isStatus
          ? Alignment.centerLeft
          : (right ? Alignment.centerRight : Alignment.centerLeft),
      padding: EdgeInsets.symmetric(horizontal: d.f(10)),
      child: child,
    );
  }
}

// ── Search highlight ─────────────────────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final double fontSize;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;

    final normal = TextStyle(
      fontSize: fontSize,
      color: C.textHigh,
      fontWeight: FontWeight.w500,
    );

    while ((idx = lower.indexOf(q, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: normal));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + q.length),
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            backgroundColor: C.primary,
          ),
        ),
      );
      start = idx + q.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: normal));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(children: spans),
    );
  }
}
