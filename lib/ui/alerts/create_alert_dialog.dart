import 'package:flutter/material.dart';
import '../../core/service_locator.dart';
import '../../domain/price_alert.dart';
import '../../services/alert_service.dart';
import '../design_system/vx_colors.dart';

class CreateAlertDialog extends StatefulWidget {
  final String symbol;
  final double currentPrice;

  const CreateAlertDialog({
    super.key,
    required this.symbol,
    required this.currentPrice,
  });

  @override
  State<CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<CreateAlertDialog> {
  late TextEditingController _priceController;
  AlertType _selectedType = AlertType.crossesAbove;

  @override
  void initState() {
    super.initState();
    _priceController =
        TextEditingController(text: widget.currentPrice.toStringAsFixed(2));

    // Auto-select logic
    // If we type higher than current, assume Crosses Above
    _priceController.addListener(_updateType);
  }

  void _updateType() {
    final target = double.tryParse(_priceController.text);
    if (target != null) {
      setState(() {
        if (target > widget.currentPrice) {
          _selectedType = AlertType.crossesAbove;
        } else {
          _selectedType = AlertType.crossesBelow;
        }
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VxColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "SET ALERT: ${widget.symbol}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            // Current Price
            Text(
              "Current: \$${widget.currentPrice.toStringAsFixed(2)}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),

            // Toggle Type
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    AlertType.crossesAbove,
                    "Crosses Above",
                    Icons.trending_up,
                    VxColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTypeButton(
                    AlertType.crossesBelow,
                    "Crosses Below",
                    Icons.trending_down,
                    VxColors.neonRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: "\$ ",
                prefixStyle: const TextStyle(color: Colors.grey, fontSize: 24),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: VxColors.neonPurple),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Add Button
            ElevatedButton(
              onPressed: _saveAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: VxColors.neonPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "CREATE ALERT",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
      AlertType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.white10,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAlert() {
    final target = double.tryParse(_priceController.text);
    if (target == null) return;

    final alert = PriceAlert(
      symbol: widget.symbol,
      targetPrice: target,
      type: _selectedType,
    );

    getIt<AlertService>().addAlert(alert);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alert Created!"),
          backgroundColor: VxColors.neonCyan,
        ),
      );
    }
  }
}
