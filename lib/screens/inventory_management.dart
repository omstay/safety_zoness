import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Added for DateFormat
import 'package:safetyzoness/screens/pdf_utils.dart';
import 'package:safetyzoness/screens/report/sales_by_hsn_report_screen.dart';
import '../model/SaleMaster.dart'; // Import the updated SaleMaster and SaleItem
import 'add_edit_sale_screen.dart'; // Import the new AddEditSaleScreen
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth

// Data Models with improved dynamic data handling
class ItemMaster {
  final String id;
  final String userId;
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
    required this.userId,
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
      userId: getStringValue(map, 'userId'),
      itemCode: getStringValue(map, 'itemCode'),
      description: getStringValue(map, 'description'),
      hsnSacCode: getStringValue(map, 'hsnSacCode'),
      unitOfMeasurement: getStringValue(map, 'unitOfMeasurement'),
      cgstRate: getDoubleValue(map, 'cgstRate'),
      sgstRate: getDoubleValue(map, 'sgstRate'),
      igstRate: getDoubleValue(map, 'igstRate'),
      cessRate: getDoubleValue(map, 'cessRate'),
      sellingPrice: getDoubleValue(map, 'sellingPrice'),
      costPrice: getDoubleValue(map, 'costPrice'),
      profitMargin: getDoubleValue(map, 'profitMargin'),
      isActive: getBoolValue(map, 'isActive'),
      createdAt: getDateTimeValue(map, 'createdAt'),
    );
  }

  // Helper methods for safe data extraction (made public for external access)
  static String getStringValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return '';
    return value.toString();
  }

  static double getDoubleValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool getBoolValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return true;
  }

  static DateTime getDateTimeValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
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
  final String userId;
  final String itemId;
  final String location;
  final double currentStock;
  final double minimumStockLevel;
  final DateTime lastUpdated;

  StockInventory({
    required this.id,
    required this.userId,
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
      userId: ItemMaster.getStringValue(map, 'userId'),
      itemId: ItemMaster.getStringValue(map, 'itemId'),
      location: ItemMaster.getStringValue(map, 'location'),
      currentStock: ItemMaster.getDoubleValue(map, 'currentStock'),
      minimumStockLevel: ItemMaster.getDoubleValue(map, 'minimumStockLevel'),
      lastUpdated: ItemMaster.getDateTimeValue(map, 'lastUpdated'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
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
  static const String defaultuserId = 'default_business_001'; // Set your default business ID here

  // You can modify this method to get business ID from SharedPreferences,
  // environment variables, or any other source
  static String getCurrentuserId() {
    return defaultuserId;
  }
}

// Add Stock Dialog Widget
class AddStockDialog extends StatefulWidget {
  final String userId; // Change from userId to userId
  const AddStockDialog({super.key, required this.userId});

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
          .where('userId', isEqualTo: widget.userId) // Change from userId to userId
          .where('isActive', isEqualTo: true)
          .get();
      setState(() {
        _items = snapshot.docs
            .map((doc) {
          try {
            return ItemMaster.fromFirestore(doc);
          } catch (e) {
            debugPrint('Error parsing item ${doc.id}: $e'); // Debug print
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
      debugPrint('Error loading items: $e'); // Debug print
    }
  }

  Future<void> _saveStock() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('AddStockDialog: Form validation failed.'); // Debug print
      return;
    }
    if (_selectedItemId == null) {
      debugPrint('AddStockDialog: No item selected.'); // Debug print
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('stock_inventory').add({
        'userId': widget.userId, // Change from userId to userId
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
      debugPrint('Stock added successfully for item ID: $_selectedItemId'); // Debug print
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error saving stock: $e'); // Debug print
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
                  filled: true,
                  fillColor: Colors.white,
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
                  filled: true,
                  fillColor: Colors.white,
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
                  filled: true,
                  fillColor: Colors.white,
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
                  filled: true,
                  fillColor: Colors.white,
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
  final String? userId; // Changed from userId to userId
  const InventoryManagementScreen({super.key, this.userId});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Added Firebase Auth instance
  late String _currentUserId;

  // GlobalKeys to access child tab states
  final GlobalKey<_SalesTabState> _salesTabKey = GlobalKey<_SalesTabState>();
  final GlobalKey<_ItemsTabState> _itemsTabKey = GlobalKey<_ItemsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = widget.userId ?? _auth.currentUser?.uid ?? '';

    if (_currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Inventory', // Updated title to reflect user-specific data
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF667eea),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667eea),
          indicatorWeight: 4,
          tabs: const [
            Tab(text: 'Sales', icon: Icon(Icons.monetization_on_rounded)),
            Tab(text: 'Items', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Stock', icon: Icon(Icons.storage)),
            Tab(text: 'Reports', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SalesTab(key: _salesTabKey, userId: _currentUserId), // Pass userId instead of userId
          ItemsTab(key: _itemsTabKey, userId: _currentUserId), // Pass userId instead of userId
          StockTab(userId: _currentUserId), // Pass userId instead of userId
          ReportsTab(userId: _currentUserId), // Pass userId instead of userId
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index == 0) { // Sales Tab
            return FloatingActionButton.extended(
              onPressed: () {
                _salesTabKey.currentState?.showAddSaleDialog();
              },
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add New Sale'),
            );
          } else if (_tabController.index == 1) { // Items Tab
            return FloatingActionButton.extended(
              onPressed: () {
                _itemsTabKey.currentState?.showAddItemDialog();
              },
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            );
          } else if (_tabController.index == 2) { // Stock Tab
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

  // This method is now only for Stock, as Sales and Items are handled by GlobalKeys
  void _showAddStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(userId: _currentUserId),
    );
  }
}

// Items Tab with improved error handling
class ItemsTab extends StatefulWidget {
  final String userId; // Changed from userId to userId
  const ItemsTab({super.key, required this.userId});

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Made public for access from parent widget
  void showAddItemDialog() {
    _showItemDialog(null);
  }

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
            stream: _firestore.collection('items')
                .where('userId', isEqualTo: widget.userId)
                .where('isActive', isEqualTo: true)
                .snapshots(), // Corrected collection to 'items'
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('ItemsTab StreamBuilder Error: ${snapshot.error}'); // Debug print
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
                  debugPrint('Error parsing item ${doc.id}: $e'); // Debug print
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
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton.extended(
              heroTag: 'generate_items_report',
              label: const Text('Generate My Items Report'), // Updated label
              icon: const Icon(Icons.document_scanner),
              backgroundColor: Colors.blue,
              onPressed: () async {
                try {
                  final snapshot = await _firestore
                      .collection('items')
                      .where('userId', isEqualTo: widget.userId)
                      .where('isActive', isEqualTo: true)
                      .get();
                  final items = snapshot.docs
                      .map((doc) => ItemMaster.fromFirestore(doc))
                      .toList();
                  if (items.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No items to export.'), backgroundColor: Colors.orange),
                      );
                    }
                    return;
                  }
                  // Show options to download, share, or print
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return SafeArea(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.download),
                              title: const Text('Download PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.generateAndDownloadAllItemsPDF(items);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('All Items Report PDF downloaded!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text('Share PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.shareAllItemsPDF(items);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('All Items Report PDF shared!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.print),
                              title: const Text('Print PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.printAllItemsPDF(items);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('All Items Report PDF sent to printer!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error generating items report: $e'), backgroundColor: Colors.red),
                    );
                  }
                  debugPrint('Error generating all items report: $e');
                }
              },
            ),
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
              onPressed: () => showAddItemDialog(), // Call public method
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
        border: Border.all(color: Colors.grey.shade200, width: 1), // Added border
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

  void _showEditItemDialog(ItemMaster item) {
    _showItemDialog(item);
  }

  void _showItemDialog(ItemMaster? item) {
    final isEditing = item != null;
    final _dialogFormKey = GlobalKey<FormState>(); // New form key for the dialog
    final controllers = {
      'itemCode': TextEditingController(text: item?.itemCode ?? ''),
      'description': TextEditingController(text: item?.description ?? ''),
      'hsnSacCode': TextEditingController(text: item?.hsnSacCode ?? ''),
      'unitOfMeasurement': TextEditingController(text: item?.unitOfMeasurement ?? ''),
      'cgstRate': TextEditingController(text: item?.cgstRate.toString() ?? '0.0'),
      'sgstRate': TextEditingController(text: item?.sgstRate.toString() ?? '0.0'),
      'igstRate': TextEditingController(text: item?.igstRate.toString() ?? '0.0'),
      'cessRate': TextEditingController(text: item?.cessRate.toString() ?? '0.0'),
      'sellingPrice': TextEditingController(text: item?.sellingPrice.toString() ?? '0.0'),
      'costPrice': TextEditingController(text: item?.costPrice.toString() ?? '0.0'),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
        content: Form( // Wrap content in a Form
          key: _dialogFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField('Item Code', controllers['itemCode']!, validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Item Code is required';
                  return null;
                }),
                _buildDialogTextField('Description', controllers['description']!, validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Description is required';
                  return null;
                }),
                _buildDialogTextField('HSN/SAC Code', controllers['hsnSacCode']!),
                _buildDialogTextField('Unit of Measurement', controllers['unitOfMeasurement']!),
                Row(
                  children: [
                    Expanded(child: _buildDialogTextField('CGST Rate %', controllers['cgstRate']!, isNumber: true, validator: (value) {
                      if (double.tryParse(value ?? '') == null) return 'Valid number required';
                      return null;
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDialogTextField('SGST Rate %', controllers['sgstRate']!, isNumber: true, validator: (value) {
                      if (double.tryParse(value ?? '') == null) return 'Valid number required';
                      return null;
                    })),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildDialogTextField('IGST Rate %', controllers['igstRate']!, isNumber: true, validator: (value) {
                      if (double.tryParse(value ?? '') == null) return 'Valid number required';
                      return null;
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDialogTextField('Cess Rate %', controllers['cessRate']!, isNumber: true, validator: (value) {
                      if (double.tryParse(value ?? '') == null) return 'Valid number required';
                      return null;
                    })),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildDialogTextField('Cost Price', controllers['costPrice']!, isNumber: true, validator: (value) {
                      if (double.tryParse(value ?? '') == null) return 'Valid number required';
                      return null;
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDialogTextField('Selling Price', controllers['sellingPrice']!, isNumber: true, validator: (value) {
                      if (double.tryParse(value ?? '') == null) return 'Valid number required';
                      return null;
                    })),
                  ],
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
            onPressed: () {
              if (_dialogFormKey.currentState!.validate()) { // Validate before saving
                _saveItem(controllers, isEditing, item?.id);
              } else {
                debugPrint('Add/Edit Item Dialog: Form validation failed.'); // Debug print
              }
            },
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

  Widget _buildDialogTextField(String label, TextEditingController controller, {bool isNumber = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField( // Changed to TextFormField for validation
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true, // Added filled property
          fillColor: Colors.white, // Added fill color
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _saveItem(Map<String, TextEditingController> controllers, bool isEditing, String? itemId) async {
    try {
      final costPrice = double.tryParse(controllers['costPrice']!.text.trim()) ?? 0;
      final sellingPrice = double.tryParse(controllers['sellingPrice']!.text.trim()) ?? 0;
      final profitMargin = costPrice > 0 ? ((sellingPrice - costPrice) / costPrice) * 100 : 0;

      final itemData = {
        'userId': widget.userId, // Use userId instead of userId
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
        debugPrint('Item updated successfully: $itemId'); // Debug print
      } else {
        final docRef = await _firestore.collection('items').add(itemData);
        debugPrint('Item added successfully with ID: ${docRef.id}'); // Debug print
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
      debugPrint('Error saving item: $e'); // Debug print
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
                debugPrint('Item deleted successfully: ${item.id}'); // Debug print
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                debugPrint('Error deleting item: $e'); // Debug print
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

class SalesTab extends StatefulWidget {
  final String userId;
  const SalesTab({super.key, required this.userId});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar (same as before)
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search sales by customer...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        // FIXED Sales List - Removed orderBy to avoid index requirement
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('sales')
                .where('userId', isEqualTo: widget.userId)
            // REMOVED: .orderBy('date', descending: true) - This was causing the index error
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('SalesTab StreamBuilder Error: ${snapshot.error}');
                return const Center(child: Text("Error loading sales"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final sales = snapshot.data!.docs
                  .map((doc) {
                try {
                  return SaleMaster.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Error parsing sale: $e');
                  return null;
                }
              })
                  .where((sale) => sale != null)
                  .cast<SaleMaster>()
                  .where((sale) => _searchQuery.isEmpty || sale.customerName.toLowerCase().contains(_searchQuery))
                  .toList();

              // MANUAL SORTING: Sort by date in Dart since we can't use orderBy in Firestore
              sales.sort((a, b) => b.date.compareTo(a.date)); // Sort descending by date

              if (sales.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  return _buildSaleCard(sales[index]);
                },
              );
            },
          ),
        ),
        // Report generation button - Also remove orderBy here
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton.extended(
              heroTag: 'generate_sales_report',
              label: const Text('Generate My Sales Report'),
              icon: const Icon(Icons.document_scanner),
              backgroundColor: Colors.blue,
              onPressed: () async {
                try {
                  final snapshot = await _firestore
                      .collection('sales')
                      .where('userId', isEqualTo: widget.userId)
                  // REMOVED: .orderBy('date', descending: true) - Avoid index requirement
                      .get();

                  final sales = snapshot.docs
                      .map((doc) => SaleMaster.fromFirestore(doc))
                      .toList();

                  // MANUAL SORTING: Sort by date in Dart
                  sales.sort((a, b) => b.date.compareTo(a.date));

                  if (sales.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No sales data to export.'), backgroundColor: Colors.orange),
                      );
                    }
                    return;
                  }

                  // Rest of the method remains the same...
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return SafeArea(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.download),
                              title: const Text('Download PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.generateAndDownloadAllSalesPDF(sales);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('My Sales Report PDF downloaded!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text('Share PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.shareAllSalesPDF(sales);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('My Sales Report PDF shared!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.print),
                              title: const Text('Print PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.printAllSalesPDF(sales);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('My Sales Report PDF sent to printer!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error generating sales report: $e'), backgroundColor: Colors.red),
                    );
                  }
                  debugPrint('Error generating all sales report: $e');
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void showAddSaleDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSaleScreen(userId: widget.userId), // Pass userId instead of businessId
      ),
    );
  }

// And update the edit sale dialog method
  void _showEditSaleDialog(SaleMaster sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSaleScreen(
          userId: widget.userId, // Pass userId instead of businessId
          saleId: sale.id,
          saleDoc: null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No sales yet' : 'No matching sales',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: showAddSaleDialog, // Call public method
            icon: const Icon(Icons.add),
            label: const Text('Add Sale'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SaleMaster sale) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sale.customerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${sale.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Invoice #: ${sale.invoice}'),
            Text('Date: ${DateFormat('dd MMM yyyy').format(sale.date)}'),
            const SizedBox(height: 12),
            // Display items in sale
            if (sale.items.isNotEmpty) ...[
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Use a DataTable or similar for items, matching the screenshot format
              Container( // Added Container for styling the table
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect( // Clip content to rounded corners
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge, // Ensure clipping
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64), // Adjust width as needed
                      child: DataTable(
                        columnSpacing: 12,
                        horizontalMargin: 12, // Adjusted margin
                        headingRowColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF667eea).withOpacity(0.1)), // Light primary color
                        dataRowColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                          }
                          return null; // Use default for other states
                        }),
                        decoration: BoxDecoration( // Added decoration for inner table border
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        columns: [
                          DataColumn(label: Text('Sr No.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('UQC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Taxable Value (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Rate (%)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('IGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('CGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('SGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Cess (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        ],
                        rows: List<DataRow>.generate(
                          sale.items.length,
                              (index) {
                            final item = sale.items[index];
                            final totalTaxRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);
                            return DataRow(
                              cells: [
                                DataCell(Text((index + 1).toString(), style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.hsnSacCode, style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.description, style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.unitOfMeasurement, style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.quantity.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.totalTaxableValue.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text('${totalTaxRate.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.integratedTaxAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.centralTaxAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.stateTaxAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.cessAmount.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade800))),
                                DataCell(Text(item.itemTotal.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _generatePDF(sale),
                  tooltip: 'Download PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () => _shareSale(sale),
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.black),
                  onPressed: () => _printSale(sale),
                  tooltip: 'Print',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditSaleDialog(sale),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteSale(sale.id),
                  tooltip: 'Delete',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }



  Future<void> _deleteSale(String saleId) async {
    try {
      await _firestore.collection('sales').doc(saleId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale deleted'), backgroundColor: Colors.green),
      );
      debugPrint('Sale deleted successfully: $saleId'); // Debug print
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      debugPrint('Error deleting sale: $e'); // Debug print
    }
  }

  Future<void> _generatePDF(SaleMaster sale) async {
    await PDFUtils.generateAndDownloadPDF(sale);
  }

  Future<void> _shareSale(SaleMaster sale) async {
    await PDFUtils.shareSalePDF(sale);
  }

  Future<void> _printSale(SaleMaster sale) async {
    await PDFUtils.printSalePDF(sale);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Stock Tab with improved error handling
class StockTab extends StatefulWidget {
  final String userId; // Changed from userId to userId
  const StockTab({super.key, required this.userId});

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
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('StockTab StreamBuilder Error: ${snapshot.error}'); // Debug print
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
            debugPrint('Error parsing stock ${doc.id}: $e'); // Debug print
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
            'No stock records found', // Updated message for user-specific context
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your stock levels will appear here', // Updated message
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
        border: isLowStock ? Border.all(color: Colors.orange, width: 2) : Border.all(color: Colors.grey.shade200, width: 1), // Added border
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
                              debugPrint('Error loading item for stock card: $e'); // Debug print
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

// Enhanced Reports Tab with User-specific Data Analysis
class ReportsTab extends StatefulWidget {
  final String userId; // Changed from userId to userId
  const ReportsTab({super.key, required this.userId});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Inventory Reports', // Updated title for user-specific context
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          // Summary Cards Row
          Row(
            children: [
              Expanded(child: _buildSummaryCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildLowStockCard()),
            ],
          ),
          const SizedBox(height: 20),
          // Reports List
          Expanded(
            child: ListView(
              children: [
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
                  'Sales Performance (HSN)', // Updated title
                  'Track sales trends and performance by HSN/SAC code', // Updated subtitle
                  Icons.trending_up,
                  const Color(0xFF2196F3),
                      () => _showSalesByHsnReport(context), // NEW: Navigate to HSN report screen
                ),
                _buildReportCard(
                  'Valuation Report',
                  'Total inventory valuation',
                  Icons.account_balance,
                  const Color(0xFF9C27B0),
                      () => _showValuationReport(context),
                ),
                _buildReportCard(
                  'Profit Analysis',
                  'Analyze profit margins by item',
                  Icons.show_chart,
                  const Color(0xFFE91E63),
                      () => _showProfitAnalysisReport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('items')
          .where('userId', isEqualTo: widget.userId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int totalItems = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Total Items',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                totalItems.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLowStockCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('stock_inventory')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildSummaryCardSkeleton();
        }
        int lowStockCount = 0;
        for (var doc in snapshot.data!.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
            final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
            if (currentStock <= minStock) {
              lowStockCount++;
            }
          } catch (e) {
            debugPrint('Error calculating low stock count: $e'); // Debug print
            // Handle parsing errors
          }
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: lowStockCount > 0 ? Border.all(color: Colors.orange, width: 2) : null,
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
                children: [
                  Icon(
                    Icons.warning,
                    color: lowStockCount > 0 ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Low Stock',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lowStockCount.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: lowStockCount > 0 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.grey.shade400, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '0',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
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
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('stock_inventory')
                .where('userId', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No stock data available'),
                );
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final itemId = ItemMaster.getStringValue(data, 'itemId');
                  final location = ItemMaster.getStringValue(data, 'location');
                  final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
                  final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
                  final isLowStock = currentStock <= minStock;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('items').doc(itemId).get(),
                    builder: (context, itemSnapshot) {
                      String itemName = 'Unknown Item';
                      if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
                        try {
                          final item = ItemMaster.fromFirestore(itemSnapshot.data!);
                          itemName = item.description.isNotEmpty ? item.description : 'Unnamed Item';
                        } catch (e) {
                          debugPrint('Error loading item for stock summary: $e'); // Debug print
                          itemName = 'Error loading item';
                        }
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.inventory,
                            color: isLowStock ? Colors.orange : Colors.green,
                          ),
                          title: Text(itemName),
                          subtitle: Text('Location: $location'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Stock: ${currentStock.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? Colors.orange : Colors.green,
                                ),
                              ),
                              Text(
                                'Min: ${minStock.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
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

  void _showLowStockReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Stock Alert Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('stock_inventory')
                .where('userId', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // Filter low stock items
              final lowStockItems = snapshot.data!.docs.where((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
                  final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
                  return currentStock <= minStock;
                } catch (e) {
                  debugPrint('Error filtering low stock item: $e'); // Debug print
                  return false;
                }
              }).toList();

              if (lowStockItems.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'All items are well stocked!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: lowStockItems.length,
                itemBuilder: (context, index) {
                  final doc = lowStockItems[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final itemId = ItemMaster.getStringValue(data, 'itemId');
                  final location = ItemMaster.getStringValue(data, 'location');
                  final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
                  final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('items').doc(itemId).get(),
                    builder: (context, itemSnapshot) {
                      String itemName = 'Unknown Item';
                      if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
                        try {
                          final item = ItemMaster.fromFirestore(itemSnapshot.data!);
                          itemName = item.description.isNotEmpty ? item.description : 'Unnamed Item';
                        } catch (e) {
                          debugPrint('Error loading item for low stock report: $e'); // Debug print
                          itemName = 'Error loading item';
                        }
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: Colors.orange,
                          ),
                          title: Text(itemName),
                          subtitle: Text('Location: $location'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Stock: ${currentStock.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                'Min: ${minStock.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
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

  // NEW: Function to show the Sales by HSN Report Screen
  void _showSalesByHsnReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesByHsnReportScreen(businessId: widget.userId),
      ),
    );
  }

  void _showValuationReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inventory Valuation Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('stock_inventory')
                .where('userId', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No stock data available for valuation'),
                );
              }
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _calculateInventoryValuation(snapshot.data!.docs),
                builder: (context, valuationSnapshot) {
                  if (!valuationSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final valuationData = valuationSnapshot.data!;
                  double totalValue = 0;
                  for (var item in valuationData) {
                    totalValue += item['totalValue'] as double;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Inventory Value:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: valuationData.length,
                          itemBuilder: (context, index) {
                            final item = valuationData[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.account_balance, color: Colors.purple),
                                title: Text(item['itemName']),
                                subtitle: Text(
                                  'Stock: ${item['stock']} × ₹${item['costPrice'].toStringAsFixed(2)}',
                                ),
                                trailing: Text(
                                  '₹${item['totalValue'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
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

  void _showProfitAnalysisReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profit Analysis Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('items')
                .where('userId', isEqualTo: widget.userId)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No items available for profit analysis'),
                );
              }
              final items = snapshot.data!.docs.map((doc) {
                try {
                  return ItemMaster.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Error parsing item for profit analysis: $e'); // Debug print
                  return null;
                }
              }).where((item) => item != null).cast<ItemMaster>().toList();

              // Sort by profit margin (descending)
              items.sort((a, b) => b.profitMargin.compareTo(a.profitMargin));

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final profitPerUnit = item.sellingPrice - item.costPrice;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.show_chart,
                        color: item.profitMargin > 20 ? Colors.green :
                        item.profitMargin > 10 ? Colors.orange : Colors.red,
                      ),
                      title: Text(item.description.isNotEmpty ? item.description : 'Unnamed Item'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cost: ₹${item.costPrice.toStringAsFixed(2)} | Selling: ₹${item.sellingPrice.toStringAsFixed(2)}'),
                          Text('Profit per unit: ₹${profitPerUnit.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.profitMargin > 20 ? Colors.green.withOpacity(0.1) :
                          item.profitMargin > 10 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.profitMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.profitMargin > 20 ? Colors.green :
                            item.profitMargin > 10 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
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

  Future<List<Map<String, dynamic>>> _calculateInventoryValuation(List<QueryDocumentSnapshot> stockDocs) async {
    List<Map<String, dynamic>> valuationData = [];
    for (var doc in stockDocs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final itemId = ItemMaster.getStringValue(data, 'itemId');
        final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');

        // Get item details
        final itemDoc = await _firestore.collection('items').doc(itemId).get();
        if (itemDoc.exists) {
          final item = ItemMaster.fromFirestore(itemDoc);
          final totalValue = currentStock * item.costPrice;
          valuationData.add({
            'itemName': item.description.isNotEmpty ? item.description : 'Unnamed Item',
            'stock': currentStock,
            'costPrice': item.costPrice,
            'totalValue': totalValue,
          });
        }
      } catch (e) {
        // Handle individual item errors
        debugPrint('Error calculating valuation for item: $e'); // Debug print
      }
    }
    return valuationData;
  }
}

class GenerateStockReportButton extends StatefulWidget {
  final String userId; // Change from userId to userId

  const GenerateStockReportButton({Key? key, required this.userId}) : super(key: key);

  @override
  State<GenerateStockReportButton> createState() => _GenerateStockReportButtonState();
}

class _GenerateStockReportButtonState extends State<GenerateStockReportButton> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton.extended(
          heroTag: 'generate_stock_report',
          label: const Text('Generate All Stock Report'),
          icon: const Icon(Icons.document_scanner),
          backgroundColor: Colors.blue,
          onPressed: () async {
            try {
              final stockSnapshot = await _firestore
                  .collection('stock_inventory')
                  .where('userId', isEqualTo: widget.userId)
                  .get();
              final stocks = stockSnapshot.docs
                  .map((doc) => StockInventory.fromFirestore(doc))
                  .toList();

              final itemSnapshot = await _firestore
                  .collection('items')
                  .where('userId', isEqualTo: widget.userId) // Add this filter
                  .where('isActive', isEqualTo: true)
                  .get();
              final items = itemSnapshot.docs
                  .map((doc) => ItemMaster.fromFirestore(doc))
                  .toList();

              if (stocks.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No stock data to export.'), backgroundColor: Colors.orange),
                  );
                }
                return;
              }
              // Show options to download, share, or print
              showModalBottomSheet(
                context: context,
                builder: (BuildContext bc) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.download),
                          title: const Text('Download PDF'),
                          onTap: () async {
                            Navigator.pop(bc);
                            await PDFUtils.generateAndDownloadAllStockPDF(stocks, items);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All Stock Report PDF downloaded!'), backgroundColor: Colors.green),
                              );
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.share),
                          title: const Text('Share PDF'),
                          onTap: () async {
                            Navigator.pop(bc);
                            await PDFUtils.shareAllStockPDF(stocks, items);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All Stock Report PDF shared!'), backgroundColor: Colors.green),
                              );
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.print),
                          title: const Text('Print PDF'),
                          onTap: () async {
                            Navigator.pop(bc);
                            await PDFUtils.printAllStockPDF(stocks, items);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All Stock Report PDF sent to printer!'), backgroundColor: Colors.green),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error generating stock report: $e'), backgroundColor: Colors.red),
                );
              }
              debugPrint('Error generating all stock report: $e');
            }
          },
        ),
      ),
    );
  }
}
// GSTR-1 Section Screen for B2B, B2C Large, B2C Small, Exports
class GSTR1SectionScreen extends StatefulWidget {
  final String userId;
  final String sectionTitle;
  final String sectionFilter;
  final DateTime fromDate;
  final DateTime toDate;

  const GSTR1SectionScreen({
    super.key,
    required this.userId,
    required this.sectionTitle,
    required this.sectionFilter,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<GSTR1SectionScreen> createState() => _GSTR1SectionScreenState();
}

class _GSTR1SectionScreenState extends State<GSTR1SectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionTitle),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('sales')
            .where('userId', isEqualTo: widget.userId) // Add this filter
            .where('gstr1Section', isEqualTo: widget.sectionFilter)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data!.docs
              .map((doc) => SaleMaster.fromFirestore(doc))
              .toList();

          if (sales.isEmpty) {
            return _buildEmptyState();
          }

          // Calculate totals
          double totalTaxableValue = 0;
          double totalCGST = 0;
          double totalSGST = 0;
          double totalIGST = 0;
          double totalCess = 0;
          double grandTotal = 0;

          for (var sale in sales) {
            for (var item in sale.items) {
              totalTaxableValue += item.totalTaxableValue;
              totalCGST += item.centralTaxAmount;
              totalSGST += item.stateTaxAmount;
              totalIGST += item.integratedTaxAmount;
              totalCess += item.cessAmount;
            }
            grandTotal += sale.total;
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow( // Change from Shadow to BoxShadow
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Period: ${DateFormat('dd/MM/yyyy').format(widget.fromDate)} - ${DateFormat('dd/MM/yyyy').format(widget.toDate)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${sales.length} Invoices',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Taxable', '₹${totalTaxableValue.toStringAsFixed(2)}'),
                        _buildSummaryItem('CGST', '₹${totalCGST.toStringAsFixed(2)}'),
                        _buildSummaryItem('SGST', '₹${totalSGST.toStringAsFixed(2)}'),
                        _buildSummaryItem('IGST', '₹${totalIGST.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total: ₹${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Sales List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    return _buildSaleCard(sales[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No ${widget.sectionTitle.toLowerCase()} found',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'for the selected period',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SaleMaster sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        'Invoice: ${sale.invoice}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('Customer: ${sale.customerName}'),
                      if (sale.recipientGSTIN.isNotEmpty)
                        Text('GSTIN: ${sale.recipientGSTIN}',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${sale.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(sale.date),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sale.supplyType == 'INTRA' ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sale.supplyType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: sale.supplyType == 'INTRA' ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (sale.placeOfSupply.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('POS: ${sale.placeOfSupply}', style: TextStyle(color: Colors.grey.shade600)),
            ],

            const SizedBox(height: 12),
            // Items summary
            Text('Items (${sale.items.length}):', style: const TextStyle(fontWeight: FontWeight.w500)),
            ...sale.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Row(
                children: [
                  Expanded(child: Text('• ${item.description}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                  Text('₹${item.itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            )),
            if (sale.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text('... and ${sale.items.length - 3} more items',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final salesSnapshot = await _firestore
          .collection('sales')
          .where('userId', isEqualTo: widget.userId) // Add this filter
          .where('gstr1Section', isEqualTo: widget.sectionFilter)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
          .get();

      final sales = salesSnapshot.docs
          .map((doc) => SaleMaster.fromFirestore(doc))
          .toList();

      if (sales.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Download PDF'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateGSTR1SectionPDF(sales.cast<Map<String, dynamic>>(), widget.sectionTitle, widget.fromDate, widget.toDate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.sectionTitle} PDF downloaded!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Download Excel'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateGSTR1SectionExcel(sales.cast<Map<String, dynamic>>(), widget.sectionTitle, widget.fromDate, widget.toDate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.sectionTitle} Excel downloaded!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Download JSON'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateGSTR1SectionJSON(sales, widget.sectionFilter, widget.fromDate, widget.toDate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.sectionTitle} JSON downloaded!')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// HSN Summary Screen
class HSNSummaryScreen extends StatefulWidget {
  final String userId;
  final DateTime fromDate;
  final DateTime toDate;

  const HSNSummaryScreen({
    super.key,
    required this.userId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<HSNSummaryScreen> createState() => _HSNSummaryScreenState();
}

class _HSNSummaryScreenState extends State<HSNSummaryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HSN Summary'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportHSNSummary,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _generateHSNSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final hsnData = snapshot.data ?? [];

          if (hsnData.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.summarize, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No HSN data found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.teal.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total HSN Codes', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${hsnData.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Total Value', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('₹${hsnData.fold<double>(0, (sum, item) => sum + item['totalValue']).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // HSN List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hsnData.length,
                  itemBuilder: (context, index) {
                    final hsn = hsnData[index];
                    return _buildHSNCard(hsn);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHSNCard(Map<String, dynamic> hsn) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HSN: ${hsn['hsnCode']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₹${hsn['totalValue'].toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Description: ${hsn['description']}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('UQC: ${hsn['uqc']}')),
                Expanded(child: Text('Qty: ${hsn['totalQuantity'].toStringAsFixed(2)}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTaxInfo('Taxable', hsn['taxableValue']),
                _buildTaxInfo('CGST', hsn['cgstAmount']),
                _buildTaxInfo('SGST', hsn['sgstAmount']),
                _buildTaxInfo('IGST', hsn['igstAmount']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxInfo(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text('₹${value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _generateHSNSummary() async {
    final salesSnapshot = await _firestore
        .collection('sales')
        .where('userId', isEqualTo: widget.userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
        .get();

    final Map<String, Map<String, dynamic>> hsnSummary = {};

    for (var doc in salesSnapshot.docs) {
      final sale = SaleMaster.fromFirestore(doc);

      for (var item in sale.items) {
        final hsnCode = item.hsnSacCode;

        if (hsnSummary.containsKey(hsnCode)) {
          hsnSummary[hsnCode]!['totalQuantity'] += item.quantity;
          hsnSummary[hsnCode]!['taxableValue'] += item.totalTaxableValue;
          hsnSummary[hsnCode]!['cgstAmount'] += item.centralTaxAmount;
          hsnSummary[hsnCode]!['sgstAmount'] += item.stateTaxAmount;
          hsnSummary[hsnCode]!['igstAmount'] += item.integratedTaxAmount;
          hsnSummary[hsnCode]!['totalValue'] += item.itemTotal;
        } else {
          hsnSummary[hsnCode] = {
            'hsnCode': hsnCode,
            'description': item.description,
            'uqc': item.unitOfMeasurement,
            'totalQuantity': item.quantity,
            'taxableValue': item.totalTaxableValue,
            'cgstAmount': item.centralTaxAmount,
            'sgstAmount': item.stateTaxAmount,
            'igstAmount': item.integratedTaxAmount,
            'totalValue': item.itemTotal,
          };
        }
      }
    }

    return hsnSummary.values.toList()..sort((a, b) => a['hsnCode'].compareTo(b['hsnCode']));
  }

  Future<void> _exportHSNSummary() async {
    try {
      final hsnData = await _generateHSNSummary();

      if (hsnData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No HSN data to export')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Download PDF'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateHSNSummaryPDF(hsnData, widget.fromDate, widget.toDate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('HSN Summary PDF downloaded!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Download Excel'),
                  onTap: () async {
                    Navigator.pop(bc);
                    await PDFUtils.generateHSNSummaryExcel(hsnData, widget.fromDate, widget.toDate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('HSN Summary Excel downloaded!')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Documents Summary Screen
class DocumentsSummaryScreen extends StatefulWidget {
  final String userId;
  final DateTime fromDate;
  final DateTime toDate;

  const DocumentsSummaryScreen({
    super.key,
    required this.userId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<DocumentsSummaryScreen> createState() => _DocumentsSummaryScreenState();
}

class _DocumentsSummaryScreenState extends State<DocumentsSummaryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents Summary'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _generateDocumentsSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docSummary = snapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period: ${DateFormat('dd/MM/yyyy').format(widget.fromDate)} - ${DateFormat('dd/MM/yyyy').format(widget.toDate)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),

                _buildDocumentTypeCard('Invoices', docSummary['invoices'] ?? {}),
                _buildDocumentTypeCard('Debit Notes', docSummary['debitNotes'] ?? {}),
                _buildDocumentTypeCard('Credit Notes', docSummary['creditNotes'] ?? {}),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportDocumentsSummary(docSummary),
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Summary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentTypeCard(String title, Map<String, dynamic> data) {
    final count = data['count'] ?? 0;
    final fromNo = data['fromNo'] ?? 'N/A';
    final toNo = data['toNo'] ?? 'N/A';
    final cancelled = data['cancelled'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Issued: $count', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('From: $fromNo'),
                      Text('To: $toNo'),
                    ],
                  ),
                ),
                if (cancelled > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$cancelled Cancelled',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _generateDocumentsSummary() async {
    final salesSnapshot = await _firestore
        .collection('sales')
        .where('userId', isEqualTo: widget.userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
        .get();

    final invoices = <String>[];
    final debitNotes = <String>[];
    final creditNotes = <String>[];

    for (var doc in salesSnapshot.docs) {
      final sale = SaleMaster.fromFirestore(doc);

      switch (sale.documentType) {
        case 'INV':
          invoices.add(sale.invoice);
          break;
        case 'DBN':
          debitNotes.add(sale.invoice);
          break;
        case 'CDN':
          creditNotes.add(sale.invoice);
          break;
      }
    }

    return {
      'invoices': _getDocumentSummary(invoices),
      'debitNotes': _getDocumentSummary(debitNotes),
      'creditNotes': _getDocumentSummary(creditNotes),
    };
  }

  Map<String, dynamic> _getDocumentSummary(List<String> documents) {
    if (documents.isEmpty) {
      return {'count': 0, 'fromNo': 'N/A', 'toNo': 'N/A', 'cancelled': 0};
    }

    documents.sort();
    return {
      'count': documents.length,
      'fromNo': documents.first,
      'toNo': documents.last,
      'cancelled': 0, // You can implement cancelled document tracking
    };
  }

  Future<void> _exportDocumentsSummary(Map<String, dynamic> summary) async {
    try {
      await PDFUtils.generateDocumentsSummaryPDF(summary as List<Map<String, dynamic>>, widget.fromDate, widget.toDate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents Summary PDF downloaded!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Nil Rated Supplies Screen
class NilRatedSuppliesScreen extends StatefulWidget {
  final String userId;
  final DateTime fromDate;
  final DateTime toDate;

  const NilRatedSuppliesScreen({
    super.key,
    required this.userId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<NilRatedSuppliesScreen> createState() => _NilRatedSuppliesScreenState();
}

class _NilRatedSuppliesScreenState extends State<NilRatedSuppliesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nil Rated Supplies'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _generateNilRatedData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final nilRatedData = snapshot.data ?? {};

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Color(0xFF667eea),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF667eea),
                  tabs: [
                    Tab(text: 'Nil Rated'),
                    Tab(text: 'Exempted'),
                    Tab(text: 'Non-GST'),
                    Tab(text: 'Composition'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildNilRatedTab(nilRatedData['nilRated'] ?? []),
                      _buildNilRatedTab(nilRatedData['exempted'] ?? []),
                      _buildNilRatedTab(nilRatedData['nonGST'] ?? []),
                      _buildNilRatedTab(nilRatedData['composition'] ?? []),
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

  Widget _buildNilRatedTab(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No data found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    double totalValue = data.fold(0, (sum, item) => sum + (item['value'] as double));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Items: ${data.length}'),
              Text('Total Value: ₹${totalValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(item['description']),
                  subtitle: Text('HSN: ${item['hsnCode']}'),
                  trailing: Text('₹${item['value'].toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _generateNilRatedData() async {
    final salesSnapshot = await _firestore
        .collection('sales')
        .where('userId', isEqualTo: widget.userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.fromDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.toDate))
        .get();

    final Map<String, List<Map<String, dynamic>>> nilRatedData = {
      'nilRated': [],
      'exempted': [],
      'nonGST': [],
      'composition': [],
    };

    for (var doc in salesSnapshot.docs) {
      final sale = SaleMaster.fromFirestore(doc);

      for (var item in sale.items) {
        if (item.isNilRated) {
          nilRatedData['nilRated']!.add({
            'description': item.description,
            'hsnCode': item.hsnSacCode,
            'value': item.totalTaxableValue,
          });
        } else if (item.isExempt) {
          nilRatedData['exempted']!.add({
            'description': item.description,
            'hsnCode': item.hsnSacCode,
            'value': item.totalTaxableValue,
          });
        } else if (item.isNonGST) {
          nilRatedData['nonGST']!.add({
            'description': item.description,
            'hsnCode': item.hsnSacCode,
            'value': item.totalTaxableValue,
          });
        }
      }
    }

    return nilRatedData;
  }
}
class StockTabWithReportButton extends StatelessWidget {
  final String userId;

  const StockTabWithReportButton({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StockTab(userId: userId),
        GenerateStockReportButton(userId: userId),
      ],
    );
  }
}
