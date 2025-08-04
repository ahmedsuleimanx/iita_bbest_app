import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';

import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/common/adaptive_image.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/custom_text_field.dart';
import 'product_edit_screen.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  // State variables
  bool _isLoading = false;
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  String _sortBy = 'name'; // Default sort by name
  bool _sortAscending = true;
  bool _showOnlyLowStock = false;
  
  // Selected products for bulk actions
  final List<String> _selectedProductIds = [];

  @override
  Widget build(BuildContext context) {
    // Watch products
    final productsState = ref.watch(productProvider);
    final categories = ref.watch(productCategoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          // Bulk actions menu
          if (_selectedProductIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showBulkActionsMenu(context),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _buildControls(categories),
            Expanded(
              child: productsState.when(
                data: (products) => _buildProductsList(products),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ErrorState(
                  title: 'Error Loading Products',
                  message: 'Error loading products: $error',
                  onRetry: () => ref.refresh(productProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditProduct(null),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Controls section with search, filter, and sort options
  Widget _buildControls(List<ProductCategory> categories) {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            CustomTextField(
              hintText: 'Search products...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: AppSizes.p12),
            Row(
              children: [
                // Category filter
                Expanded(
                  child: DropdownButtonFormField<ProductCategory?>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.p12,
                        vertical: AppSizes.p8,
                      ),
                    ),
                    value: _selectedCategory,
                    items: [
                      const DropdownMenuItem<ProductCategory?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map(
                        (category) => DropdownMenuItem<ProductCategory?>(
                          value: category,
                          child: Text(category.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                // Sort options
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.p12,
                        vertical: AppSizes.p8,
                      ),
                    ),
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'price', child: Text('Price')),
                      DropdownMenuItem(value: 'stock', child: Text('Stock')),
                      DropdownMenuItem(value: 'date', child: Text('Date Added')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                // Sort order toggle
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
              ],
            ),
            // Additional filters
            Row(
              children: [
                // Low stock filter
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Low Stock Items'),
                    value: _showOnlyLowStock,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyLowStock = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                // Clear all filters button
                                  CustomButton(
                    onPressed: _clearFilters,
                    text: 'Clear Filters',
                    type: ButtonType.outline,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Product list with filtering and sorting
  Widget _buildProductsList(List<ProductModel> allProducts) {
    // Apply filters and sorting
    List<ProductModel> filteredProducts = allProducts;
    
    // Filter by category
    if (_selectedCategory != null) {
      filteredProducts = filteredProducts.where(
        (product) => product.category == _selectedCategory
      ).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredProducts = filteredProducts.where((product) {
        return product.name.toLowerCase().contains(query) ||
               product.description.toLowerCase().contains(query) ||
               product.id.toLowerCase().contains(query);
      }).toList();
    }
    
    // Filter by low stock
    if (_showOnlyLowStock) {
      filteredProducts = filteredProducts.where(
        (product) => product.stockQuantity <= 10 && product.stockQuantity > 0
      ).toList();
    }
    
    // Apply sorting
    filteredProducts.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'price':
          result = a.price.compareTo(b.price);
          break;
        case 'stock':
          result = a.stockQuantity.compareTo(b.stockQuantity);
          break;
        case 'date':
          result = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          result = a.name.compareTo(b.name);
      }
      return _sortAscending ? result : -result;
    });

    // Empty state
    if (filteredProducts.isEmpty) {
      return EmptyState(
        title: 'No Products Found',
        message: 'No products match your search criteria.',
        lottieAsset: 'assets/animations/empty_box.json',
        buttonLabel: 'Add New Product',
        onButtonPressed: () => _navigateToEditProduct(null),
      );
    }

    // Products list view
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        itemCount: filteredProducts.length,
        padding: const EdgeInsets.all(AppSizes.p16),
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          final isSelected = _selectedProductIds.contains(product.id);
          
          return _buildProductCard(product, isSelected);
        },
      ),
    );
  }
  
  // Individual product card
  Widget _buildProductCard(ProductModel product, bool isSelected) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.p8),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _toggleProductSelection(product.id),
        onLongPress: () => _navigateToEditProduct(product),
        borderRadius: BorderRadius.circular(AppSizes.p8),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox for selection
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleProductSelection(product.id),
              ),
              
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.p8),
                child: product.imageUrls.isNotEmpty
                    ? AdaptiveImage(
                        imagePath: product.mainImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
              const SizedBox(width: AppSizes.p12),
              
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and ID
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ID: ${product.id.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    
                    // Category
                    Chip(
                      label: Text(
                        product.category.displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(height: AppSizes.p4),
                    
                    // Price and stock
                    Row(
                      children: [
                        Text(
                          '${AppStrings.currencySymbol}${product.discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (product.hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSizes.p4),
                            child: Text(
                              '${AppStrings.currencySymbol}${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          'Stock: ${product.stockQuantity}',
                          style: TextStyle(
                            color: _getStockColor(product.stockQuantity),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions popup menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleProductAction(value, product),
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle_availability',
                    child: ListTile(
                      leading: Icon(product.isAvailable ? Icons.visibility_off : Icons.visibility),
                      title: Text(product.isAvailable ? 'Hide Product' : 'Show Product'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
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

  // Helper widget for product image placeholder
  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey),
      ),
    );
  }
  
  // Handle product menu actions
  void _handleProductAction(String action, ProductModel product) async {
    switch (action) {
      case 'edit':
        _navigateToEditProduct(product);
        break;
        
      case 'toggle_availability':
        await _toggleProductAvailability(product);
        break;
        
      case 'delete':
        await _confirmDeleteProduct(product);
        break;
    }
  }
  
  // Show bulk actions menu
  void _showBulkActionsMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'make_available',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Make Available'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'make_unavailable',
          child: ListTile(
            leading: Icon(Icons.visibility_off),
            title: Text('Make Unavailable'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) => _handleBulkAction(value));
  }

  // Handle bulk actions on selected products
  void _handleBulkAction(String? action) async {
    if (action == null || _selectedProductIds.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final productNotifier = ref.read(productProvider.notifier);
      final products = ref.read(productProvider).asData?.value ?? [];
      final selectedProducts = products
          .where((p) => _selectedProductIds.contains(p.id))
          .toList();

      switch (action) {
        case 'make_available':
          for (final product in selectedProducts) {
            if (!product.isAvailable) {
              await productNotifier.updateProduct(
                product.copyWith(isAvailable: true),
              );
            }
          }
          break;
          
        case 'make_unavailable':
          for (final product in selectedProducts) {
            if (product.isAvailable) {
              await productNotifier.updateProduct(
                product.copyWith(isAvailable: false),
              );
            }
          }
          break;
          
        case 'delete':
          final confirmed = await _confirmDeleteBulkProducts();
          if (confirmed) {
            for (final product in selectedProducts) {
              await productNotifier.deleteProduct(product.id);
            }
            setState(() {
              _selectedProductIds.clear();
            });
          }
          break;
      }
      
      // Show confirmation
      _showSnackBar('Selected products updated successfully');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Toggle product availability
  Future<void> _toggleProductAvailability(ProductModel product) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(productProvider.notifier).updateProduct(
        product.copyWith(isAvailable: !product.isAvailable),
      );
      _showSnackBar(
        product.isAvailable 
            ? 'Product hidden from catalog' 
            : 'Product now visible in catalog',
      );
    } catch (e) {
      _showSnackBar('Error updating product: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Confirm and delete product
  Future<void> _confirmDeleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await ref.read(productProvider.notifier).deleteProduct(product.id);
        _showSnackBar('Product deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting product: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Confirm and delete multiple products
  Future<bool> _confirmDeleteBulkProducts() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: Text(
          'Are you sure you want to delete ${_selectedProductIds.length} selected products? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Toggle product selection for bulk actions
  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  // Navigate to add/edit product screen
  void _navigateToEditProduct(ProductModel? product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditScreen(product: product),
        fullscreenDialog: true,
      ),
    );
  }

  // Clear all applied filters
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _sortBy = 'name';
      _sortAscending = true;
      _showOnlyLowStock = false;
    });
  }

  // Show a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Get color based on stock level
  Color _getStockColor(int stockQuantity) {
    if (stockQuantity <= 0) {
      return Colors.red;
    } else if (stockQuantity <= 5) {
      return Colors.orange;
    } else if (stockQuantity <= 10) {
      return Colors.amber.shade700;
    } else {
      return Colors.green;
    }
  }
}