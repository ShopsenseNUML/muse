import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _savedProducts = [];
  List<Map<String, dynamic>> _searchHistory = [];

  // Mock product data with realistic images and categories
  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'Premium Cotton Kurta Shalwar',
      'price': 2499,
      'originalPrice': 3999,
      'category': 'Clothing',
      'source': 'Daraz',
      'rating': 4.5,
      'imageUrl':
          'https://trendia.co/cdn/shop/files/purple-premium-cotton-kurta-dupatta-pant-set-yufta-store-6417skdprm-5.webp?v=1747808907?w=400&h=500&fit=crop&crop=center',
      'description':
          'Premium cotton kurta shalwar with traditional embroidery. Perfect for casual and formal occasions.',
      'brand': 'Premium Wear',
      'fabric': 'Cotton',
      'color': 'White, Blue, Black',
      'size': 'S, M, L, XL, XXL',
      'occasion': 'Casual, Formal',
    },
    {
      'id': 2,
      'name': 'Sports Running Shoes',
      'price': 3999,
      'originalPrice': 5999,
      'category': 'Shoes',
      'source': 'Shoppers',
      'rating': 4.2,
      'imageUrl':
          'https://m.media-amazon.com/images/I/71dW7fT9DTL._AC_UY900_.jpg?w=400&h=500&fit=crop&crop=center',
      'description':
          'High-performance running shoes with cushioned sole and breathable mesh upper.',
      'brand': 'SportsPro',
      'fabric': 'Mesh & Synthetic',
      'color': 'Black, White, Red',
      'size': '6-12 US',
      'occasion': 'Sports, Casual',
    },
    {
      'id': 3,
      'name': 'Iphone 17 Pro Max',
      'price': 89999,
      'originalPrice': 99999,
      'category': 'Electronics',
      'source': 'AliExpress',
      'rating': 4.8,
      'imageUrl':
          'https://citymagazine.b-cdn.net/wp-content/uploads/2025/09/iPhone-17-Pro-Max-2025-02-1400x788.webp?w=400&h=500&fit=crop&crop=center',
      'description':
          'Latest flagship smartphone with 6.7" display, 108MP camera, and all-day battery life.',
      'brand': 'TechPro',
      'fabric': 'Glass & Aluminum',
      'color': 'Silver, Gold, Black',
      'size': '6.7 inch',
      'occasion': 'Everyday',
    },
    {
      'id': 4,
      'name': 'Designer Sunglasses',
      'price': 1499,
      'originalPrice': 2499,
      'category': 'Accessories',
      'source': 'Daraz',
      'rating': 4.0,
      'imageUrl':
          'https://www.pilgrim.net/cdn/shop/files/752010504_l1_638276715780000000.jpg?v=1719365234&width=1080f?w=400&h=500&fit=crop&crop=center',
      'description':
          'Trendy designer sunglasses with UV protection and stylish frames.',
      'brand': 'FashionEye',
      'fabric': 'Plastic & Metal',
      'color': 'Black, Brown, Tortoise',
      'size': 'One Size',
      'occasion': 'Casual, Travel',
    },
    {
      'id': 5,
      'name': 'Leather Handbag',
      'price': 4999,
      'originalPrice': 6999,
      'category': 'Bags',
      'source': 'Meesho',
      'rating': 4.3,
      'imageUrl':
          'https://aodour.pk/cdn/shop/files/1e1c1922-2ab2-41f3-8b78-e43390b0dad8.png?format=webp&v=1775866467&width=800?w=400&h=500&fit=crop&crop=center',
      'description':
          'Premium leather handbag with multiple compartments and adjustable straps.',
      'brand': 'LeatherCraft',
      'fabric': 'Genuine Leather',
      'color': 'Brown, Black, Tan',
      'size': 'Medium',
      'occasion': 'Formal, Casual',
    },
    {
      'id': 6,
      'name': 'Traditional Embroidered Dupatta',
      'price': 1299,
      'originalPrice': 1999,
      'category': 'Fashion',
      'source': 'Shoppers',
      'rating': 4.6,
      'imageUrl':
          'https://nishatlinen.com/cdn/shop/files/KFE26-192-_7_d95c5ecf-12ec-491f-9f53-7a2571a41bc5.jpg?v=1780658198&width=2400?w=400&h=500&fit=crop&crop=center',
      'description':
          'Beautiful embroidered dupatta with traditional patterns and vibrant colors.',
      'brand': 'Heritage',
      'fabric': 'Silk Blend',
      'color': 'Red, Blue, Green',
      'size': '2.5 meters',
      'occasion': 'Wedding, Festivals',
    },
    {
      'id': 7,
      'name': 'Leather Sandals',
      'price': 2199,
      'originalPrice': 2999,
      'category': 'Shoes',
      'source': 'Daraz',
      'rating': 4.1,
      'imageUrl':
          'https://starlet.pk/cdn/shop/files/p97.jpg?v=1772186670?w=400&h=500&fit=crop&crop=center',
      'description':
          'Comfortable leather sandals with soft cushioning and durable soles.',
      'brand': 'ComfortWalk',
      'fabric': 'Leather',
      'color': 'Brown, Black',
      'size': '7-11 US',
      'occasion': 'Casual, Summer',
    },
    {
      'id': 8,
      'name': 'Wireless Earbuds Pro',
      'price': 2999,
      'originalPrice': 4999,
      'category': 'Electronics',
      'source': 'AliExpress',
      'rating': 4.4,
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRVpOHPb8OvrhmhgPe5vc9hKsr-zPgvd8VXwpnsWI0baVVtW8M6p0ktkltL&s=10?w=400&h=500&fit=crop&crop=center',
      'description':
          'Premium wireless earbuds with noise cancellation and long battery life.',
      'brand': 'AudioTech',
      'fabric': 'Plastic & Silicone',
      'color': 'White, Black',
      'size': 'Standard',
      'occasion': 'Music, Calls',
    },
    {
      'id': 9,
      'name': 'Fashion Smart Watch',
      'price': 5499,
      'originalPrice': 7999,
      'category': 'Accessories',
      'source': 'Meesho',
      'rating': 4.7,
      'imageUrl':
          'https://i5.walmartimages.com/asr/a2697a6c-9bf7-4ae4-ae23-048b5690b961.c842b7878301cf001c115182dcad7115.jpeg?w=400&h=500&fit=crop&crop=center',
      'description':
          'Stylish smartwatch with fitness tracking, notifications, and customizable faces.',
      'brand': 'WearTech',
      'fabric': 'Stainless Steel & Silicone',
      'color': 'Silver, Gold, Black',
      'size': '42mm, 44mm',
      'occasion': 'Everyday, Fitness',
    },
    {
      'id': 10,
      'name': 'Travel Backpack',
      'price': 6999,
      'originalPrice': 8999,
      'category': 'Bags',
      'source': 'Shoppers',
      'rating': 4.5,
      'imageUrl':
          'https://mines.pk/cdn/shop/files/Voyuger_girls.jpg?v=1776870150&width=400&height=500&fit=crop&crop=center',
      'description':
          'Durable travel backpack with multiple compartments and padded straps.',
      'brand': 'TravelPro',
      'fabric': 'Nylon & Polyester',
      'color': 'Black, Blue, Gray',
      'size': '40L, 50L',
      'occasion': 'Travel, Hiking',
    },
    {
      'id': 11,
      'name': 'Cotton Casual Shirt',
      'price': 899,
      'originalPrice': 1299,
      'category': 'Clothing',
      'source': 'Daraz',
      'rating': 4.0,
      'imageUrl':
          'https://www.fairindigo.com/cdn/shop/files/BG_OF_04750_Iron_FW25_3950.jpg?v=1772308176&width=1946?w=400&h=500&fit=crop&crop=center',
      'description':
          'Lightweight cotton casual shirt perfect for everyday wear.',
      'brand': 'UrbanWear',
      'fabric': 'Cotton',
      'color': 'White, Blue, Pink',
      'size': 'S-XXL',
      'occasion': 'Casual, Office',
    },
    {
      'id': 12,
      'name': 'Gaming Laptop',
      'price': 129999,
      'originalPrice': 159999,
      'category': 'Electronics',
      'source': 'AliExpress',
      'rating': 4.9,
      'imageUrl':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRsfgVgnlaYUjLbhorLz4NU9-gTinKFnkGqJMWs1DL1RA&s=10?w=400&h=500&fit=crop&crop=center',
      'description':
          'High-performance gaming laptop with RTX graphics and fast refresh rate display.',
      'brand': 'GameTech',
      'fabric': 'Aluminum & Plastic',
      'color': 'Black, Silver',
      'size': '15.6 inch, 17.3 inch',
      'occasion': 'Gaming, Work',
    },
    {
      'id': 13,
      'name': 'Designer High Heels',
      'price': 4599,
      'originalPrice': 6499,
      'category': 'Shoes',
      'source': 'Meesho',
      'rating': 4.3,
      'imageUrl':
          'https://www.tedbaker.com/cdn/shop/files/PDP-WW-SS26-13.jpg?w=400&h=500&fit=crop&crop=center',
      'description':
          'Elegant designer high heels with comfortable padding and stylish design.',
      'brand': 'FashionHeel',
      'fabric': 'Leather & Synthetic',
      'color': 'Red, Black, Nude',
      'size': '5-10 US',
      'occasion': 'Formal, Parties',
    },
    {
      'id': 14,
      'name': 'Premium Wallet',
      'price': 799,
      'originalPrice': 1299,
      'category': 'Accessories',
      'source': 'Daraz',
      'rating': 4.2,
      'imageUrl':
          'https://images.unsplash.com/photo-1627123424574-724758594e93?w=400&h=500&fit=crop&crop=center',
      'description':
          'Genuine leather wallet with multiple card slots and coin compartment.',
      'brand': 'LeatherCraft',
      'fabric': 'Leather',
      'color': 'Brown, Black',
      'size': 'Standard',
      'occasion': 'Everyday',
    },
    {
      'id': 15,
      'name': 'Smart TV 55" 4K',
      'price': 64999,
      'originalPrice': 79999,
      'category': 'Electronics',
      'source': 'Shoppers',
      'rating': 4.6,
      'imageUrl':
          'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=400&h=500&fit=crop&crop=center',
      'description':
          '55 inch 4K Smart TV with HDR, built-in streaming apps, and voice control.',
      'brand': 'VisionTech',
      'fabric': 'Aluminum & Plastic',
      'color': 'Black',
      'size': '55 inch',
      'occasion': 'Entertainment',
    },
  ];

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get savedProducts => _savedProducts;
  List<Map<String, dynamic>> get searchHistory => _searchHistory;

  ProductProvider() {
    _loadData();
  }

  void _loadData() {
    // Load some saved products
    _savedProducts = [_products[0], _products[3], _products[5]];
  }

  bool isProductSaved(String productId) {
    return _savedProducts.any((p) => p['id'].toString() == productId);
  }

  void toggleSavedProduct(String productId, Map<String, dynamic> product) {
    if (isProductSaved(productId)) {
      _savedProducts.removeWhere((p) => p['id'].toString() == productId);
    } else {
      _savedProducts.add(product);
    }
    notifyListeners();
  }

  void addSearchHistory(String query) {
    _searchHistory.insert(0, {'query': query, 'timestamp': DateTime.now()});
    if (_searchHistory.length > 20) {
      _searchHistory.removeLast();
    }
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getProductsByCategory(String category) {
    if (category == 'All') {
      return _products;
    }
    return _products.where((p) => p['category'] == category).toList();
  }

  List<Map<String, dynamic>> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _products.where((product) {
      final name = product['name'].toLowerCase();
      final category = product['category'].toLowerCase();
      final brand = (product['brand'] ?? '').toLowerCase();
      return name.contains(lowerQuery) ||
          category.contains(lowerQuery) ||
          brand.contains(lowerQuery);
    }).toList();
  }

  Map<String, dynamic>? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p['id'].toString() == id);
    } catch (e) {
      return null;
    }
  }
}
