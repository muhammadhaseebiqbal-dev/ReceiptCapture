import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/receipt/bloc/receipt_bloc.dart';
import '../features/receipt/bloc/receipt_event.dart';
import '../features/receipt/bloc/receipt_state.dart';
import '../core/database/models.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/receipt_card.dart';
import '../shared/widgets/empty_state.dart';
import 'receipt_form_screen.dart';
import '../shared/widgets/loading_indicator.dart';

class ReceiptListScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCamera;

  const ReceiptListScreen({super.key, this.onNavigateToCamera});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const double _bottomNavClearance = 100;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load receipts when the screen initializes
    context.read<ReceiptBloc>().add(const LoadReceipts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {});
    if (query.isNotEmpty) {
      context.read<ReceiptBloc>().add(SearchReceipts(query));
    } else {
      context.read<ReceiptBloc>().add(const ClearSearch());
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    context.read<ReceiptBloc>().add(const ClearSearch());
    _searchFocusNode.unfocus();
  }

  Future<void> _refreshReceipts() async {
    context.read<ReceiptBloc>().add(const RefreshReceipts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Receipts',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: IconButton(
                          onPressed: _refreshReceipts,
                          icon: const Icon(Icons.refresh_rounded),
                          iconSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search receipts...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ReceiptBloc, ReceiptState>(
                    buildWhen: (previous, current) =>
                        previous.receipts != current.receipts ||
                        previous.searchResults != current.searchResults ||
                        previous.isSearching != current.isSearching,
                    builder: (context, state) {
                      return _buildActivityOverview(state);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Receipt list
            Expanded(
              child: BlocListener<ReceiptBloc, ReceiptState>(
                listener: (context, state) {
                  if (state.status == ReceiptStatus.failure &&
                      state.errorMessage.contains('delete')) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Failed to delete receipt: ${state.errorMessage}',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.errorColor,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Retry',
                          textColor: Colors.white,
                          onPressed: _refreshReceipts,
                        ),
                      ),
                    );
                  }
                },
                child: BlocBuilder<ReceiptBloc, ReceiptState>(
                  builder: (context, state) {
                    if (state.status == ReceiptStatus.loading) {
                      return const LoadingIndicator();
                    }

                    if (state.status == ReceiptStatus.failure) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Oops! Something went wrong',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.errorMessage,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _refreshReceipts,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final receiptsToShow = state.isSearching
                        ? state.searchResults
                        : state.receipts;

                    if (receiptsToShow.isEmpty) {
                      return EmptyState(
                        icon: state.isSearching
                            ? Icons.search_off_rounded
                            : Icons.receipt_long_outlined,
                        title: state.isSearching
                            ? 'No results found'
                            : 'No receipts yet',
                        subtitle: state.isSearching
                            ? 'Try adjusting your search terms'
                            : 'Tap the camera button to capture your first receipt',
                        actionLabel: state.isSearching
                            ? null
                            : 'Capture Receipt',
                        onActionPressed: state.isSearching
                            ? null
                            : widget.onNavigateToCamera,
                      );
                    }

                    return RefreshIndicator(
                      color: AppTheme.primaryColor,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      onRefresh: _refreshReceipts,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          _bottomNavClearance,
                        ),
                        itemCount: receiptsToShow.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildActivityListHeader(
                                count: receiptsToShow.length,
                                isSearching: state.isSearching,
                              ),
                            );
                          }

                          final receipt = receiptsToShow[index - 1];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ReceiptCard(
                              receipt: receipt,
                              onTap: () {
                                // Navigate to receipt details view (read-only)
                                _viewReceiptDetails(context, receipt);
                              },
                              onEdit: () {
                                _editReceipt(context, receipt);
                              },
                              onDelete: () {
                                _showDeleteConfirmation(context, receipt.id);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editReceipt(BuildContext context, Receipt receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptFormScreen(
          imagePath: receipt.imagePath,
          croppedImagePath: receipt.croppedImagePath,
          isEditing: true,
          existingReceipt: receipt,
        ),
      ),
    );
  }

  void _viewReceiptDetails(BuildContext context, Receipt receipt) {
    // For now, just navigate to edit mode for viewing
    // Later you can create a dedicated details/view screen
    _editReceipt(context, receipt);
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String receiptId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text(
          'Are you sure you want to delete this receipt? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      debugPrint(
        '=== UI DELETE: User confirmed deletion of receipt: $receiptId',
      );

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Deleting receipt...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      context.read<ReceiptBloc>().add(DeleteReceipt(receiptId));
    }
  }

  Widget _buildActivityOverview(ReceiptState state) {
    final totalReceipts = state.receipts.length;
    final syncedReceipts = state.receipts
        .where((receipt) => receipt.isSynced)
        .length;
    final localReceipts = totalReceipts - syncedReceipts;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewPill(
            context: context,
            icon: Icons.receipt_long_rounded,
            label: 'Total',
            value: '$totalReceipts',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewPill(
            context: context,
            icon: Icons.cloud_done_rounded,
            label: 'Synced',
            value: '$syncedReceipts',
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOverviewPill(
            context: context,
            icon: Icons.schedule_rounded,
            label: 'Pending',
            value: '$localReceipts',
            color: AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityListHeader({
    required int count,
    required bool isSearching,
  }) {
    final subtitle = isSearching
        ? '$count matching results'
        : '$count receipts in your timeline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSearching ? Icons.manage_search_rounded : Icons.timeline_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
