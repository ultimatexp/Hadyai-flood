import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/store_product.dart';

/// Provider for store products
final storeProductsProvider = FutureProvider.autoDispose<List<StoreProduct>>((ref) async {
  final rows = await Supabase.instance.client
      .from('store_products')
      .select('*')
      .eq('in_stock', true)
      .order('created_at', ascending: false);

  return rows.map<StoreProduct>((r) => StoreProduct.fromJson(r)).toList();
});

/// Store screen for displaying products
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(storeProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ร้านค้า'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () { /* TODO: open cart */ },
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _CategoryChip(
                  label: 'ทั้งหมด',
                  emoji: '🛒',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...ProductCategory.values.map((category) => _CategoryChip(
                  label: category.thaiLabel,
                  emoji: category.emoji,
                  isSelected: _selectedCategory == category,
                  onTap: () => setState(() => _selectedCategory = category),
                )),
              ],
            ),
          ),

          // Products grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = _selectedCategory != null
                    ? products.where((p) => p.category == _selectedCategory).toList()
                    : products;

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _ProductCard(product: filtered[index]),
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: 4,
                itemBuilder: (context, index) => _ProductSkeleton(),
              ),
              error: (_, __) => Center(
                child: Text('ไม่สามารถโหลดสินค้า', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront, size: 48, color: Color(0xFF667eea)),
          ),
          const SizedBox(height: 16),
          Text(
            'เร็วๆ นี้!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'สินค้าสำหรับสัตว์เลี้ยงกำลังมา\nอาหาร • อุปกรณ์ • ของเล่น',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showProductDetail(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '฿${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: Colors.grey[100],
    child: Center(
      child: Text(product.category.emoji, style: const TextStyle(fontSize: 32)),
    ),
  );

  void _showProductDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                // Image
                if (product.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(product.imageUrl!, height: 250, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${product.category.emoji} ${product.category.thaiLabel}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF667eea)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '฿${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                      ),
                      if (product.description != null) ...[
                        const SizedBox(height: 16),
                        Text(product.description!, style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            // TODO: Add to cart / purchase
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('เร็วๆ นี้! ฟีเจอร์กำลังพัฒนา')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ซื้อสินค้า', style: TextStyle(fontSize: 16)),
                        ),
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
}

class _ProductSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 6),
                  Container(width: 80, height: 12, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                  const Spacer(),
                  Container(width: 60, height: 16, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
