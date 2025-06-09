import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Models based on your PDF table structure
class Business {
  final String? id;
  final String businessName;
  final String? logoPath;
  final String address;
  final String gstin;
  final String stateCode;
  final String businessType;
  final String turnoverCategory;
  final String? digitalSignaturePath;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankBranch;
  final DateTime createdAt;

  Business({
    this.id,
    required this.businessName,
    this.logoPath,
    required this.address,
    required this.gstin,
    required this.stateCode,
    required this.businessType,
    required this.turnoverCategory,
    this.digitalSignaturePath,
    this.bankAccountNumber,
    this.bankName,
    this.bankBranch,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logoPath': logoPath,
      'address': address,
      'gstin': gstin,
      'stateCode': stateCode,
      'businessType': businessType,
      'turnoverCategory': turnoverCategory,
      'digitalSignaturePath': digitalSignaturePath,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'bankBranch': bankBranch,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Business.fromMap(Map<String, dynamic> map, String id) {
    return Business(
      id: id,
      businessName: map['businessName'] ?? '',
      logoPath: map['logoPath'],
      address: map['address'] ?? '',
      gstin: map['gstin'] ?? '',
      stateCode: map['stateCode'] ?? '',
      businessType: map['businessType'] ?? '',
      turnoverCategory: map['turnoverCategory'] ?? '',
      digitalSignaturePath: map['digitalSignaturePath'],
      bankAccountNumber: map['bankAccountNumber'],
      bankName: map['bankName'],
      bankBranch: map['bankBranch'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Customer {
  final String? id;
  final String businessId;
  final String name;
  final String contactNumber;
  final String email;
  final String address;
  final String? gstin;
  final String? stateCode;
  final String customerType;
  final double? creditLimit;
  final String? creditTerms;
  final String? taxTreatment;

  Customer({
    this.id,
    required this.businessId,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.address,
    this.gstin,
    this.stateCode,
    required this.customerType,
    this.creditLimit,
    this.creditTerms,
    this.taxTreatment,
  });

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
      'gstin': gstin,
      'stateCode': stateCode,
      'customerType': customerType,
      'creditLimit': creditLimit,
      'creditTerms': creditTerms,
      'taxTreatment': taxTreatment,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gstin: map['gstin'],
      stateCode: map['stateCode'],
      customerType: map['customerType'] ?? 'B2C',
      creditLimit: map['creditLimit']?.toDouble(),
      creditTerms: map['creditTerms'],
      taxTreatment: map['taxTreatment'],
    );
  }
}

// Firebase Service for CRUD operations
class GSTFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Business CRUD operations
  static Future<String> addBusiness(Business business) async {
    try {
      DocumentReference docRef = await _firestore.collection('businesses').add(business.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add business: $e');
    }
  }

  static Future<void> updateBusiness(String id, Business business) async {
    try {
      await _firestore.collection('businesses').doc(id).update(business.toMap());
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  static Future<void> deleteBusiness(String id) async {
    try {
      await _firestore.collection('businesses').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete business: $e');
    }
  }

  static Stream<List<Business>> getBusinesses() {
    return _firestore.collection('businesses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Business.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Customer CRUD operations
  static Future<String> addCustomer(Customer customer) async {
    try {
      DocumentReference docRef = await _firestore.collection('customers').add(customer.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  static Stream<List<Customer>> getCustomers(String businessId) {
    return _firestore
        .collection('customers')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}

// Main GST Management Screen
class GSTManagementScreen extends StatefulWidget {
  const GSTManagementScreen({super.key});

  @override
  State<GSTManagementScreen> createState() => _GSTManagementScreenState();
}

class _GSTManagementScreenState extends State<GSTManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'GST Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Businesses', icon: Icon(Icons.business)),
            Tab(text: 'Customers', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1565C0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBusinessesTab(),
                _buildCustomersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddBusinessDialog();
          } else {
            _showAddCustomerDialog();
          }
        },
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Business' : 'Add Customer',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBusinessesTab() {
    return StreamBuilder<List<Business>>(
      stream: GSTFirebaseService.getBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        List<Business> businesses = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          businesses = businesses.where((business) {
            return business.businessName.toLowerCase().contains(_searchQuery) ||
                business.gstin.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (businesses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No businesses found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first business to get started',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: businesses.length,
          itemBuilder: (context, index) {
            return _buildBusinessCard(businesses[index]);
          },
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    return StreamBuilder<List<Business>>(
      stream: GSTFirebaseService.getBusinesses(),
      builder: (context, businessSnapshot) {
        if (businessSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Business> businesses = businessSnapshot.data ?? [];

        if (businesses.isEmpty) {
          return const Center(
            child: Text('Please add a business first to manage customers'),
          );
        }

        return StreamBuilder<List<Customer>>(
          stream: GSTFirebaseService.getCustomers(businesses.first.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<Customer> customers = snapshot.data ?? [];

            if (_searchQuery.isNotEmpty) {
              customers = customers.where((customer) {
                return customer.name.toLowerCase().contains(_searchQuery) ||
                    customer.email.toLowerCase().contains(_searchQuery);
              }).toList();
            }

            if (customers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No customers found',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                return _buildCustomerCard(customers[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBusinessCard(Business business) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Color(0xFF1565C0),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.businessName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'GSTIN: ${business.gstin}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBusinessDialog(business);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(business.id!, 'business');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, business.address),
            _buildInfoRow(Icons.category, business.businessType),
            _buildInfoRow(Icons.trending_up, business.turnoverCategory),
            if (business.bankName != null)
              _buildInfoRow(Icons.account_balance, business.bankName!),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        customer.customerType,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, customer.contactNumber),
            _buildInfoRow(Icons.email, customer.email),
            _buildInfoRow(Icons.location_on, customer.address),
            if (customer.gstin != null)
              _buildInfoRow(Icons.receipt, customer.gstin!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBusinessDialog() {
    _showBusinessDialog();
  }

  void _showEditBusinessDialog(Business business) {
    _showBusinessDialog(business: business);
  }

  void _showBusinessDialog({Business? business}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: business?.businessName ?? '');
    final addressController = TextEditingController(text: business?.address ?? '');
    final gstinController = TextEditingController(text: business?.gstin ?? '');
    final stateCodeController = TextEditingController(text: business?.stateCode ?? '');
    String businessType = business?.businessType ?? 'Proprietorship';
    String turnoverCategory = business?.turnoverCategory ?? 'Below 20 Lakh';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(business == null ? 'Add Business' : 'Edit Business'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: gstinController,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stateCodeController,
                  decoration: const InputDecoration(
                    labelText: 'State Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: businessType,
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Proprietorship', 'Partnership', 'LLP', 'Private Limited', 'Public Limited']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => businessType = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: turnoverCategory,
                  decoration: const InputDecoration(
                    labelText: 'Turnover Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Below 20 Lakh', '20 Lakh - 1 Crore', '1-5 Crore', 'Above 5 Crore']
                      .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                  onChanged: (value) => turnoverCategory = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final newBusiness = Business(
                    id: business?.id,
                    businessName: nameController.text,
                    address: addressController.text,
                    gstin: gstinController.text,
                    stateCode: stateCodeController.text,
                    businessType: businessType,
                    turnoverCategory: turnoverCategory,
                    createdAt: business?.createdAt ?? DateTime.now(),
                  );

                  if (business == null) {
                    await GSTFirebaseService.addBusiness(newBusiness);
                  } else {
                    await GSTFirebaseService.updateBusiness(business.id!, newBusiness);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(business == null ? 'Business added successfully' : 'Business updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(business == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    // Get the first business ID for simplicity
    StreamBuilder<List<Business>>(
      stream: GSTFirebaseService.getBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          _showCustomerDialog(snapshot.data!.first.id!);
        }
        return const SizedBox();
      },
    );
  }

  void _showCustomerDialog(String businessId) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    String customerType = 'B2C';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Customer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: customerType,
                  decoration: const InputDecoration(
                    labelText: 'Customer Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['B2B', 'B2C', 'Export', 'Import']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => customerType = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final customer = Customer(
                    businessId: businessId,
                    name: nameController.text,
                    contactNumber: contactController.text,
                    email: emailController.text,
                    address: addressController.text,
                    customerType: customerType,
                  );

                  await GSTFirebaseService.addCustomer(customer);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String id, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type'),
        content: Text('Are you sure you want to delete this $type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                if (type == 'business') {
                  await GSTFirebaseService.deleteBusiness(id);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$type deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}