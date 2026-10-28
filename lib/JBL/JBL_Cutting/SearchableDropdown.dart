import 'package:flutter/material.dart';
import '../../../Color/Colorclass.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final T? value;


  final List<T>? items;
  final Future<List<T>> Function()? fetchItems;

  /// T ko display string me convert karne ke liye
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.items,
    this.fetchItems,
    this.hint = "Select",
    this.enabled = true,
  }) : assert(items != null || fetchItems != null,
  'items ya fetchItems me se ek dena zaroori hai');

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  List<T>? _cache; // API data ek baar fetch ke baad cache

  Future<List<T>> _load({bool force = false}) async {
    if (widget.items != null) return widget.items!;
    if (_cache != null && !force) return _cache!;
    _cache = await widget.fetchItems!();
    return _cache!;
  }

  Future<void> _open() async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SearchSheet<T>(
        title: widget.label,
        load: _load,
        itemLabel: widget.itemLabel,
        selected: widget.value,
      ),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.value == null ? "" : widget.itemLabel(widget.value as T);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: C.textHigh)),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.enabled ? _open : null,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.brand300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text.isEmpty ? widget.hint : text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: text.isEmpty
                          ? Colors.grey
                          : const Color(0xFF1A2340),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchSheet<T> extends StatefulWidget {
  final String title;
  final Future<List<T>> Function({bool force}) load;
  final String Function(T) itemLabel;
  final T? selected;

  const _SearchSheet({
    required this.title,
    required this.load,
    required this.itemLabel,
    required this.selected,
  });

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  final _search = TextEditingController();
  List<T> _all = [];
  List<T> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _all = await widget.load(force: force);
      _applyFilter(_search.text);
      _loading = false;
    } catch (e) {
      _error = "Try again";
      _loading = false;
    }
    if (mounted) setState(() {});
  }

  void _applyFilter(String q) {
    final query = q.trim().toLowerCase();
    _filtered = query.isEmpty
        ? List.of(_all)
        : _all
        .where((e) => widget.itemLabel(e).toLowerCase().contains(query))
        .toList();
    setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: h * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Select ${widget.title}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: _applyFilter,
                decoration: InputDecoration(
                  hintText: "Search...",
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _search.clear();
                      _applyFilter('');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: C.brand300),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => _fetch(force: true),
                child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) return const Center(child: Text("No results"));

    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = _filtered[i];
        final isSel = item == widget.selected;
        return ListTile(
          dense: true,
          title: Text(widget.itemLabel(item),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
          trailing: isSel
              ? const Icon(Icons.check, size: 18, color: C.primaryDark)
              : null,
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }
}