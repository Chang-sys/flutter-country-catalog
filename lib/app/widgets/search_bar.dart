import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search country...',
  }) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _handleClear() {
    // If field has text: clear it and notify parent via onChanged (keep search open).
    if (widget.controller.text.isNotEmpty) {
      widget.controller.clear();
      // notify parent that query changed to empty (so controller/filter updates)
      widget.onChanged('');
      // keep focus so keyboard stays open (user can type again immediately)
      // If you prefer to drop the keyboard on clearing, call: FocusScope.of(context).unfocus();
      return;
    }

    // If field is empty: unfocus (hide keyboard) and tell parent to close the search UI
    FocusScope.of(context).unfocus();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final hintStyle =
        Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
          color: Colors.black,
          fontSize: 14,
        ) ??
        const TextStyle(color: Colors.grey, fontSize: 14);

    return Container(
      height: kToolbarHeight - 8,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.grey,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: hintStyle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: _handleClear,
            ),
          ),
        ),
      ),
    );
  }
}
