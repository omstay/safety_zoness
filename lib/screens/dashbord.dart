import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the models and config from the previous inventory management system
class BusinessConfig {
  static const String defaultBusinessId = 'default_business_001';

  static String getCurrentBusinessId() {
    return defaultBusinessId;
  }
}

class ItemMaster {
  final String id;
  final String businessId;
  final String itemCode;
  final String description;
  final String hsnSacCode;
  final String unitOfMeasurement;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cessRate;
  final double sellingPrice;
  final double costPrice;
  final double profitMargin;
  final bool isActive;
  final DateTime createdAt;

  ItemMaster({
    required this.id,
    required this.businessId,
    required this.itemCode,
    required this.description,
    required this.hsnSacCode,
    required this.unitOfMeasurement,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.cessRate,
    required this.sellingPrice,
    required this.costPrice,
    required this.profitMargin,
    required this.isActive,
    required this.createdAt,
  });

  factory ItemMaster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    final Map<String, dynamic> map = data as Map<String, dynamic>;

    return ItemMaster(
      id: doc.id,
      businessId: _getStringValue(map, 'businessId'),
      itemCode: _getStringValue(map, 'itemCode'),
      description: _getStringValue(map, 'description'),
      hsnSacCode: _getStringValue(map, 'hsnSacCode'),
      unitOfMeasurement: _getStringValue(map, 'unitOfMeasurement'),
      cgstRate: _getDoubleValue(map, 'cgstRate'),
      sgstRate: _getDoubleValue(map, 'sgstRate'),
      igstRate: _getDoubleValue(map, 'igstRate'),
      cessRate: _getDoubleValue(map, 'cessRate'),
      sellingPrice: _getDoubleValue(map, 'sellingPrice'),
      costPrice: _getDoubleValue(map, 'costPrice'),
      profitMargin: _getDoubleValue(map, 'profitMargin'),
      isActive: _getBoolValue(map, 'isActive'),
      createdAt: _getDateTimeValue(map, 'createdAt'),
    );
  }

  static String _getStringValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return '';
    return value.toString();
  }

  static double _getDoubleValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool _getBoolValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return true;
  }

  static DateTime _getDateTimeValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // Get total GST rate
  double get totalGstRate => cgstRate + sgstRate + igstRate + cessRate;

  // Get category based on HSN code (simplified logic)
  String get category {
    if (hsnSacCode.startsWith('84') || hsnSacCode.startsWith('85')) {
      return 'Electronics';
    } else if (hsnSacCode.startsWith('94')) {
      return 'Furniture';
    } else if (hsnSacCode.startsWith('48')) {
      return 'Stationery';
    }
    return 'General';
  }
}

class StockInventory {
  final String id;
  final String businessId;
  final String itemId;
  final String location;
  final double currentStock;
  final double minimumStockLevel;
  final DateTime lastUpdated;

  StockInventory({
    required this.id,
    required this.businessId,
    required this.itemId,
    required this.location,
    required this.currentStock,
    required this.minimumStockLevel,
    required this.lastUpdated,
  });

  factory StockInventory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    final Map<String, dynamic> map = data as Map<String, dynamic>;

    return StockInventory(
      id: doc.id,
      businessId: ItemMaster._getStringValue(map, 'businessId'),
      itemId: ItemMaster._getStringValue(map, 'itemId'),
      location: ItemMaster._getStringValue(map, 'location'),
      currentStock: ItemMaster._getDoubleValue(map, 'currentStock'),
      minimumStockLevel: ItemMaster._getDoubleValue(map, 'minimumStockLevel'),
      lastUpdated: ItemMaster._getDateTimeValue(map, 'lastUpdated'),
    );
  }

  bool get isLowStock => currentStock <= minimumStockLevel;
}

// Combined inventory item for dashboard display
class DashboardInventoryItem {
  final ItemMaster item;
  final StockInventory? stock;

  DashboardInventoryItem({
    required this.item,
    this.stock,
  });

  String get name => item.description.isNotEmpty ? item.description : 'Unnamed Item';
  String get hsnCode => item.hsnSacCode;
  double get gstRate => item.totalGstRate;
  double get unitPrice => item.sellingPrice;
  double get currentStock => stock?.currentStock ?? 0;
  bool get isLowStock => stock?.isLowStock ?? false;
  String get category => item.category;

  InventoryStatus get status => isLowStock ? InventoryStatus.lowStock : InventoryStatus.inStock;
}

enum InventoryStatus {
  lowStock,
  inStock,
}

class DashboardScreen extends StatefulWidget {
  final String? businessId;

  const DashboardScreen({super.key, this.businessId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _currentBusinessId;

  List<DashboardInventoryItem> _items = [];
  bool _isLoading = true;
  String _error = '';

  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Low Stock', 'In Stock', 'Electronics', 'Furniture', 'Stationery', 'General'];

  @override
  void initState() {
    super.initState();
    _currentBusinessId = widget.businessId ?? BusinessConfig.getCurrentBusinessId();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Load items and stock data
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('businessId', isEqualTo: _currentBusinessId)
          .where('isActive', isEqualTo: true)
          .get();

      final stockSnapshot = await _firestore
          .collection('stock_inventory')
          .where('businessId', isEqualTo: _currentBusinessId)
          .get();

      // Create maps for easier lookup
      final stockMap = <String, StockInventory>{};
      for (final doc in stockSnapshot.docs) {
        try {
          final stock = StockInventory.fromFirestore(doc);
          stockMap[stock.itemId] = stock;
        } catch (e) {
          print('Error parsing stock ${doc.id}: $e');
        }
      }

      // Combine items with their stock data
      final items = <DashboardInventoryItem>[];
      for (final doc in itemsSnapshot.docs) {
        try {
          final item = ItemMaster.fromFirestore(doc);
          final stock = stockMap[item.id];
          items.add(DashboardInventoryItem(item: item, stock: stock));
        } catch (e) {
          print('Error parsing item ${doc.id}: $e');
        }
      }

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<DashboardInventoryItem> get filteredItems {
    if (selectedFilter == 'All') return _items;
    if (selectedFilter == 'Low Stock') {
      return _items.where((item) => item.status == InventoryStatus.lowStock).toList();
    }
    if (selectedFilter == 'In Stock') {
      return _items.where((item) => item.status == InventoryStatus.inStock).toList();
    }
    return _items.where((item) => item.category == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInventoryData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final lowStockCount = _items.where((item) => item.status == InventoryStatus.lowStock).length;
    final totalValue = _items.fold<double>(0, (sum, item) => sum + (item.unitPrice * item.currentStock));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Modern App Bar
            _buildModernAppBar(),

            // Dashboard Stats
            _buildDashboardStats(lowStockCount, totalValue),

            // Filter Section
            _buildFilterSection(),

            // Inventory List
            Expanded(
              child: _buildInventoryList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 8,
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TaxEase GST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Sales',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _loadInventoryData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh Data',
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats(int lowStockCount, double totalValue) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Items',
              _items.length.toString(),
              Icons.inventory_2_outlined,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              lowStockCount.toString(),
              Icons.warning_outlined,
              const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Value',
              totalValue > 1000
                  ? '₹${(totalValue / 1000).toStringAsFixed(1)}K'
                  : '₹${totalValue.toStringAsFixed(0)}',
              Icons.currency_rupee_outlined,
              const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final option = filterOptions[index];
          final isSelected = selectedFilter == option;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = option;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF3B82F6),
              side: BorderSide(
                color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
              ),
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryList() {
    final items = filteredItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              selectedFilter == 'All' ? 'No items found' : 'No items match the selected filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedFilter == 'All'
                  ? 'Add your first item to get started'
                  : 'Try selecting a different filter',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildInventoryCard(item);
        },
      ),
    );
  }

  Widget _buildInventoryCard(DashboardInventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HSN: ${item.hsnCode.isNotEmpty ? item.hsnCode : 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status == InventoryStatus.lowStock
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status == InventoryStatus.lowStock ? 'Low Stock' : 'In Stock',
                  style: TextStyle(
                    color: item.status == InventoryStatus.lowStock
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip('Stock: ${item.currentStock.toStringAsFixed(0)}', Icons.inventory_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip('₹${item.unitPrice.toStringAsFixed(0)}', Icons.currency_rupee_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip('GST: ${item.gstRate.toStringAsFixed(1)}%', Icons.receipt_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showItemDetails(item),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRestockDialog(item),
                  icon: Icon(
                    item.status == InventoryStatus.lowStock
                        ? Icons.add_shopping_cart_outlined
                        : Icons.edit_outlined,
                    size: 16,
                  ),
                  label: Text(item.status == InventoryStatus.lowStock ? 'Restock' : 'Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.status == InventoryStatus.lowStock
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF6B7280),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final hsnController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final cgstController = TextEditingController();
    final sgstController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Add New Item',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hsnController,
                    decoration: const InputDecoration(
                      labelText: 'HSN Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cgstController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CGST %',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true) return 'Required';
                            if (double.tryParse(value!) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: sgstController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'SGST %',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true) return 'Required';
                            if (double.tryParse(value!) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty == true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Initial Stock',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty == true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _addNewItem(
                    nameController.text.trim(),
                    hsnController.text.trim(),
                    double.parse(cgstController.text),
                    double.parse(sgstController.text),
                    double.parse(priceController.text),
                    double.parse(stockController.text),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Item'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewItem(String name, String hsn, double cgst, double sgst, double price, double stock) async {
    try {
      // Add item to items collection
      final itemRef = await _firestore.collection('items').add({
        'businessId': _currentBusinessId,
        'itemCode': 'AUTO_${DateTime.now().millisecondsSinceEpoch}',
        'description': name,
        'hsnSacCode': hsn,
        'unitOfMeasurement': 'PCS',
        'cgstRate': cgst,
        'sgstRate': sgst,
        'igstRate': 0,
        'cessRate': 0,
        'sellingPrice': price,
        'costPrice': price * 0.8, // Assume 20% margin
        'profitMargin': 20,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add stock record
      await _firestore.collection('stock_inventory').add({
        'businessId': _currentBusinessId,
        'itemId': itemRef.id,
        'location': 'Main Warehouse',
        'currentStock': stock,
        'minimumStockLevel': stock * 0.2, // 20% of initial stock as minimum
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Reload data
      _loadInventoryData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showItemDetails(DashboardInventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Category', item.category),
            _buildDetailRow('HSN Code', item.hsnCode.isNotEmpty ? item.hsnCode : 'N/A'),
            _buildDetailRow('Item Code', item.item.itemCode.isNotEmpty ? item.item.itemCode : 'N/A'),
            _buildDetailRow('CGST Rate', '${item.item.cgstRate}%'),
            _buildDetailRow('SGST Rate', '${item.item.sgstRate}%'),
            _buildDetailRow('Total GST Rate', '${item.gstRate.toStringAsFixed(1)}%'),
            _buildDetailRow('Unit Price', '₹${item.unitPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Current Stock', '${item.currentStock.toStringAsFixed(1)} units'),
            _buildDetailRow('Total Value', '₹${(item.unitPrice * item.currentStock).toStringAsFixed(2)}'),
            if (item.stock != null) ...[
              _buildDetailRow('Location', item.stock!.location),
              _buildDetailRow('Min Stock Level', '${item.stock!.minimumStockLevel.toStringAsFixed(1)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(DashboardInventoryItem item) {
    final stockController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            item.status == InventoryStatus.lowStock ? 'Restock Item' : 'Update Stock',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Stock: ${item.currentStock.toStringAsFixed(1)} units'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: item.status == InventoryStatus.lowStock ? 'Add Quantity' : 'New Stock Level',
                    border: const OutlineInputBorder(),
                    helperText: item.status == InventoryStatus.lowStock
                        ? 'Enter quantity to add to current stock'
                        : 'Enter new total stock level',
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty == true) return 'Required';
                    final parsed = double.tryParse(value!);
                    if (parsed == null || parsed <= 0) return 'Must be positive number';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final quantity = double.parse(stockController.text);
                  await _updateStock(item, quantity, item.status == InventoryStatus.lowStock);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(item.status == InventoryStatus.lowStock ? 'Restock' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStock(DashboardInventoryItem item, double quantity, bool isAddition) async {
    try {
      if (item.stock == null) {
        // Create new stock record
        await _firestore.collection('stock_inventory').add({
          'businessId': _currentBusinessId,
          'itemId': item.item.id,
          'location': 'Main Warehouse',
          'currentStock': quantity,
          'minimumStockLevel': quantity * 0.2,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing stock record
        final newStock = isAddition ? item.currentStock + quantity : quantity;
        await _firestore.collection('stock_inventory').doc(item.stock!.id).update({
          'currentStock': newStock,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Reload data
      _loadInventoryData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}