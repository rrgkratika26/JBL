import 'package:IMS/services/JBL_apis/jbl_api_bailing_reports.dart';
import 'package:IMS/Color/Colorclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// IN aur OUT dono ke liye default fields (same API response)
const List<String> kLamReportFields = [
  'rolL_CODE',
  'barcode',
  'looM_TYPE',
  'looM_NO',
  'fabriC_CODE',
  'grosS_WEIGHT',
  'neT_WEIGHT',
  'rolL_LENGTH',
  'avG_WEIGHT',
  'operatoR_NAME',
  'supervisoR_NAME',
  'status',
  'partyname',
  'worK_ORDER_NO',
  'conT_NO',
  'requireD_QUANTITY',
  'requireD_QUANTITY_MTR',
];

// ── Column config: label, width, numeric ─────────────────────────────────────
class _ColDef {
  final String label;
  final double width;
  final bool numeric;
  const _ColDef(this.label, this.width, {this.numeric = false});
}

const Map<String, _ColDef> _colDefs = {
  'rolL_CODE': _ColDef('Roll Code', 100),
  'barcode': _ColDef('Barcode', 110),
  'looM_TYPE': _ColDef('Loom Type', 90),
  'looM_NO': _ColDef('Loom No', 80),
  'fabriC_CODE': _ColDef('Fabric Code', 170),
  'grosS_WEIGHT': _ColDef('Gross Wt', 90, numeric: true),
  'neT_WEIGHT': _ColDef('Net Wt', 80, numeric: true),
  'rolL_LENGTH': _ColDef('Length', 80, numeric: true),
  'avG_WEIGHT': _ColDef('Avg Wt', 80, numeric: true),
  'operatoR_NAME': _ColDef('Operator', 110),
  'supervisoR_NAME': _ColDef('Supervisor', 110),
  'status': _ColDef('Status', 100),
  'partyname': _ColDef('Party', 150),
  'worK_ORDER_NO': _ColDef('Work Order', 120),
  'conT_NO': _ColDef('Cont No', 100),
  'requireD_QUANTITY': _ColDef('Req Qty', 90, numeric: true),
  'requireD_QUANTITY_MTR': _ColDef('Req Qty (m)', 110, numeric: true),
};

// unknown key aaye to auto label + default width
_ColDef _def(String key) => _colDefs[key] ?? _ColDef(_autoLabel(key), 110);

String _autoLabel(String key) {
  final s = key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .toLowerCase();
  return s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

const double _serialW = 48;
const double _rowH = 46;
const double _headH = 44;

// ─────────────────────────────────────────────────────────────────────────────
class LaminationReportView extends StatefulWidget {
  final String title;
  final String type; // 'IN' or 'OUT'
  final Map<String, String> initialParams;
  final List<String> fields;

  const LaminationReportView({
    super.key,
    required this.title,
    required this.type,
    required this.initialParams,
    required this.fields,
  });

  @override
  State<LaminationReportView> createState() => _LaminationReportViewState();
}

class _LaminationReportViewState extends State<LaminationReportView> {
  final JblApiService _api = JblApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _data = [];
  bool _loading = true;
  String _search = '';

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _toDate = DateTime.now();

  late Map<String, String> _baseParams;

  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _baseParams = Map<String, String>.from(widget.initialParams);
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _show(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  String get _rangeText => _fmt(_fromDate) == _fmt(_toDate)
      ? _show(_fromDate)
      : '${_show(_fromDate)} – ${_show(_toDate)}';

  String _num(dynamic v) {
    final d = double.tryParse('$v');
    if (d == null) return '${v ?? '—'}';
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

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _api.getLaminationReports(
        type: widget.type,
        fromDate: _fmt(_fromDate),
        toDate: _fmt(_toDate),
        plant: _baseParams['plant'] ?? '',
      );
      if (!mounted) return;
      setState(() => _data = res);
    } catch (e) {
      debugPrint('API ERROR [${widget.type}]: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.lightImpact();
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: C.primary,
            onPrimary: Colors.white,
            surface: C.bg,
            onSurface: C.textHigh,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
      });
      _fetch();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: C.primary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: C.bg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: C.bg,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: C.bg, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              _fetch();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Search + date chip ─────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: C.bg,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: C.brand50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.borderLight),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(
                  fontSize: 13,
                  color: C.textHigh,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search records…',
                  hintStyle: const TextStyle(color: C.textLow, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: C.textMid,
                    size: 18,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setState(() => _search = '');
                            _searchCtrl.clear();
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: C.textMid,
                            size: 16,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),

              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 15, color: C.bg),
                  const SizedBox(width: 6),
                  Text(
                    _rangeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: C.primary,
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
        child: CircularProgressIndicator(strokeWidth: 3, color: C.primary),
      );
    }

    final rows = _filtered;

    if (rows.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 30, color: C.textHigh),
              const SizedBox(height: 16),
              Text(
                _search.isNotEmpty
                    ? 'No results for "$_search"'
                    : 'No Data Found',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: C.textHigh,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _search.isNotEmpty
                    ? 'Try a different keyword'
                    : 'No ${widget.type} records for $_rangeText',
                style: const TextStyle(fontSize: 12, color: C.textMid),
              ),
            ],
          ),
        ),
      );
    }

    final allCols = (rows.first as Map<String, dynamic>).keys.toList();
    final cols = widget.fields.where(allCols.contains).toList();

    return Column(
      children: [
        _buildSummary(rows, allCols),
        Expanded(child: _buildTable(cols, rows)),
      ],
    );
  }

  // ── Summary chips ──────────────────────────────────────────────────────────
  Widget _buildSummary(List<dynamic> rows, List<String> allCols) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _chip('Rolls: ${rows.length}'),
          if (allCols.contains('neT_WEIGHT'))
            _chip('Net Wt: ${_sum(rows, 'neT_WEIGHT').toStringAsFixed(2)} kg'),
          if (allCols.contains('rolL_LENGTH'))
            _chip('Len: ${_sum(rows, 'rolL_LENGTH').toStringAsFixed(2)} m'),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
    decoration: BoxDecoration(
      color: C.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: C.borderLight),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: C.textHigh,
      ),
    ),
  );

  // ── Table (sticky header + lazy rows) ──────────────────────────────────────
  Widget _buildTable(List<String> cols, List<dynamic> rows) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(14, 0, 14, 14 + bottomInset),
      decoration: BoxDecoration(
        color: C.primary,

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
          // tablet / landscape me columns stretch ho jaate hain
          final colsW = cols.fold<double>(0, (s, c) => s + _def(c).width);
          final avail = box.maxWidth - _serialW;
          final stretch = colsW > 0 ? (avail / colsW).clamp(1.0, 3.0) : 1.0;
          double w(String c) => _def(c).width * stretch;
          final totalW = _serialW + cols.fold<double>(0, (s, c) => s + w(c));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalW,
              child: Column(
                children: [
                  // sticky header
                  Container(
                    height: _headH,

                    child: Row(
                      children: [
                        const _HeadCell(
                          label: '#',
                          width: _serialW,
                          center: true,
                        ),
                        ...cols.map(
                          (c) => _HeadCell(
                            label: _def(c).label,
                            width: w(c),
                            right: _def(c).numeric,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // lazy rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemExtent: _rowH,
                      padding: EdgeInsets.zero,
                      itemBuilder: (_, i) {
                        final row = rows[i] as Map<String, dynamic>;
                        return _DataRow(
                          index: i,
                          cols: cols,
                          row: row,
                          widthOf: w,
                          highlight: _search,
                          accent: C.primary,
                          fmtNum: _num,
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

  // ── Row detail sheet ───────────────────────────────────────────────────────
  void _showDetail(Map<String, dynamic> row) {
    HapticFeedback.selectionClick();
    final keys = widget.fields.where(row.containsKey).toList();
    final title = '${row['rolL_CODE'] ?? row['barcode'] ?? 'Details'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: C.bg,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, sc) => Column(
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
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
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
                  vertical: 6,
                ),
                itemCount: keys.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: C.divider),
                itemBuilder: (_, i) {
                  final k = keys[i];
                  final v = row[k];
                  final def = _def(k);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            def.label,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: C.textMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            v == null || '$v'.isEmpty
                                ? '—'
                                : (def.numeric ? _num(v) : '$v'),
                            style: const TextStyle(
                              fontSize: 13,
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

  const _HeadCell({
    required this.label,
    required this.width,
    this.right = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    alignment: center
        ? Alignment.center
        : (right ? Alignment.centerRight : Alignment.centerLeft),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
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
  final double Function(String) widthOf;
  final String highlight;
  final Color accent;
  final String Function(dynamic) fmtNum;
  final VoidCallback onTap;

  const _DataRow({
    required this.index,
    required this.cols,
    required this.row,
    required this.widthOf,
    required this.highlight,
    required this.accent,
    required this.fmtNum,
    required this.onTap,
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
                width: _serialW,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: C.textLow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ...cols.map((c) {
                final def = _def(c);
                final raw = row[c];
                final text = (raw == null || '$raw'.trim().isEmpty)
                    ? '—'
                    : (def.numeric ? fmtNum(raw) : '$raw');
                return _Cell(
                  width: widthOf(c),
                  value: text,
                  right: def.numeric,
                  isStatus: c == 'status',
                  highlight: highlight,
                  accent: accent,
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
  final Color accent;

  const _Cell({
    required this.width,
    required this.value,
    required this.right,
    required this.isStatus,
    required this.highlight,
    required this.accent,
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
    return accent;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (isStatus && value != '—') {
      final col = _statusColor();
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: col,
          ),
        ),
      );
    } else if (highlight.isNotEmpty &&
        value.toLowerCase().contains(highlight.toLowerCase())) {
      child = _HighlightText(text: value, query: highlight, accent: accent);
    } else {
      child = Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 12.5,
          color: value == '—' ? C.textLow : C.textHigh,
          fontWeight: right ? FontWeight.w700 : FontWeight.w500,
        ),
      );
    }

    return Container(
      width: width,
      alignment: (right && !isStatus)
          ? Alignment.centerRight
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: child,
    );
  }
}

// ── Search highlight ─────────────────────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final Color accent;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0, idx;

    const normal = TextStyle(
      fontSize: 12.5,
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
            fontSize: 12.5,
            color: accent,
            fontWeight: FontWeight.w800,
            backgroundColor: accent.withOpacity(0.14),
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
