import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../common/custom_text_field.dart';

class OrderFilterCriteria {
  final OrderStatus? status;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;

  const OrderFilterCriteria({
    this.status,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  OrderFilterCriteria copyWith({
    OrderStatus? status,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    return OrderFilterCriteria(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      (searchQuery?.isNotEmpty == true) ||
      startDate != null ||
      endDate != null ||
      minAmount != null ||
      maxAmount != null;
}

class AdvancedOrderFilter extends ConsumerStatefulWidget {
  final OrderFilterCriteria initialCriteria;
  final Function(OrderFilterCriteria) onFilterChanged;

  const AdvancedOrderFilter({
    super.key,
    required this.initialCriteria,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<AdvancedOrderFilter> createState() => _AdvancedOrderFilterState();
}

class _AdvancedOrderFilterState extends ConsumerState<AdvancedOrderFilter> {
  late OrderFilterCriteria _criteria;
  final _searchController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
    _searchController.text = _criteria.searchQuery ?? '';
    _minAmountController.text = _criteria.minAmount?.toString() ?? '';
    _maxAmountController.text = _criteria.maxAmount?.toString() ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advanced Filters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (_criteria.hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Query
          CustomTextField(
            controller: _searchController,
            label: 'Search Orders',
            hint: 'Order ID, customer name, address...',
            prefixIcon: Icons.search,
            onChanged: (value) {
              _updateCriteria(_criteria.copyWith(searchQuery: value.isEmpty ? null : value));
            },
          ),
          const SizedBox(height: 16),

          // Order Status Filter
          _buildStatusFilter(),
          const SizedBox(height: 16),

          // Date Range Filter
          _buildDateRangeFilter(),
          const SizedBox(height: 16),

          // Amount Range Filter
          _buildAmountRangeFilter(),
          const SizedBox(height: 16),

          // Filter Summary
          if (_criteria.hasActiveFilters) _buildFilterSummary(),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip(null, 'All Orders'),
            ...OrderStatus.values.map((status) => _buildStatusChip(status, status.displayName)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus? status, String label) {
    final isSelected = _criteria.status == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _updateCriteria(_criteria.copyWith(status: selected ? status : null));
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _criteria.startDate,
                onDateSelected: (date) {
                  _updateCriteria(_criteria.copyWith(startDate: date));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                date: _criteria.endDate,
                onDateSelected: (date) {
                  _updateCriteria(_criteria.copyWith(endDate: date));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(onDateSelected),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Select date',
                  style: TextStyle(
                    color: date != null ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Amount Range',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _minAmountController,
                label: 'Min Amount',
                hint: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  _updateCriteria(_criteria.copyWith(minAmount: amount));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _maxAmountController,
                label: 'Max Amount',
                hint: '999.99',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  _updateCriteria(_criteria.copyWith(maxAmount: amount));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSummary() {
    final activeFilters = <String>[];
    
    if (_criteria.status != null) {
      activeFilters.add('Status: ${_criteria.status!.displayName}');
    }
    if (_criteria.searchQuery?.isNotEmpty == true) {
      activeFilters.add('Search: "${_criteria.searchQuery}"');
    }
    if (_criteria.startDate != null) {
      activeFilters.add('From: ${DateFormat('MMM dd, yyyy').format(_criteria.startDate!)}');
    }
    if (_criteria.endDate != null) {
      activeFilters.add('To: ${DateFormat('MMM dd, yyyy').format(_criteria.endDate!)}');
    }
    if (_criteria.minAmount != null) {
      activeFilters.add('Min: \$${_criteria.minAmount!.toStringAsFixed(2)}');
    }
    if (_criteria.maxAmount != null) {
      activeFilters.add('Max: \$${_criteria.maxAmount!.toStringAsFixed(2)}');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Active Filters (${activeFilters.length})',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeFilters.map((filter) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(Function(DateTime?) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _updateCriteria(OrderFilterCriteria newCriteria) {
    setState(() {
      _criteria = newCriteria;
    });
    widget.onFilterChanged(_criteria);
  }

  void _clearAllFilters() {
    _searchController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    
    const clearedCriteria = OrderFilterCriteria();
    setState(() {
      _criteria = clearedCriteria;
    });
    widget.onFilterChanged(clearedCriteria);
  }
}
