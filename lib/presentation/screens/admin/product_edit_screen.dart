import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';


import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../services/local_image_service.dart';
import '../../widgets/common/adaptive_image.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  const ProductEditScreen({super.key, this.product});
  
  final ProductModel? product;

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _unitController;
  late final TextEditingController _discountController;
  
  ProductCategory _selectedCategory = ProductCategory.other;
  bool _isAvailable = true;
  bool _isLoading = false;
  
  // Image upload functionality
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isUploadingImages = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing product data if editing
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    _stockController = TextEditingController(text: product?.stockQuantity.toString() ?? '');
    _unitController = TextEditingController(text: product?.unit ?? 'pieces');
    _discountController = TextEditingController(text: product?.discountPercentage?.toString() ?? '');
    
    if (product != null) {
      _selectedCategory = product.category;
      _isAvailable = product.isAvailable;
      _existingImageUrls = List.from(product.imageUrls);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  /// Pick images from gallery or camera
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload images to local storage using LocalImageService
  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    
    setState(() {
      _isUploadingImages = true;
    });
    
    try {
      // Use the LocalImageService for local storage
      final uploadedPaths = await LocalImageService.uploadMultipleImages(
        imageFiles: _selectedImages,
        uploadType: UploadType.product,
        onProgress: (current, total) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saving image $current of $total locally...'),
                duration: const Duration(milliseconds: 800),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
      );
      
      if (uploadedPaths.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved ${uploadedPaths.length} images locally!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      return uploadedPaths;
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save images locally';
        
        // Provide more specific error messages based on the exception
        if (e.toString().contains('Permission denied')) {
          errorMessage = 'Permission denied. Please check file system permissions.';
        } else if (e.toString().contains('No space left')) {
          errorMessage = 'Not enough storage space available.';
        } else {
          errorMessage = 'Save failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadImages(),
            ),
          ),
        );
      }
      
      return [];
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  /// Remove selected image
  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Remove existing image
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: Text(
              AppStrings.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInDown(
                  child: _buildBasicInfoSection(),
                ),
                
                const SizedBox(height: AppSizes.p24),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 50),
                  child: _buildImageSection(),
                ),
                
                const SizedBox(height: AppSizes.p24),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildPricingSection(),
                ),
                
                const SizedBox(height: AppSizes.p24),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildInventorySection(),
                ),
                
                const SizedBox(height: AppSizes.p24),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildAvailabilitySection(),
                ),
                
                const SizedBox(height: AppSizes.p32),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: AppStrings.cancel,
                          type: ButtonType.outline,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSizes.p16),
                      Expanded(
                        child: CustomButton(
                          text: isEditing ? AppStrings.update : AppStrings.add,
                          onPressed: _saveProduct,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            
            CustomTextField(
              controller: _nameController,
              label: 'Product Name',
              hintText: 'Enter product name',
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSizes.p16),
            
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              hintText: 'Enter product description',
              maxLines: 4,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSizes.p16),
            
            // Category dropdown
            Text(
              'Category *',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProductCategory>(
                  isExpanded: true,
                  value: _selectedCategory,
                  items: ProductCategory.values.map((category) {
                    return DropdownMenuItem<ProductCategory>(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product Images',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isUploadingImages)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),
            
            // Existing images
            if (_existingImageUrls.isNotEmpty) ...[
              Text(
                'Current Images:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          AdaptiveImage(
                            imagePath: _existingImageUrls[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.p16),
            ],
            
            // New selected images
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'New Images:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeSelectedImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.p16),
            ],
            
            // Add images button
            OutlinedButton.icon(
              onPressed: _isUploadingImages ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            if (_existingImageUrls.isEmpty && _selectedImages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No images selected. Add some product images to make your listing more attractive.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _priceController,
                    label: 'Price (₵)',
                    hintText: '0.00',
                    keyboardType: TextInputType.number,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: CustomTextField(
                    controller: _discountController,
                    label: 'Discount (%)',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final discount = double.tryParse(value);
                        if (discount == null || discount < 0 || discount > 100) {
                          return 'Invalid discount';
                        }
                      }
                      return null;
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

  Widget _buildInventorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _stockController,
                    label: 'Stock Quantity',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Stock quantity is required';
                      }
                      final stock = int.tryParse(value);
                      if (stock == null || stock < 0) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: CustomTextField(
                    controller: _unitController,
                    label: 'Unit',
                    hintText: 'pieces',
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Unit is required';
                      }
                      return null;
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

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            
            SwitchListTile(
              title: const Text('Product Available'),
              subtitle: Text(
                _isAvailable 
                    ? 'Product is visible to customers'
                    : 'Product is hidden from customers',
              ),
              value: _isAvailable,
              onChanged: (value) {
                setState(() {
                  _isAvailable = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final productNotifier = ref.read(productProvider.notifier);
      
      // Parse form data
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final stockQuantity = int.parse(_stockController.text.trim());
      final unit = _unitController.text.trim();
      final discountText = _discountController.text.trim();
      final discount = discountText.isEmpty ? null : double.parse(discountText);
      
      // Upload new images if any
      List<String> newImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        newImageUrls = await _uploadImages();
      }
      
      // Combine existing and new image URLs
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];
      
      if (widget.product != null) {
        // Update existing product
        final updatedProduct = widget.product!.copyWith(
          name: name,
          description: description,
          price: price,
          category: _selectedCategory,
          stockQuantity: stockQuantity,
          unit: unit,
          isAvailable: _isAvailable,
          discountPercentage: discount,
          imageUrls: allImageUrls,
          updatedAt: DateTime.now(),
        );
        
        await productNotifier.updateProduct(updatedProduct);
      } else {
        // Create new product
        final newProduct = ProductModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          description: description,
          price: price,
          category: _selectedCategory,
          stockQuantity: stockQuantity,
          unit: unit,
          isAvailable: _isAvailable,
          discountPercentage: discount,
          imageUrls: allImageUrls,
          createdAt: DateTime.now(),
        );
        
        await productNotifier.addProduct(newProduct);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null 
                  ? 'Product updated successfully'
                  : 'Product added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 