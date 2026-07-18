import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F2147),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<CartService>(
          builder: (context, cart, child) {
            return Text(
              'My Cart (${cart.itemCount} Item${cart.itemCount > 1 ? 's' : ''})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            );
          },
        ),
        actions: const [
          Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF0F2147), size: 16),
              SizedBox(width: 4),
              Text(
                'Secure',
                style: TextStyle(color: Color(0xFF0F2147), fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: Consumer<CartService>(
        builder: (context, cart, child) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F2147)));
          }
          if (cart.itemCount == 0) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDeliveryBanner(),
                      _buildCartItems(cart),
                      _buildCouponSection(),
                      _buildOrderSummary(cart),
                      _buildPaymentMethodHint(),
                    ],
                  ),
                ),
              ),
              _buildStickyBottomBar(context, cart),
            ],
          );
        },
      )),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2147), 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Color(0xFF0F2147), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('We deliver within 8 hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F2147))),
                SizedBox(height: 2),
                Text('Payment only via Cash on Delivery', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF0F2147), borderRadius: BorderRadius.circular(20)),
            child: const Text('WITHIN 8 HOURS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartService cart) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cart.items.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
        itemBuilder: (context, index) {
          final item = cart.items.values.toList()[index];
          final discount = item.discountPercentage ?? 0;
          final original = item.originalPrice ?? item.price;
          
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item.imageUrl!, fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.medication, color: Colors.grey, size: 40)),
                        )
                      : const Icon(Icons.medication, color: Colors.grey, size: 40),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2147)),
                            ),
                          ),
                          InkWell(
                            onTap: () => cart.removeItem(item.medicineId),
                            child: Icon(Icons.delete_outline, size: 20, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item.variant ?? 'Standard Variant', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      const SizedBox(height: 8),
                      if (discount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2147),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${discount.toInt()}% OFF', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                if (original > item.price) ...[
                                  const SizedBox(width: 4),
                                  Text('₹${original.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[400], fontSize: 11, decoration: TextDecoration.lineThrough)),
                                ],
                              ],
                            ),
                          ),
                          // Quantity Controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => cart.updateQuantity(item.medicineId, item.quantity - 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Text('−', style: TextStyle(color: Color(0xFF0F2147), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  alignment: Alignment.center,
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                InkWell(
                                  onTap: () => cart.updateQuantity(item.medicineId, item.quantity + 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Text('+', style: TextStyle(color: Color(0xFF0F2147), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2147))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer, color: Color(0xFF0F2147), size: 16),
              SizedBox(width: 6),
              Text('Apply Coupon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F2147))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2147),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartService cart) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2147))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Total (${cart.itemCount} Items)', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Delivery Charge', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹0.00', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 12)),
                  const Text('(Free Delivery)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2147))),
              Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2147))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodHint() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF0F2147), shape: BoxShape.circle),
            child: const Icon(Icons.money, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Method: Cash on Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F2147))),
                SizedBox(height: 2),
                Text('You will pay in cash when your order is delivered.', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, CartService cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total Payable', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2147))),
                const Text('(Inclusive of all taxes)', style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2147),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                children: [
                  Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
