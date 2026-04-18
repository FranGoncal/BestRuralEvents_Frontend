import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../models/ticket.dart';

class TicketQrDialog extends StatelessWidget {
  final Ticket ticket;
  final String qrToken;
  final String formattedPurchaseDate;

  const TicketQrDialog({
    super.key,
    required this.ticket,
    required this.qrToken,
    required this.formattedPurchaseDate,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Event title
            Text(
              ticket.event.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF37474F),
              ),
            ),

            const SizedBox(height: 10),

            // Instruction
            Text(
              'Show this QR code at the entrance',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 20),

            // QR Code (main focus)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: QrImageView(
                data: qrToken,
                version: QrVersions.auto,
                size: 230,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 18),

            // Purchase date (optional but clean)
            Text(
              'Purchased on $formattedPurchaseDate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}