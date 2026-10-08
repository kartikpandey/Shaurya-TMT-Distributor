import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';

/// Decimal quantity field in tonnes with − / + stepper buttons.
class TonnageInput extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;

  const TonnageInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 0.5,
  });

  // Show whole tonnes without decimals and trim trailing zeros otherwise
  static String format(double tonnes) {
    final fixed = tonnes.toStringAsFixed(3);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  State<TonnageInput> createState() => _TonnageInputState();
}

class _TonnageInputState extends State<TonnageInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: TonnageInput.format(widget.value),
    );
  }

  @override
  void didUpdateWidget(TonnageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text when the value changed from outside, but not while typing
    final typed = double.tryParse(_controller.text);
    if (widget.value != oldWidget.value && typed != widget.value) {
      _controller.text = TonnageInput.format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stepBy(double delta) {
    final next = double.parse((widget.value + delta).toStringAsFixed(3));
    if (next <= 0) return;
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            iconSize: 18,
            tooltip: 'Decrease',
            onPressed:
                widget.value - widget.step > 0
                    ? () => _stepBy(-widget.step)
                    : null,
          ),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                suffixText: 't',
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (text) {
                final parsed = double.tryParse(text);
                if (parsed != null && parsed > 0) widget.onChanged(parsed);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 18,
            tooltip: 'Increase',
            onPressed: () => _stepBy(widget.step),
          ),
        ],
      ),
    );
  }
}
