import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scale_tap.dart';

/// A tappable number label that swaps in place for a small text field when
/// tapped — lets a value be typed in exactly instead of dragged/tapped to
/// via a slider or +/- stepper. Deliberately inline, not a dialog: a modal
/// here would fight the host bottom sheet's own keyboard-avoidance
/// animation for the same frame, which is what used to crash and stutter.
class EditableNumberLabel extends StatefulWidget {
  const EditableNumberLabel({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.style,
    this.suffix,
    this.decimals = 0,
    this.width = 56,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final TextStyle style;
  final String? suffix;
  final int decimals;
  final double width;

  @override
  State<EditableNumberLabel> createState() => _EditableNumberLabelState();
}

class _EditableNumberLabelState extends State<EditableNumberLabel> {
  bool _editing = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) _commit();
  }

  String get _formatted => widget.decimals > 0
      ? widget.value.toStringAsFixed(widget.decimals)
      : widget.value.round().toString();

  void _startEditing() {
    _controller.text = _formatted;
    setState(() => _editing = true);
    // The field doesn't exist in the tree yet this frame — focus it once
    // it does, instead of racing the not-yet-built FocusNode attachment.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // Pushed live on every keystroke, not just on submit/blur — a "Save"
  // button elsewhere on screen (e.g. _NumberEditScreen) reads whatever the
  // parent's value is at the moment it's tapped, and tapping a plain button
  // doesn't blur this field first (Flutter only unfocuses on an explicit
  // FocusScope change), so waiting for blur to commit silently dropped
  // whatever was typed if the user never dismissed the keyboard first.
  void _onTextChanged(String text) {
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed != null) widget.onChanged(parsed.clamp(widget.min, widget.max));
  }

  void _commit() {
    _onTextChanged(_controller.text);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return ScaleTap(
        onTap: _startEditing,
        child: Text(
          widget.suffix == null ? _formatted : '$_formatted ${widget.suffix}',
          style: widget.style,
        ),
      );
    }
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        style: widget.style,
        decoration: InputDecoration(
          isDense: true,
          suffixText: widget.suffix,
          contentPadding: EdgeInsets.zero,
          border: const UnderlineInputBorder(),
        ),
        onChanged: _onTextChanged,
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}
