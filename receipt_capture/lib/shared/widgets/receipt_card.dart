import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/database/models.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ReceiptCard({
    super.key,
    required this.receipt,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Receipt image thumbnail with modern styling
                    Hero(
                      tag: 'receipt_${receipt.id}',
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildReceiptImage(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Receipt details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Receipt name with modern typography
                          Text(
                            receipt.merchantName?.isNotEmpty == true 
                                ? receipt.merchantName! 
                                : 'Unnamed Receipt',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Date with subtle styling
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(receipt.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status indicator and actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Upload status with modern indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(receipt.isSynced).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(receipt.isSynced).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(receipt.isSynced),
                                size: 12,
                                color: _getStatusColor(receipt.isSynced),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                receipt.isSynced ? 'Synced' : 'Local',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(receipt.isSynced),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Action button
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_rounded,
                                      size: 18,
                                      color: AppTheme.errorColor,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit?.call();
                              } else if (value == 'delete') {
                                onDelete?.call();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptImage(BuildContext context) {
    if (receipt.imagePath.isNotEmpty) {
      final imageFile = File(receipt.imagePath);
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(context),
        );
      }
    }
    return _buildImagePlaceholder(context);
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.receipt_long_rounded,
        color: Colors.white.withOpacity(0.8),
        size: 28,
      ),
    );
  }

  Color _getStatusColor(bool isSynced) {
    return isSynced ? AppTheme.successColor : AppTheme.warningColor;
  }

  IconData _getStatusIcon(bool isSynced) {
    return isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded;
  }
}