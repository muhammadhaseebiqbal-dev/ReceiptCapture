import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/database/models.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReceiptCard({
    super.key,
    required this.receipt,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Receipt image thumbnail
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      child: _buildReceiptImage(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),

                  // Receipt details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.merchantName ?? 'Unknown Merchant',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        if (receipt.amount != null)
                          Text(
                            '\$${receipt.amount!.toStringAsFixed(2)}',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          _formatDate(receipt.date ?? receipt.createdAt),
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: AppTheme.errorColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Category and upload status
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  if (receipt.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        receipt.category!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  
                  // Upload Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(receipt.uploadStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(receipt.uploadStatus),
                          size: 12,
                          color: _getStatusColor(receipt.uploadStatus),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(receipt.uploadStatus),
                          style: AppTheme.bodySmall.copyWith(
                            color: _getStatusColor(receipt.uploadStatus),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptImage() {
    final imagePath = receipt.croppedImagePath ?? receipt.imagePath;

    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.receipt, color: Colors.grey, size: 30),
      );
    }

    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
      );
    }

    return Image.file(
      imageFile,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final receiptDate = DateTime(date.year, date.month, date.day);

    if (receiptDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (receiptDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE, h:mm a').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return Colors.green;
      case 'uploading':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      case 'queued':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return Icons.cloud_done;
      case 'uploading':
        return Icons.cloud_upload;
      case 'failed':
        return Icons.error_outline;
      case 'queued':
      default:
        return Icons.schedule;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return 'Uploaded';
      case 'uploading':
        return 'Uploading';
      case 'failed':
        return 'Failed';
      case 'queued':
      default:
        return 'Queued';
    }
  }
}
