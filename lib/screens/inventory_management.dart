import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Data Models with improved dynamic data handling
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

  // Helper methods for safe data extraction
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

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'itemCode': itemCode,
      'description': description,
      'hsnSacCode': hsnSacCode,
      'unitOfMeasurement': unitOfMeasurement,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'igstRate': igstRate,
      'cessRate': cessRate,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'profitMargin': profitMargin,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
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

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'itemId': itemId,
      'location': location,
      'currentStock': currentStock,
      'minimumStockLevel': minimumStockLevel,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

// Configuration class for business settings
class BusinessConfig {
  static const String defaultBusinessId = 'default_business_001'; // Set your default business ID here

  // You can modify this method to get business ID from SharedPreferences,
  // environment variables, or any other source
  static String getCurrentBusinessId() {
    return defaultBusinessId;
  }
}

// Add Stock Dialog Widget
class AddStockDialog extends StatefulWidget {
  final String businessId;

  const AddStockDialog({super.key, required this.businessId});

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String? _selectedItemId;
  final _locationController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minStockController = TextEditingController();

  List<ItemMaster> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('businessId', isEqualTo: widget.businessId)
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _items = snapshot.docs
            .map((doc) {
          try {
            return ItemMaster.fromFirestore(doc);
          } catch (e) {
            print('Error parsing item ${doc.id}: $e');
            return null;
          }
        })
            .where((item) => item != null)
            .cast<ItemMaster>()
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveStock() async {
    if (!_formKey.currentState!.validate() || _selectedItemId == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('stock_inventory').add({
        'businessId': widget.businessId,
        'itemId': _selectedItemId,
        'location': _locationController.text.trim(),
        'currentStock': double.parse(_currentStockController.text),
        'minimumStockLevel': double.parse(_minStockController.text),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  void dispose() {
    _locationController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Stock'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedItemId,
                decoration: const InputDecoration(
                  labelText: 'Select Item',
                  border: OutlineInputBorder(),
                ),
                items: _items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.description.isNotEmpty ? item.description : 'Unnamed Item',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItemId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Current Stock Field
              TextFormField(
                controller: _currentStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Stock',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter current stock';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Minimum Stock Level Field
              TextFormField(
                controller: _minStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Minimum Stock Level',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter minimum stock level';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveStock,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// Main Inventory Management Screen - No Authentication Required
class InventoryManagementScreen extends StatefulWidget {
  final String? businessId; // Optional parameter to override default

  const InventoryManagementScreen({super.key, this.businessId});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _currentBusinessId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Use provided businessId or get from config
    _currentBusinessId = widget.businessId ?? BusinessConfig.getCurrentBusinessId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Inventory Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF667eea),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667eea),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Items', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Stock', icon: Icon(Icons.storage)),
            Tab(text: 'Reports', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ItemsTab(businessId: _currentBusinessId),
          StockTab(businessId: _currentBusinessId),
          ReportsTab(businessId: _currentBusinessId),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddItemDialog(),
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            );
          } else if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddStockDialog(),
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Stock'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    final itemsTabState = context.findAncestorStateOfType<_ItemsTabState>();
    itemsTabState?._showAddItemDialog();
  }

  void _showAddStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(businessId: _currentBusinessId),
    );
  }
}

// Items Tab with improved error handling
class ItemsTab extends StatefulWidget {
  final String businessId;

  const ItemsTab({super.key, required this.businessId});

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search items...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Items List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('items')
                .where('businessId', isEqualTo: widget.businessId)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data!.docs
                  .map((doc) {
                try {
                  return ItemMaster.fromFirestore(doc);
                } catch (e) {
                  print('Error parsing item ${doc.id}: $e');
                  return null;
                }
              })
                  .where((item) => item != null)
                  .cast<ItemMaster>()
                  .where((item) =>
              _searchQuery.isEmpty ||
                  item.description.toLowerCase().contains(_searchQuery) ||
                  item.itemCode.toLowerCase().contains(_searchQuery))
                  .toList();

              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
            _searchQuery.isEmpty ? 'No items found' : 'No items match your search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first item to get started'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemMaster item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF667eea),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description.isNotEmpty ? item.description : 'Unnamed Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${item.itemCode.isNotEmpty ? item.itemCode : 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditItemDialog(item);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip('HSN: ${item.hsnSacCode.isNotEmpty ? item.hsnSacCode : 'N/A'}', Colors.blue),
                  const SizedBox(width: 8),
                  _buildInfoChip('Unit: ${item.unitOfMeasurement.isNotEmpty ? item.unitOfMeasurement : 'N/A'}', Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cost Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${item.costPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Selling Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${item.sellingPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Profit Margin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${item.profitMargin.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog(null);
  }

  void _showEditItemDialog(ItemMaster item) {
    _showItemDialog(item);
  }

  void _showItemDialog(ItemMaster? item) {
    final isEditing = item != null;
    final controllers = {
      'itemCode': TextEditingController(text: item?.itemCode ?? ''),
      'description': TextEditingController(text: item?.description ?? ''),
      'hsnSacCode': TextEditingController(text: item?.hsnSacCode ?? ''),
      'unitOfMeasurement': TextEditingController(text: item?.unitOfMeasurement ?? ''),
      'cgstRate': TextEditingController(text: item?.cgstRate.toString() ?? '0'),
      'sgstRate': TextEditingController(text: item?.sgstRate.toString() ?? '0'),
      'igstRate': TextEditingController(text: item?.igstRate.toString() ?? '0'),
      'cessRate': TextEditingController(text: item?.cessRate.toString() ?? '0'),
      'sellingPrice': TextEditingController(text: item?.sellingPrice.toString() ?? '0'),
      'costPrice': TextEditingController(text: item?.costPrice.toString() ?? '0'),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField('Item Code', controllers['itemCode']!),
              _buildDialogTextField('Description', controllers['description']!),
              _buildDialogTextField('HSN/SAC Code', controllers['hsnSacCode']!),
              _buildDialogTextField('Unit of Measurement', controllers['unitOfMeasurement']!),
              Row(
                children: [
                  Expanded(child: _buildDialogTextField('CGST Rate %', controllers['cgstRate']!, isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDialogTextField('SGST Rate %', controllers['sgstRate']!, isNumber: true)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildDialogTextField('IGST Rate %', controllers['igstRate']!, isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDialogTextField('Cess Rate %', controllers['cessRate']!, isNumber: true)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildDialogTextField('Cost Price', controllers['costPrice']!, isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDialogTextField('Selling Price', controllers['sellingPrice']!, isNumber: true)),
                ],
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
            onPressed: () => _saveItem(controllers, isEditing, item?.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Future<void> _saveItem(Map<String, TextEditingController> controllers, bool isEditing, String? itemId) async {
    try {
      final costPrice = double.tryParse(controllers['costPrice']!.text.trim()) ?? 0;
      final sellingPrice = double.tryParse(controllers['sellingPrice']!.text.trim()) ?? 0;
      final profitMargin = costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

      final itemData = {
        'businessId': widget.businessId,
        'itemCode': controllers['itemCode']!.text.trim(),
        'description': controllers['description']!.text.trim(),
        'hsnSacCode': controllers['hsnSacCode']!.text.trim(),
        'unitOfMeasurement': controllers['unitOfMeasurement']!.text.trim(),
        'cgstRate': double.tryParse(controllers['cgstRate']!.text.trim()) ?? 0,
        'sgstRate': double.tryParse(controllers['sgstRate']!.text.trim()) ?? 0,
        'igstRate': double.tryParse(controllers['igstRate']!.text.trim()) ?? 0,
        'cessRate': double.tryParse(controllers['cessRate']!.text.trim()) ?? 0,
        'sellingPrice': sellingPrice,
        'costPrice': costPrice,
        'profitMargin': profitMargin,
        'isActive': true,
        if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
      };

      if (isEditing && itemId != null) {
        await _firestore.collection('items').doc(itemId).update(itemData);
      } else {
        await _firestore.collection('items').add(itemData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Item updated successfully' : 'Item added successfully'),
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
    }
  }

  void _showItemDetails(ItemMaster item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.description.isNotEmpty ? item.description : 'Item Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Item Code', item.itemCode.isNotEmpty ? item.itemCode : 'N/A'),
            _buildDetailRow('HSN/SAC Code', item.hsnSacCode.isNotEmpty ? item.hsnSacCode : 'N/A'),
            _buildDetailRow('Unit', item.unitOfMeasurement.isNotEmpty ? item.unitOfMeasurement : 'N/A'),
            _buildDetailRow('CGST Rate', '${item.cgstRate}%'),
            _buildDetailRow('SGST Rate', '${item.sgstRate}%'),
            _buildDetailRow('IGST Rate', '${item.igstRate}%'),
            _buildDetailRow('Cost Price', '₹${item.costPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Selling Price', '₹${item.sellingPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Profit Margin', '${item.profitMargin.toStringAsFixed(2)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ItemMaster item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.description.isNotEmpty ? item.description : 'this item'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('items').doc(item.id).update({'isActive': false});
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
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
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Stock Tab with improved error handling
class StockTab extends StatefulWidget {
  final String businessId;

  const StockTab({super.key, required this.businessId});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('stock_inventory')
          .where('businessId', isEqualTo: widget.businessId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stocks = snapshot.data!.docs
            .map((doc) {
          try {
            return StockInventory.fromFirestore(doc);
          } catch (e) {
            print('Error parsing stock ${doc.id}: $e');
            return null;
          }
        })
            .where((stock) => stock != null)
            .cast<StockInventory>()
            .toList();

        if (stocks.isEmpty) {
          return _buildEmptyStockState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            return _buildStockCard(stocks[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyStockState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No stock records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stock levels will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(StockInventory stock) {
    final isLowStock = stock.currentStock <= stock.minimumStockLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLowStock ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storage,
                    color: isLowStock ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('items').doc(stock.itemId).get(),
                        builder: (context, itemSnapshot) {
                          if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
                            try {
                              final item = ItemMaster.fromFirestore(itemSnapshot.data!);
                              return Text(
                                item.description.isNotEmpty ? item.description : 'Unnamed Item',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            } catch (e) {
                              return const Text(
                                'Error loading item',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              );
                            }
                          }
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${stock.location.isNotEmpty ? stock.location : 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LOW STOCK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStockInfo('Current Stock', stock.currentStock.toStringAsFixed(1)),
                _buildStockInfo('Min Level', stock.minimumStockLevel.toStringAsFixed(1)),
                _buildStockInfo('Status', isLowStock ? 'Low' : 'Good'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatDate(stock.lastUpdated)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Reports Tab with placeholder functionality
class ReportsTab extends StatelessWidget {
  final String businessId;

  const ReportsTab({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildReportCard(
            'Stock Summary',
            'Overview of current stock levels',
            Icons.analytics,
            const Color(0xFF4CAF50),
                () => _showStockSummaryReport(context),
          ),
          _buildReportCard(
            'Low Stock Alert',
            'Items running low on stock',
            Icons.warning,
            const Color(0xFFFF9800),
                () => _showLowStockReport(context),
          ),
          _buildReportCard(
            'Stock Movement',
            'Track stock in and out movements',
            Icons.swap_horiz,
            const Color(0xFF2196F3),
                () => _showStockMovementReport(context),
          ),
          _buildReportCard(
            'Valuation Report',
            'Total inventory valuation',
            Icons.account_balance,
            const Color(0xFF9C27B0),
                () => _showValuationReport(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showStockSummaryReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Summary Report'),
        content: const Text('This feature will show a comprehensive overview of all stock levels across different locations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLowStockReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Stock Alert Report'),
        content: const Text('This feature will display all items that are currently below their minimum stock levels.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStockMovementReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Movement Report'),
        content: const Text('This feature will track all stock movements including purchases, sales, and transfers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showValuationReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valuation Report'),
        content: const Text('This feature will calculate the total value of your inventory based on cost prices and current stock levels.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}