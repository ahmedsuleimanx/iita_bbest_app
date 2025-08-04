import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_sizes.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/products/product_grid_view.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final filterCategoryProvider = StateProvider<ProductCategory?>((ref) => null);
final filterMinPriceProvider = StateProvider<double?>((ref) => null);
final filterMaxPriceProvider = StateProvider<double?>((ref) => null);
final filterInStockProvider = StateProvider<bool>((ref) => false);
final filterHasDiscountProvider = StateProvider<bool>((ref) => false);
final showFiltersProvider = StateProvider<bool>((ref) => false);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).state = widget.initialQuery!;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final showFilters = ref.watch(showFiltersProvider);

    final products = ref.watch(productProvider);
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search Products'),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child:               CustomTextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search for products...',
                prefixIcon: Icons.search,
                suffixIcon: searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                onSubmitted: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: showFilters ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () {
                ref.read(showFiltersProvider.notifier).update((state) => !state);
              },
              tooltip: 'Filter options',
            ),
          ],
        ),
        body: Column(
          children: [
            // Filters section
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: showFilters ? null : 0,
              child: showFilters 
                ? _buildFiltersSection() 
                : const SizedBox.shrink(),
            ),
            
            // Results section
            Expanded(
              child: products.when(
                data: (productList) {
                  // Apply filters to products
                  final filtered = _applyFilters(productList);
              
                  if (filtered.isEmpty && searchQuery.isEmpty && !_hasActiveFilters()) {
                    return _buildEmptyInitialState();
                  }
              
                  if (filtered.isEmpty) {
                    return _buildNoResultsFound();
                  }
              
                  return _buildSearchResults(filtered);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _hasActiveFilters() {
    final filterCategory = ref.read(filterCategoryProvider);
    final filterMinPrice = ref.read(filterMinPriceProvider);
    final filterMaxPrice = ref.read(filterMaxPriceProvider);
    final filterInStock = ref.read(filterInStockProvider);
    final filterHasDiscount = ref.read(filterHasDiscountProvider);
    
    return filterCategory != null || 
           filterMinPrice != null || 
           filterMaxPrice != null || 
           filterInStock || 
           filterHasDiscount;
  }
  
  List<ProductModel> _applyFilters(List<ProductModel> products) {

    final category = ref.read(filterCategoryProvider);
    final minPrice = ref.read(filterMinPriceProvider);
    final maxPrice = ref.read(filterMaxPriceProvider);
    final inStock = ref.read(filterInStockProvider);
    final hasDiscount = ref.read(filterHasDiscountProvider);
    
    // Use the ProductNotifier's methods
    final productNotifier = ref.read(productProvider.notifier);
    
    // Apply filters (search query handled by ProductNotifier internally)
    
    return productNotifier.filterProducts(
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStock: inStock,
      hasDiscount: hasDiscount,
    );
  }

  Widget _buildFiltersSection() {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.s),
            
            // Category filter
            _buildCategoryFilter(),
            const SizedBox(height: AppSizes.s),
            
            // Price range filter
            _buildPriceRangeFilter(),
            const SizedBox(height: AppSizes.s),
            
            // Checkboxes for stock and discount
            Row(
              children: [
                Expanded(child: _buildStockFilter()),
                Expanded(child: _buildDiscountFilter()),
              ],
            ),
            const SizedBox(height: AppSizes.m),
            
            // Filter action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reset Filters',
                    type: ButtonType.outline,
                    onPressed: _resetFilters,
                  ),
                ),
                const SizedBox(width: AppSizes.m),
                Expanded(
                  child: CustomButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      // Filters are applied automatically via providers
                      ref.read(showFiltersProvider.notifier).state = false;
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
    final filterCategory = ref.watch(filterCategoryProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSizes.s),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProductCategory?>(
              isExpanded: true,
              value: filterCategory,
              hint: const Text('All Categories'),
              items: [
                const DropdownMenuItem<ProductCategory?>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...ProductCategory.values.map((category) {
                  return DropdownMenuItem<ProductCategory?>(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                ref.read(filterCategoryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSizes.s),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _minPriceController,
                hintText: 'Min',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                onChanged: (value) {
                  ref.read(filterMinPriceProvider.notifier).state = 
                      value.isEmpty ? null : double.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: AppSizes.m),
            const Text('to'),
            const SizedBox(width: AppSizes.m),
            Expanded(
              child: CustomTextField(
                controller: _maxPriceController,
                hintText: 'Max',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                onChanged: (value) {
                  ref.read(filterMaxPriceProvider.notifier).state = 
                      value.isEmpty ? null : double.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStockFilter() {
    final filterInStock = ref.watch(filterInStockProvider);
    
    return CheckboxListTile(
      title: const Text('In Stock Only'),
      value: filterInStock,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (value) {
        ref.read(filterInStockProvider.notifier).state = value ?? false;
      },
    );
  }
  
  Widget _buildDiscountFilter() {
    final filterHasDiscount = ref.watch(filterHasDiscountProvider);
    
    return CheckboxListTile(
      title: const Text('Discounted Only'),
      value: filterHasDiscount,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (value) {
        ref.read(filterHasDiscountProvider.notifier).state = value ?? false;
      },
    );
  }
  
  void _resetFilters() {
    _minPriceController.clear();
    _maxPriceController.clear();
    ref.read(filterCategoryProvider.notifier).state = null;
    ref.read(filterMinPriceProvider.notifier).state = null;
    ref.read(filterMaxPriceProvider.notifier).state = null;
    ref.read(filterInStockProvider.notifier).state = false;
    ref.read(filterHasDiscountProvider.notifier).state = false;
  }
  




  Widget _buildSearchResults(List<ProductModel> products) {
    return FadeIn(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Found ${products.length} products',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: ProductGridView(
                products: products,
                onAddToCart: (product) async {
                  try {
                    await ref.read(cartProvider.notifier).addItem(product, 1);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          action: SnackBarAction(
                            label: 'View Cart',
                            onPressed: () {
                              GoRouter.of(context).push('/cart');
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add item to cart: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyInitialState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: AppSizes.m),
            const Text(
              'Start searching for products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.s),
            const Text(
              'Enter a search term or use filters',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoResultsFound() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                      Icon(
            Icons.search_off,
            size: 80,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
            const SizedBox(height: AppSizes.m),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.s),
            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppSizes.m),
            CustomButton(
              text: 'Reset All',
              type: ButtonType.outline,
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
                _resetFilters();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.m),
          const Text(
            'Error loading products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.s),
          Text(
            error.toString(),
            style: const TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.m),
          CustomButton(
            text: 'Try Again',
            onPressed: () {
              ref.read(productProvider.notifier).loadProducts();
            },
          ),
        ],
      ),
    );
  }
} 