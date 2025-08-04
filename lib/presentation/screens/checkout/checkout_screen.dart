import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../utils/extensions.dart';
import '../../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';

/// Provider for shipping fee calculation
final shippingFeeProvider = StateProvider<double>((ref) => 10.0);

/// Provider for tax calculation (as a percentage)
final taxRateProvider = StateProvider<double>((ref) => 5.0);

/// A production-grade checkout screen that allows users to complete their order
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.mobileMoney;
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Place the order using the current cart and form data
  Future<void> _placeOrder() async {
    if (_formKey.currentState?.validate() != true) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final cart = ref.read(cartProvider);
      if (cart.isEmpty) {
        context.showErrorSnackBar('Your cart is empty');
        setState(() => _isProcessing = false);
        return;
      }

      final user = ref.read(currentUserProvider);
      if (user == null) {
        context.showErrorSnackBar('Please log in to place an order');
        setState(() => _isProcessing = false);
        return;
      }

      // Calculate fees
      final subtotal = cart.totalAmount;
      final shippingFee = ref.read(shippingFeeProvider);
      final taxRate = ref.read(taxRateProvider);
      final taxAmount = subtotal * (taxRate / 100);
      
      // Create a unique order ID
      final orderId = const Uuid().v4();
      
      // Create the order
      final order = OrderModel.fromCart(
        id: orderId,
        cart: cart,
        paymentMethod: _selectedPaymentMethod,
        deliveryAddress: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        shippingFee: shippingFee,
        tax: taxAmount,
      );

      // Save order to Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(order.toMap());
      
      // Clear cart after successful order
      await ref.read(cartProvider.notifier).clearCart();

      // Show success message and navigate
      if (!mounted) return;
      
      setState(() => _isProcessing = false);
      _showOrderSuccessDialog(orderId);
    } catch (e) {
      setState(() => _isProcessing = false);
      context.showErrorSnackBar('Failed to place order: ${e.toString()}');
    }
  }

  /// Show a success dialog after order placement
  void _showOrderSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text('Your order #${orderId.substring(0, 8)} has been placed!'),
            const SizedBox(height: 8),
            const Text(
              'You can track your order in the Order History section.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            onPressed: () {
              GoRouter.of(context).go('/orders');
            },
            text: 'View Order History',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final cartIsEmpty = ref.watch(cartIsEmptyProvider);

    if (cartIsEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
        ),
        body: EmptyState(
          lottieAsset: 'assets/animations/empty_cart.json',
          title: 'Your cart is empty',
          message: 'Add some products to your cart to checkout.',
          buttonLabel: 'Shop Now',
          onButtonPressed: () => GoRouter.of(context).go('/products'),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isProcessing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(),
                const SizedBox(height: AppSizes.p24),
                _buildDeliverySection(),
                const SizedBox(height: AppSizes.p24),
                _buildPaymentMethodSection(),
                const SizedBox(height: AppSizes.p24),
                _buildTotalSection(),
                const SizedBox(height: AppSizes.p24),
                SafeArea(
                  child: CustomButton(
                    onPressed: _placeOrder,
                    text: 'Place Order',
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the order summary section with cart items
  Widget _buildOrderSummary() {
    final cart = ref.watch(cartProvider);
    
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${cart.totalItems} ${cart.totalItems == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Divider(),
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.productImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppStrings.currencySymbol}${item.productPrice.toStringAsFixed(2)} × ${item.quantity}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    // Item total
                    Text(
                      '${AppStrings.currencySymbol}${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the delivery address section
  Widget _buildDeliverySection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'Full Address',
                hint: 'Enter your full delivery address',
                maxLines: 3,
                validator: Validators.required('Address is required'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'Delivery Notes (Optional)',
                hint: 'Special instructions for delivery',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the payment method section
  Widget _buildPaymentMethodSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                title: 'Mobile Money',
                subtitle: 'Pay via mobile money transfer',
                icon: Icons.phone_android,
                value: PaymentMethod.mobileMoney,
              ),
              _buildPaymentOption(
                title: 'Bank Transfer',
                subtitle: 'Pay via bank transfer',
                icon: Icons.account_balance,
                value: PaymentMethod.bankTransfer,
              ),
              _buildPaymentOption(
                title: 'Cash on Delivery',
                subtitle: 'Pay when your order is delivered',
                icon: Icons.payments_outlined,
                value: PaymentMethod.cashOnDelivery,
              ),
              _buildPaymentOption(
                title: 'Card Payment',
                subtitle: 'Pay with credit or debit card',
                icon: Icons.credit_card,
                value: PaymentMethod.card,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single payment option
  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required PaymentMethod value,
  }) {
    return RadioListTile<PaymentMethod>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _selectedPaymentMethod = newValue);
        }
      },
    );
  }

  /// Build the order total section
  Widget _buildTotalSection() {
    final cart = ref.watch(cartProvider);
    final shippingFee = ref.watch(shippingFeeProvider);
    final taxRate = ref.watch(taxRateProvider);
    final subtotal = cart.totalAmount;
    final taxAmount = subtotal * (taxRate / 100);
    final total = subtotal + shippingFee + taxAmount;

    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTotalRow(
                'Subtotal',
                '${AppStrings.currencySymbol}${subtotal.toStringAsFixed(2)}',
              ),
              _buildTotalRow(
                'Shipping',
                '${AppStrings.currencySymbol}${shippingFee.toStringAsFixed(2)}',
              ),
              _buildTotalRow(
                'Tax (${taxRate.toStringAsFixed(0)}%)',
                '${AppStrings.currencySymbol}${taxAmount.toStringAsFixed(2)}',
              ),
              const Divider(thickness: 1),
              _buildTotalRow(
                'Total',
                '${AppStrings.currencySymbol}${total.toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single row in the total section
  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}