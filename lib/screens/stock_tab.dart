import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/item_master.dart';
import '../services/user_service.dart';

class StockInventory {
  final String id;
  final String businessId;
  final String userId;
  final String itemId;
  final String location;
  final double currentStock;
  final double minimumStockLevel;
  final DateTime lastUpdated;

  StockInventory({
    required this.id,
    required this.businessId,
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
      businessId: ItemMaster.getStringValue(map, 'businessId'),
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
      'businessId': businessId,
      'userId': userId,
      'itemId': itemId,
      'location': location,
      'currentStock': currentStock,
      'minimumStockLevel': minimumStockLevel,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class StockTab extends StatefulWidget {
  final String businessId;

  const StockTab({super.key, required this.businessId});

  @override
  State<StockTab> createState() => StockTabState();
}

class StockTabState extends State<StockTab> {
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
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
            ),
          );
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.storage_outlined,
              size: 60,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No stock records found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stock levels will appear here once you add them',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => showAddStockDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(StockInventory stock) {
    final isLowStock = stock.currentStock <= stock.minimumStockLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLowStock ? Border.all(color: const Color(0xFFFF9800), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? const Color(0xFFFF9800).withOpacity(0.1)
                        : const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.storage,
                    color: isLowStock ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            } catch (e) {
                              return const Text(
                                'Error loading item',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              );
                            }
                          }
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${stock.location.isNotEmpty ? stock.location : 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LOW STOCK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStockInfo('Current Stock', stock.currentStock.toStringAsFixed(1),
                    isLowStock ? const Color(0xFFFF9800) : const Color(0xFF4CAF50)),
                _buildStockInfo('Min Level', stock.minimumStockLevel.toStringAsFixed(1), Colors.grey),
                _buildStockInfo('Status', isLowStock ? 'Low' : 'Good',
                    isLowStock ? const Color(0xFFFF9800) : const Color(0xFF4CAF50)),
              ],
            ),
            const SizedBox(height: 12),
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

  Widget _buildStockInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void showAddStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(businessId: widget.businessId),
    );
  }
}

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
      final stockData = await UserService.addUserContext({
        'itemId': _selectedItemId,
        'location': _locationController.text.trim(),
        'currentStock': double.parse(_currentStockController.text),
        'minimumStockLevel': double.parse(_minStockController.text),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('stock_inventory').add(stockData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock added successfully'),
            backgroundColor: Color(0xFF4CAF50),
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
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add, color: Color(0xFFFF9800)),
          SizedBox(width: 8),
          Text('Add Stock'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedItemId,
                decoration: InputDecoration(
                  labelText: 'Select Item',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Current Stock',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
              TextFormField(
                controller: _minStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Minimum Stock Level',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
            backgroundColor: const Color(0xFFFF9800),
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

  @override
  void dispose() {
    _locationController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }
}
