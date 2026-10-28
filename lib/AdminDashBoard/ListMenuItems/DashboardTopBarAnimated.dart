// import 'dart:async';
// import 'package:flutter/material.dart';
//
// import '../../Color/Colorclass.dart';
// import '../../InquiryScreen/Marketing/MarketingModel.dart';
// import '../../services/DashboardApiServices.dart';
// import '../Dashboard Summary.dart';
// import 'dashBoardMapper.dart';
//
// class MetricItem {
//   final String label;
//   final num value;
//
//   const MetricItem(this.label, this.value);
// }
//
// class DeptCountItem {
//   final String title;
//   final IconData icon;
//   final List<MetricItem> metrics; // 1..n values per dept
//   final Color color;
//
//   const DeptCountItem({
//     required this.title,
//     required this.icon,
//     required this.metrics,
//     required this.color,
//   });
// }
//
// // ─────────────────────────────────────────────
// //  TOP BAR WIDGET
// // ─────────────────────────────────────────────
// class DashboardTopBarAnimated extends StatefulWidget {
//   final String unit;
//   final String fromDate;
//   final String toDate;
//
//   final VoidCallback? onMenuTap;
//   final VoidCallback? onProfileTap;
//
//   const DashboardTopBarAnimated({
//     super.key,
//     required this.unit,
//     required this.fromDate,
//     required this.toDate,
//     this.onMenuTap,
//     this.onProfileTap,
//   });
//
//   @override
//   State<DashboardTopBarAnimated> createState() =>
//       _DashboardTopBarAnimatedState();
// }
//
// class _DashboardTopBarAnimatedState extends State<DashboardTopBarAnimated>
//     with TickerProviderStateMixin {
//   late final AnimationController _entranceCtrl;
//   late final Animation<Offset> _slideAnim;
//   late final Animation<double> _fadeAnim;
//   bool _isPaused = false;
//   int currentIndex = 0;
//   DashboardSummary? dashboardSummary;
//   List<DeptCountItem> deptCounts = [];
//   bool isLoading = true;
//
//   final ScrollController _scrollCtrl = ScrollController();
//   Timer? _tickerTimer;
//   Timer? _refreshTimer;
//   double _scrollPos = 0;
//   static const double _scrollSpeed = 0.6;
//   static const Duration _tickInterval = Duration(milliseconds: 16);
//
//   @override
//   void initState() {
//     super.initState();
//
//     _entranceCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//
//     _slideAnim = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
//         .animate(
//       CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
//     );
//
//     _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn);
//
//     _entranceCtrl.forward();
//
//     loadDashboard();
//
//     _refreshTimer = Timer.periodic(
//       const Duration(seconds: 30),
//           (_) => loadDashboard(),
//     );
//   }
//
//   void _startTicker() {
//     _tickerTimer = Timer.periodic(_tickInterval, (_) {
//       if (_isPaused) return;
//       if (!_scrollCtrl.hasClients) return;
//
//       final maxExtent = _scrollCtrl.position.maxScrollExtent;
//       if (maxExtent <= 0) return;
//
//       _scrollPos += _scrollSpeed;
//
//       if (_scrollPos >= maxExtent / 2) {
//         _scrollPos = 0;
//       }
//
//       _scrollCtrl.jumpTo(
//         _scrollPos.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
//       );
//     });
//   }
//
//   @override
//   void dispose() {
//     _tickerTimer?.cancel();
//     _refreshTimer?.cancel();
//     _scrollCtrl.dispose();
//     _entranceCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final mq = MediaQuery.of(context);
//     final isMobile = mq.size.width < 600;
//
//     return SlideTransition(
//       position: _slideAnim,
//       child: FadeTransition(
//         opacity: _fadeAnim,
//         child: SizedBox(
//           width: double.infinity,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               isLoading
//                   ? const SizedBox(
//                 height: 90,
//                 child: Center(
//                   child: CircularProgressIndicator(strokeWidth: 2.4),
//                 ),
//               )
//                   : _tickerRow(isMobile),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _tickerRow(bool isMobile) {
//     if (deptCounts.isEmpty) {
//       return SizedBox(
//         height: 96,
//         child: Center(
//           child: Text(
//             "No Data",
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       );
//     }
//
//     final doubled = [...deptCounts, ...deptCounts];
//
//     return SizedBox(
//       height: isMobile ? 132 : 156,
//       child: ListView.builder(
//         controller: _scrollCtrl,
//         scrollDirection: Axis.horizontal,
//         physics: const NeverScrollableScrollPhysics(),
//         padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24),
//         itemCount: doubled.length,
//         itemBuilder: (_, index) {
//           return Padding(
//             padding: const EdgeInsets.only(right: 15),
//             child: Listener(
//               onPointerDown: (_) => setState(() => _isPaused = true),
//               onPointerUp: (_) => setState(() => _isPaused = false),
//               onPointerCancel: (_) => setState(() => _isPaused = false),
//               child: _tickerCard(doubled[index], isMobile),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // ── Redesigned card: cleaner hierarchy, bigger value text ──
//   Widget _tickerCard(DeptCountItem item, bool isMobile) {
//     final bool active = deptCounts[currentIndex].title == item.title;
//     final int metricCount = item.metrics.length;
//     final bool useGrid = metricCount > 3;
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 400),
//       curve: Curves.easeOut,
//       constraints: BoxConstraints(
//         minWidth: isMobile ? 220 : 250,
//         maxWidth: isMobile ? 260 : 300,
//       ),
//       decoration: BoxDecoration(
//         color: active
//             ? item.color.withOpacity(.14)
//             : Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: active ? item.color : Colors.white.withOpacity(.08),
//           width: active ? 1.4 : 1,
//         ),
//         boxShadow: active
//             ? [
//           BoxShadow(
//             color: item.color.withOpacity(.28),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ]
//             : [],
//       ),
//       child: Padding(
//         padding: EdgeInsets.fromLTRB(5, 8, 14, 5),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── Header: icon chip + title + active dot ──
//             Row(
//               children: [
//                 Container(
//
//                   decoration: BoxDecoration(
//                     color: item.color.withOpacity(.22),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     item.icon,
//                     color: item.color,
//                     size: isMobile ? 16 : 18,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Expanded(
//                   child: Text(
//                     item.title.toUpperCase(),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     style: TextStyle(
//                       color: C.textHigh,
//                       fontWeight: FontWeight.w700,
//                       fontSize: isMobile ? 12.5 : 14,
//                       letterSpacing: 0.6,
//                     ),
//                   ),
//                 ),
//                 if (active)
//                   Container(
//                     width: 7,
//                     height: 7,
//                     decoration: BoxDecoration(
//                       color: item.color,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: item.color.withOpacity(.6),
//                           blurRadius: 4,
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//
//             const SizedBox(height: 3),
//
//             // ── Divider line under header ──
//             Container(
//               height: 1,
//               color: C.border,
//             ),
//
//             const SizedBox(height: 5),
//
//             // ── Metrics ──
//             useGrid ? _metricGrid(item, isMobile) : _metricRow(item, isMobile),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Compact metric row with vertical dividers — for ≤3 metrics
//   Widget _metricRow(DeptCountItem item, bool isMobile) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         for (int i = 0; i < item.metrics.length; i++) ...[
//           if (i > 0)
//             Container(
//               width: 1,
//               height: isMobile ? 30 : 34,
//               color: Colors.white.withOpacity(.10),
//               margin: const EdgeInsets.symmetric(horizontal: 10),
//             ),
//           Expanded(child: _metricBlock(item.metrics[i], isMobile)),
//         ],
//       ],
//     );
//   }
//
//   // Wrap-based grid — for 4+ metrics
//   Widget _metricGrid(DeptCountItem item, bool isMobile) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         const double gap = 10;
//         final double itemWidth = (constraints.maxWidth - gap) / 2;
//
//         return Wrap(
//           spacing: gap,
//           runSpacing: 6,
//           children: item.metrics.map((m) {
//             return SizedBox(
//               width: itemWidth,
//               child: _metricBlock(m, isMobile, boxed: true),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
//
//   // Single metric — big value on top, subtle label below
//   Widget _metricBlock(MetricItem m, bool isMobile, {bool boxed = false}) {
//     final content = Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         FittedBox(
//           fit: BoxFit.scaleDown,
//           alignment: Alignment.centerLeft,
//           child: Text(
//             _fmt(m.value),
//             maxLines: 1,
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w800,
//               fontSize: isMobile ? 18 : 20,
//               height: 1.1,
//             ),
//           ),
//         ),
//         const SizedBox(height: 3),
//         Text(
//           m.label,
//           overflow: TextOverflow.ellipsis,
//           maxLines: 1,
//           style: TextStyle(
//             color: Colors.white.withOpacity(.55),
//             fontSize: isMobile ? 10.5 : 12,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.3,
//           ),
//         ),
//       ],
//     );
//
//     if (!boxed) return content;
//
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.05),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: content,
//     );
//   }
//
//   String _fmt(num value) {
//     if (value >= 1000000000) {
//       return "${(value / 1000000000).toStringAsFixed(1)}B";
//     }
//     if (value >= 1000000) {
//       return "${(value / 1000000).toStringAsFixed(1)}M";
//     }
//     if (value >= 1000) {
//       return "${(value / 1000).toStringAsFixed(1)}K";
//     }
//     if (value == value.roundToDouble()) {
//       return value.toInt().toString();
//     }
//     return value.toStringAsFixed(2);
//   }
//
//   Future loadDashboard() async {
//     try {
//       dashboardSummary = await DashboardService().getDashboard(
//         unit: widget.unit,
//         fromDate: widget.fromDate,
//         toDate: widget.toDate,
//       );
//
//       final marketing = await loadDepartmentCounts();
//
//       final rawList = createDepartments(dashboardSummary!);
//
//       final seen = <String>{};
//       final baseList = rawList.where((e) => seen.add(e.title)).toList();
//
//       final Map<String, DeptCountItem> overrides = {
//         // Inquiry -> ONLY TOTAL
//         "INQUIRY": DeptCountItem(
//           title: "INQUIRY",
//           icon: Icons.query_stats,
//           color: Colors.yellow.shade600,
//           metrics: [
//             MetricItem(
//               "Total",
//               marketing["INQUIRY"]?.totalInquiryCount ?? dashboardSummary!.inquiryCount,
//             ),
//           ],
//         ),
//
//         // Work Order -> ONLY TOTAL
//         "Work Order": DeptCountItem(
//           title: "Work Order",
//           icon: Icons.assignment,
//           color: Colors.blueGrey.shade200,
//           metrics: [
//             MetricItem(
//               "Total",
//               marketing["WO"]?.totalInquiryCount ?? dashboardSummary!.woCount,
//             ),
//           ],
//         ),
//
//         // BOM -> ONLY TOTAL
//         "BOM": DeptCountItem(
//           title: "BOM",
//           icon: Icons.assignment,
//           color: Colors.blueGrey.shade200,
//           metrics: [
//             MetricItem(
//               "Total",
//               marketing["BOM"]?.totalInquiryCount ?? dashboardSummary!.bomCount,
//             ),
//           ],
//         ),
//
//         // RMD -> KG / MTR / ROLL
//         "RMD": DeptCountItem(
//           title: "RMD",
//           icon: Icons.settings,
//           color: Colors.indigo.shade200,
//           metrics: [
//             MetricItem("KG", marketing["RMD"]?.netWeight ?? 0),
//             MetricItem("MTR", marketing["RMD"]?.rollLength ?? 0),
//             MetricItem("Roll", marketing["RMD"]?.noOfRoll ?? 0),
//           ],
//         ),
//       };
//
//       deptCounts = baseList.map((e) => overrides[e.title] ?? e).toList();
//
//       if (mounted) {
//         setState(() => isLoading = false);
//
//         _tickerTimer?.cancel();
//
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _startTicker();
//         });
//       }
//     } catch (e, s) {
//       debugPrint(e.toString());
//       debugPrintStack(stackTrace: s);
//     }
//   }
//
//   Future<Map<String, MarketingCountModel>> loadDepartmentCounts() async {
//     final service = DashboardService();
//
//     final departments = ["WO", "BOM", "INQUIRY", "RMD"];
//
//     final Map<String, MarketingCountModel> result = {};
//
//     await Future.wait(
//       departments.map((dept) async {
//         try {
//           final value = await service.getMarketingCount(
//             unit: widget.unit,
//             type: dept,
//             fromDate: widget.fromDate,
//             toDate: widget.toDate,
//           );
//
//           result[dept] = value;
//
//           debugPrint("$dept Loaded");
//         } catch (e, s) {
//           debugPrint("$dept Failed");
//           debugPrint("$e");
//           debugPrintStack(stackTrace: s);
//         }
//       }),
//     );
//
//     return result;
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';

import '../../Color/Colorclass.dart';
import '../../InquiryScreen/Marketing/MarketingModel.dart';
import '../../services/DashboardApiServices.dart';
import '../Dashboard Summary.dart';
import 'dashBoardMapper.dart';

class MetricItem {
  final String label;
  final num value;

  const MetricItem(this.label, this.value);
}

class DeptCountItem {
  final String title;
  final IconData icon;
  final List<MetricItem> metrics; // 1..n values per dept
  final Color color;

  const DeptCountItem({
    required this.title,
    required this.icon,
    required this.metrics,
    required this.color,
  });
}

// ─────────────────────────────────────────────
//  TOP BAR WIDGET
// ─────────────────────────────────────────────
class DashboardTopBarAnimated extends StatefulWidget {
  final String unit;
  final String fromDate;
  final String toDate;

  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  const DashboardTopBarAnimated({
    super.key,
    required this.unit,
    required this.fromDate,
    required this.toDate,
    this.onMenuTap,
    this.onProfileTap,
  });

  @override
  State<DashboardTopBarAnimated> createState() =>
      _DashboardTopBarAnimatedState();
}

class _DashboardTopBarAnimatedState extends State<DashboardTopBarAnimated>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  bool _isPaused = false;
  int currentIndex = 0;
  DashboardSummary? dashboardSummary;
  List<DeptCountItem> deptCounts = [];
  bool isLoading = true;

  final ScrollController _scrollCtrl = ScrollController();
  Timer? _tickerTimer;
  Timer? _refreshTimer;
  double _scrollPos = 0;
  static const double _scrollSpeed = 0.6;
  static const Duration _tickInterval = Duration(milliseconds: 16);

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn);

    _entranceCtrl.forward();

    loadDashboard();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadDashboard(),
    );
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(_tickInterval, (_) {
      if (_isPaused) return;
      if (!_scrollCtrl.hasClients) return;

      final maxExtent = _scrollCtrl.position.maxScrollExtent;
      if (maxExtent <= 0) return;

      _scrollPos += _scrollSpeed;

      if (_scrollPos >= maxExtent / 2) {
        _scrollPos = 0;
      }

      _scrollCtrl.jumpTo(
        _scrollPos.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      );
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _refreshTimer?.cancel();
    _scrollCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Responsive breakpoints ──
  // mobile < 600, tablet 600–1024, desktop > 1024
  _ScreenSize _sizeOf(double width) {
    if (width < 600) return _ScreenSize.mobile;
    if (width < 1024) return _ScreenSize.tablet;
    return _ScreenSize.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screen = _sizeOf(mq.size.width);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isLoading
                  ? SizedBox(
                      height: screen == _ScreenSize.mobile ? 110 : 140,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    )
                  : _tickerRow(screen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tickerRow(_ScreenSize screen) {
    if (deptCounts.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            "No Data",
            style: TextStyle(
              color: C.textHigh,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final doubled = [...deptCounts, ...deptCounts];
    final cardHeight = switch (screen) {
      _ScreenSize.mobile => 138.0,
      _ScreenSize.tablet => 150.0,
      _ScreenSize.desktop => 162.0,
    };

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: screen == _ScreenSize.mobile ? 14 : 24,
        ),
        itemCount: doubled.length,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Listener(
              onPointerDown: (_) => setState(() => _isPaused = true),
              onPointerUp: (_) => setState(() => _isPaused = false),
              onPointerCancel: (_) => setState(() => _isPaused = false),
              child: _tickerCard(doubled[index], screen),
            ),
          );
        },
      ),
    );
  }

  // ── Card: proper contrast, clear hierarchy, breathing room ──
  Widget _tickerCard(DeptCountItem item, _ScreenSize screen) {
    final bool active = deptCounts[currentIndex].title == item.title;
    final int metricCount = item.metrics.length;
    final bool useGrid = metricCount > 3;
    final bool isMobile = screen == _ScreenSize.mobile;

    final double minW = switch (screen) {
      _ScreenSize.mobile => 210.0,
      _ScreenSize.tablet => 240.0,
      _ScreenSize.desktop => 260.0,
    };
    final double maxW = switch (screen) {
      _ScreenSize.mobile => 250.0,
      _ScreenSize.tablet => 280.0,
      _ScreenSize.desktop => 300.0,
    };

    // Text/label colors now derive from card state instead of being
    // hardcoded white — fixes invisible text on the light inactive card.
    final Color titleColor = active ? item.color.darken(0.15) : C.textHigh;
    final Color valueColor = active ? item.color.darken(0.25) : C.textHigh;
    final Color labelColor = active
        ? item.color.darken(0.05)
        : (C.textLow ?? Colors.black54);
    final Color dividerColor = active ? item.color.withOpacity(.25) : C.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      constraints: BoxConstraints(minWidth: minW, maxWidth: maxW),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withOpacity(.18),
                  item.color.withOpacity(.06),
                ],
              )
            : null,
        color: active ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: item.color, width: active ? 4 : 3),
          top: BorderSide(
            color: active ? item.color.withOpacity(.3) : C.border,
            width: .8,
          ),
          right: BorderSide(
            color: active ? item.color.withOpacity(.3) : C.border,
            width: .8,
          ),
          bottom: BorderSide(
            color: active ? item.color.withOpacity(.3) : C.border,
            width: .8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? item.color.withOpacity(.22)
                : Colors.black.withOpacity(.05),
            blurRadius: active ? 14 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon chip + title + active dot ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: isMobile ? 15 : 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 12 : 13.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            Container(height: 1, color: dividerColor),
            const SizedBox(height: 4),

            // ── Metrics ──
            Expanded(
              child: useGrid
                  ? _metricGrid(item, isMobile, valueColor, labelColor)
                  : _metricRow(item, isMobile, valueColor, labelColor),
            ),
          ],
        ),
      ),
    );
  }

  // Compact metric row with vertical dividers — for ≤3 metrics
  Widget _metricRow(
    DeptCountItem item,
    bool isMobile,
    Color valueColor,
    Color labelColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < item.metrics.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: isMobile ? 30 : 34,
              color: Colors.black.withOpacity(.08),
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
          Expanded(
            child: _metricBlock(
              item.metrics[i],
              isMobile,
              valueColor,
              labelColor,
            ),
          ),
        ],
      ],
    );
  }

  // Wrap-based grid — for 4+ metrics
  Widget _metricGrid(
    DeptCountItem item,
    bool isMobile,
    Color valueColor,
    Color labelColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 8;
        final double itemWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: 6,
          children: item.metrics.map((m) {
            return SizedBox(
              width: itemWidth,
              child: _metricBlock(
                m,
                isMobile,
                valueColor,
                labelColor,
                boxed: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Single metric — big value on top, subtle label below
  Widget _metricBlock(
    MetricItem m,
    bool isMobile,
    Color valueColor,
    Color labelColor, {
    bool boxed = false,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _fmt(m.value),
            maxLines: 1,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: isMobile ? 17 : 19,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          m.label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: labelColor,
            fontSize: isMobile ? 10 : 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    if (!boxed) return content;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: content,
    );
  }

  String _fmt(num value) {
    if (value >= 1000000000) {
      return "${(value / 1000000000).toStringAsFixed(1)}B";
    }
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    }
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Future loadDashboard() async {
    try {
      dashboardSummary = await DashboardService().getDashboard(
        unit: widget.unit,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      final marketing = await loadDepartmentCounts();

      final rawList = createDepartments(dashboardSummary!);

      final seen = <String>{};
      final baseList = rawList.where((e) => seen.add(e.title)).toList();

      final Map<String, DeptCountItem> overrides = {
        // Inquiry -> ONLY TOTAL
        "INQUIRY": DeptCountItem(
          title: "INQUIRY",
          icon: Icons.query_stats,
          color: Colors.amber.shade700,
          metrics: [
            MetricItem(
              "Total",
              marketing["INQUIRY"]?.totalInquiryCount ??
                  dashboardSummary!.inquiryCount,
            ),
          ],
        ),

        // Work Order -> ONLY TOTAL
        "Work Order": DeptCountItem(
          title: "Work Order",
          icon: Icons.assignment,
          color: Colors.blueGrey.shade600,
          metrics: [
            MetricItem(
              "Total",
              marketing["WO"]?.totalInquiryCount ?? dashboardSummary!.woCount,
            ),
          ],
        ),

        // BOM -> ONLY TOTAL
        "BOM": DeptCountItem(
          title: "BOM",
          icon: Icons.assignment,
          color: Colors.blueGrey.shade600,
          metrics: [
            MetricItem(
              "Total",
              marketing["BOM"]?.totalInquiryCount ?? dashboardSummary!.bomCount,
            ),
          ],
        ),

        // RMD -> KG / MTR / ROLL
        "RMD": DeptCountItem(
          title: "RMD",
          icon: Icons.settings,
          color: Colors.indigo.shade600,
          metrics: [
            MetricItem("KG", marketing["RMD"]?.netWeight ?? 0),
            MetricItem("MTR", marketing["RMD"]?.rollLength ?? 0),
            MetricItem("Roll", marketing["RMD"]?.noOfRoll ?? 0),
          ],
        ),
      };

      deptCounts = baseList.map((e) => overrides[e.title] ?? e).toList();

      if (mounted) {
        setState(() => isLoading = false);

        _tickerTimer?.cancel();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startTicker();
        });
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }
  }

  Future<Map<String, MarketingCountModel>> loadDepartmentCounts() async {
    final service = DashboardService();

    final departments = ["WO", "BOM", "INQUIRY", "RMD"];

    final Map<String, MarketingCountModel> result = {};

    await Future.wait(
      departments.map((dept) async {
        try {
          final value = await service.getMarketingCount(
            unit: widget.unit,
            type: dept,
            fromDate: widget.fromDate,
            toDate: widget.toDate,
          );

          result[dept] = value;

          debugPrint("$dept Loaded");
        } catch (e, s) {
          debugPrint("$dept Failed");
          debugPrint("$e");
          debugPrintStack(stackTrace: s);
        }
      }),
    );

    return result;
  }
}

enum _ScreenSize { mobile, tablet, desktop }

// Small helper so item.color.darken(x) works without pulling in another
// package. Drop this in Colorclass.dart (or anywhere globally imported)
// if it's not already there.
extension _ColorShade on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}
