import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/item_master.dart';
import '../services/user_service.dart';

class ItemsTab extends StatefulWidget {
  final String businessId;

  const ItemsTab({super.key, required this.businessId});

  @override
  State<ItemsTab> createState() => ItemsTabState();
}

class ItemsTabState extends State<ItemsTab> {
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
              hintText: 'Search items by name or code...',
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
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                  ),
                );
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No items found' : 'No items match your search',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first item to get started'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => showAddItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(16),
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
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF2196F3),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description.isNotEmpty ? item.description : 'Unnamed Item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${item.itemCode.isNotEmpty ? item.itemCode : 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
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
                            Icon(Icons.edit, size: 20, color: Color(0xFF2196F3)),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip('HSN: ${item.hsnSacCode.isNotEmpty ? item.hsnSacCode : 'N/A'}', const Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  _buildInfoChip('Unit: ${item.unitOfMeasurement.isNotEmpty ? item.unitOfMeasurement : 'N/A'}', const Color(0xFF4CAF50)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceInfo('Cost Price', item.costPrice, Colors.red),
                  _buildPriceInfo('Selling Price', item.sellingPrice, const Color(0xFF4CAF50)),
                  _buildPriceInfo('Profit', item.profitMargin, const Color(0xFF2196F3), isPercentage: true),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, double value, Color color, {bool isPercentage = false}) {
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
          isPercentage ? '${value.toStringAsFixed(1)}%' : '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void showAddItemDialog() {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEditing ? Icons.edit : Icons.add,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(width: 8),
            Text(isEditing ? 'Edit Item' : 'Add New Item'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveItem(controllers, isEditing, item?.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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

      final itemData = await UserService.addUserContext({
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
      });

      if (isEditing && itemId != null) {
        itemData['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('items').doc(itemId).update(itemData);
      } else {
        await _firestore.collection('items').add(itemData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Item updated successfully' : 'Item added successfully'),
            backgroundColor: const Color(0xFF4CAF50),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info, color: Color(0xFF2196F3)),
            const SizedBox(width: 8),
            Text(item.description.isNotEmpty ? item.description : 'Item Details'),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Item'),
          ],
        ),
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
                      backgroundColor: Color(0xFF4CAF50),
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
