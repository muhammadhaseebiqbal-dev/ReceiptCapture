import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/receipt/bloc/receipt_bloc.dart';
import '../features/receipt/bloc/receipt_event.dart';
import '../features/receipt/bloc/receipt_state.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/receipt_card.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_indicator.dart';

class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<ReceiptBloc>().add(SearchReceipts(query));
    } else {
      context.read<ReceiptBloc>().add(const ClearSearch());
    }
  }

  void _clearSearch() {
    _searchController.clear();
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                ],
              ),
            ),
          // Receipt list
          Expanded(
            child: BlocBuilder<ReceiptBloc, ReceiptState>(
              builder: (context, state) {
                if (state.status == ReceiptStatus.loading) {
                  return const LoadingIndicator();
                }

                if (state.status == ReceiptStatus.failure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'Error loading receipts',
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          state.errorMessage,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        ElevatedButton(
                          onPressed: _refreshReceipts,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                final receiptsToShow = state.isSearching
                    ? state.searchResults
                    : state.receipts;

                if (receiptsToShow.isEmpty) {
                  return EmptyState(
                    icon: state.isSearching
                        ? Icons.search_off
                        : Icons.receipt_long_outlined,
                    title: state.isSearching
                        ? 'No results found'
                        : 'No receipts yet',
                    subtitle: state.isSearching
                        ? 'Try adjusting your search terms'
                        : 'Tap the camera button to capture your first receipt',
                    actionLabel: state.isSearching ? null : 'Capture Receipt',
                    onActionPressed: state.isSearching
                        ? null
                        : () {
                            // Switch to camera tab
                            // Switch to camera tab - handled by parent
                          },
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshReceipts,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    itemCount: receiptsToShow.length,
                    itemBuilder: (context, index) {
                      final receipt = receiptsToShow[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingM,
                        ),
                        child: ReceiptCard(
                          receipt: receipt,
                          onTap: () {
                            // Navigate to receipt detail screen
                            // TODO: Implement receipt detail screen
                          },
                          onEdit: () {
                            // Navigate to edit receipt screen
                            // TODO: Implement edit receipt screen
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
        ],
      ),
    );
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

    if (result == true && context.mounted) {
      context.read<ReceiptBloc>().add(DeleteReceipt(receiptId));
    }
  }
}
