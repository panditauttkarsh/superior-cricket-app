import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/shop_item_model.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  String _selectedCategory = 'All Items';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cartItems = [];
  List<ShopItemModel> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shopRepo = ref.read(shopRepositoryProvider);
      final products = await shopRepo.getShopItems(
        category: _selectedCategory == 'All Items' ? null : _getCategoryFromDisplay(_selectedCategory),
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String? _getCategoryFromDisplay(String displayCategory) {
    final categoryMap = {
      'All Items': null,
      '🏏 Bats': 'bat',
      '👕 Jerseys': 'apparel',
      '🛡️ Protection': 'protection',
      '👟 Shoes': 'shoes',
    };
    return categoryMap[displayCategory];
  }

  void _addToCart(ShopItemModel product) {
    final name = product.name;
    final price = '\$${product.discountPrice ?? product.price}';
    final category = product.category;
    final emoji = _getEmojiForCategory(category);
    setState(() {
      // Check if item already exists in cart
      final existingIndex = _cartItems.indexWhere((item) => item['name'] == name);
      if (existingIndex != -1) {
        // Increase quantity
        _cartItems[existingIndex]['quantity'] = (_cartItems[existingIndex]['quantity'] ?? 1) + 1;
      } else {
        // Add new item
        _cartItems.add({
          'name': name,
          'price': price,
          'category': category,
          'emoji': emoji,
          'quantity': 1,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart!'),
        backgroundColor: const Color(0xFF205A28),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF205A28),
              ),
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              icon: Icons.local_offer,
              title: 'Flash Sale Started!',
              message: 'Get 30% off on all cricket gear',
              time: '2h ago',
            ),
            _buildNotificationItem(
              icon: Icons.shopping_bag,
              title: 'New Arrivals',
              message: 'Check out our latest cricket bats',
              time: '5h ago',
            ),
            _buildNotificationItem(
              icon: Icons.payment,
              title: 'Order Confirmed',
              message: 'Your order #1234 has been confirmed',
              time: '1d ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String message,
    required String time,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF205A28).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF205A28), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(message),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showCart() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Color(0xFF205A28),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF205A28),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                item['emoji'] ?? '🏏',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['category'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['price'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF205A28),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: () {
                                            setState(() {
                                              if (item['quantity'] > 1) {
                                                item['quantity']--;
                                              } else {
                                                _cartItems.removeAt(index);
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          '${item['quantity'] ?? 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: () {
                                            setState(() {
                                              item['quantity'] = (item['quantity'] ?? 1) + 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
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
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF205A28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${_calculateTotal()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_cartItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your cart is empty'),
                              backgroundColor: Color(0xFF205A28),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _cartItems.clear();
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order placed successfully!'),
                            backgroundColor: Color(0xFF205A28),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF205A28),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      final priceStr = item['price']?.toString().replaceAll('\$', '') ?? '0';
      final price = double.tryParse(priceStr) ?? 0;
      final quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // background-light
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      // Banner Section
                      _buildBannerSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Categories Section
                      _buildCategoriesSection(),
                      
                      const SizedBox(height: 16),
                      
                      // Products Grid
                      _buildProductsGrid(),
                      
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      child: Column(
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo and Title
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF205A28), // primary
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF205A28).withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_cricket,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'CRICPLAY ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF205A28),
                            letterSpacing: 1,
                          ),
                        ),
                        TextSpan(
                          text: 'Store',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Notifications and Cart
              Row(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
                        onPressed: _showNotifications,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC72B32), // secondary
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.grey),
                        onPressed: _showCart,
                      ),
                      if (_cartItems.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC72B32),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '${_cartItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1))}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadProducts(),
              decoration: InputDecoration(
                hintText: 'Search bats, jerseys, gear...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.grey),
                  onPressed: () {},
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 220, // Increased from 200 to 220 to fix overflow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuC9hQ2mrMLAW43LzsFykS8qwBpC2TQ4vMv1eO_mjVu87Ywk8wtMT-ZbI6Xxcls8WTH5-r8m7V5nBTyjG_glldUf_OCz3j-CpxGjTkd9VjNAznx0o22Vyf2a5dpoZM35-U_I1YUFVIs4k8_RoXg1FYqOokjggFby7Y9zbKB-kV6UeyTTFeHJaRtPPQKMemaalyGX5fyIl97i6BgXlKSQ-9stwOIvLQahTz4_bdybB6hrWIzeM84KOShYN9y_od6oXUhwmZ9ruYzvryjh',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Reduced vertical padding slightly
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Added to prevent overflow
            children: [
              // FLASH SALE badge - red pill shape
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFC72B32),
                  borderRadius: BorderRadius.circular(20), // Pill shape
                ),
                child: const Text(
                  'FLASH SALE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10), // Reduced from 12
              // IPL SEASON - large white text
              const Text(
                'IPL SEASON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6), // Reduced from 8
              // Subtitle
              Text(
                'Get pro gear at 30% off',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12), // Reduced from 16
              // Shop Now button - green
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF205A28),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF205A28).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF205A28),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), // Reduced vertical padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = ['All Items', '🏏 Bats', '👕 Jerseys', '🛡️ Protection', '👟 Shoes'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF205A28),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = category);
                  _loadProducts();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFC72B32)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFC72B32).withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getEmojiForCategory(String category) {
    final emojiMap = {
      'bat': '🏏',
      'ball': '⚪',
      'apparel': '👕',
      'jersey': '👕',
      'protection': '🛡️',
      'helmet': '🛡️',
      'gloves': '🧤',
      'shoes': '👟',
    };
    return emojiMap[category.toLowerCase()] ?? '🏏';
  }

  Widget _buildProductsGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            color: Color(0xFF205A28),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading products',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF205A28),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCardFromModel(product);
        },
      ),
    );
  }

  Widget _buildProductCardFromModel(ShopItemModel product) {
    final hasDiscount = product.discountPrice != null;
    final discountPercent = hasDiscount
        ? ((product.price - product.discountPrice!) / product.price * 100).round()
        : null;

    return _buildProductCard(
      category: product.category.toUpperCase(),
      name: product.name,
      rating: product.rating ?? 0.0,
      reviews: product.reviewCount ?? 0,
      price: '\$${product.discountPrice ?? product.price}',
      emoji: _getEmojiForCategory(product.category),
      imageUrl: product.imageUrl,
      originalPrice: hasDiscount ? '\$${product.price}' : null,
      discount: discountPercent != null ? '-$discountPercent%' : null,
      isBall: product.category.toLowerCase() == 'ball',
      onAddToCart: () => _addToCart(product),
    );
  }

  Widget _buildProductCard({
    required String category,
    required String name,
    required double rating,
    required int reviews,
    required String price,
    required String emoji,
    String? imageUrl,
    String? originalPrice,
    String? discount,
    bool isBall = false,
    VoidCallback? onAddToCart,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  if (imageUrl != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  if (isBall)
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFC72B32),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (discount != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC72B32),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF205A28),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$rating ($reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (originalPrice != null)
                          Text(
                            originalPrice,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFC72B32),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF205A28),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF205A28).withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        onPressed: onAddToCart ?? () {
                          _addToCart(ShopItemModel(
                            id: '',
                            name: name,
                            price: double.parse(price.replaceAll('\$', '')),
                            category: category.toLowerCase(),
                            stock: 0,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ));
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(
            Icons.sports_cricket, 
            'My Cricket', 
            false, 
            () => context.go('/my-cricket'),
          ),
          _buildNavItem(
            Icons.storefront, 
            'Store', 
            true, // Always active when on store page
            () {},
            isStore: true,
          ),
          _buildNavItem(
            Icons.rss_feed, 
            'Feed', 
            currentLocation == '/feed', 
            () => context.go('/feed'),
          ),
          _buildNavItem(
            Icons.person, 
            'Profile', 
            currentLocation == '/profile', 
            () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap, {bool isGreen = false, bool isStore = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isStore && isActive
                ? const Color(0xFF205A28) // Dark green for store when active
                : isGreen 
                    ? const Color(0xFF00D26A) 
                    : (isActive ? const Color(0xFF205A28) : Colors.grey[400]),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isStore && isActive
                  ? const Color(0xFF205A28) // Dark green for store when active
                  : isGreen 
                      ? const Color(0xFF00D26A) 
                      : (isActive ? const Color(0xFF205A28) : Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}

