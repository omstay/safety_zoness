import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'add_item_screen.dart';

class AddEditSaleScreen extends StatefulWidget {
  final DocumentSnapshot? saleDoc;
  final String businessId;
  final String saleId;

  const AddEditSaleScreen({
    super.key,
    this.saleDoc,
    required this.businessId,
    required this.saleId,
  });

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  int invoiceNumber = 1;
  List<Map<String, dynamic>> _items = [];
  bool isCredit = true;
  DocumentReference? _saleRef;

  @override
  void initState() {
    super.initState();

    if (widget.saleDoc != null) {
      _loadFromDocument(widget.saleDoc!);
    } else if (widget.saleId.isNotEmpty) {
      _fetchSaleById();
    } else {
      _loadNextInvoiceNumber();
    }
  }

  void _loadFromDocument(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    _saleRef = doc.reference;

    setState(() {
      _customerController.text = data['customerName'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      selectedDate = (data['date'] as Timestamp).toDate();
      invoiceNumber = data['invoice'] ?? 1;
      isCredit = (data['type'] ?? 'Credit') == 'Credit';
    });

    final itemsSnapshot = await _saleRef!.collection('items').get();
    setState(() {
      _items = itemsSnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _fetchSaleById() async {
    final doc = await FirebaseFirestore.instance
        .collection('sales')
        .doc(widget.saleId)
        .get();

    if (doc.exists) {
      _loadFromDocument(doc);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale not found')),
      );
    }
  }

  Future<void> _loadNextInvoiceNumber() async {
    final sales = await FirebaseFirestore.instance
        .collection('sales')
        .orderBy('invoice', descending: true)
        .limit(1)
        .get();

    if (sales.docs.isNotEmpty) {
      setState(() {
        invoiceNumber = (sales.docs.first['invoice'] ?? 0) + 1;
      });
    }
  }

  double get totalAmount => _items.fold(0.0, (sum, item) {
    return sum + (item['price'] * item['quantity']);
  });

  Future<void> _saveSale({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    final saleData = {
      'invoice': invoiceNumber,
      'date': Timestamp.fromDate(selectedDate),
      'customerName': _customerController.text.trim(),
      'phone': _phoneController.text.trim(),
      'total': totalAmount,
      'type': isCredit ? 'Credit' : 'Cash',
      'businessId': widget.businessId,
    };

    if (_saleRef == null) {
      _saleRef = await FirebaseFirestore.instance.collection('sales').add(saleData);
    } else {
      await _saleRef!.update(saleData);
      final oldItems = await _saleRef!.collection('items').get();
      for (var doc in oldItems.docs) {
        await doc.reference.delete();
      }
    }

    for (var item in _items) {
      await _saleRef!.collection('items').add(item);
    }

    if (saveAndNew) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditSaleScreen(
            businessId: widget.businessId,
            saleId: '',
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _navigateToAddItem() async {
    final newItem = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => AddItemScreen()),
    );

    if (newItem != null) {
      setState(() => _items.add(newItem));
    }
  }

  void _shareInvoice() {
    final invoiceText = StringBuffer()
      ..writeln("Invoice #$invoiceNumber")
      ..writeln("Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}")
      ..writeln("Customer: ${_customerController.text}")
      ..writeln("Phone: ${_phoneController.text}")
      ..writeln("Items:");
    for (var item in _items) {
      invoiceText.writeln(
          "- ${item['name']} (${item['quantity']} ${item['unit']}) x ₹${item['price']}");
    }
    invoiceText.writeln("Total: ₹${totalAmount.toStringAsFixed(2)}");

    Share.share(invoiceText.toString());
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sale"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareInvoice,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: invoiceNumber,
                      items: [invoiceNumber]
                          .map((e) => DropdownMenuItem(
                          value: e, child: Text('Invoice No. $e')))
                          .toList(),
                      onChanged: null,
                      decoration:
                      const InputDecoration(labelText: 'Invoice No.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Text(dateFormatted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Customer *'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration:
                const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Items"),
                onPressed: _navigateToAddItem,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text(
                          '${item['quantity']} ${item['unit']} x ₹${item['price']} (${item['tax']})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => _items.removeAt(index)),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("₹${totalAmount.toStringAsFixed(2)}"),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _saveSale(saveAndNew: true),
                      child: const Text("Save & New"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSale,
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
