import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/cart_service.dart';

class CartFloatingBar extends StatelessWidget {
  const CartFloatingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        if (cart.itemCount == 0) return const SizedBox.shrink();

        // Get up to 3 images from cart items
        final items = cart.items.values.toList();
        final images = items
            .where((item) => item.imageUrl != null)
            .map((item) => item.imageUrl!)
            .take(3)
            .toList();

        return Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Overlapping Images
                  SizedBox(
                    width: 28.0 + (images.length > 1 ? (images.length - 1) * 14.0 : 0),
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: List.generate(images.length, (index) {
                        return Positioned(
                          left: index * 14.0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.black87, width: 1.5),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.medication, size: 16, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${cart.itemCount} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F2147),
                        ),
                      ),
                      const Text(
                        'View cart',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Cart Icon Button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F2147),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
