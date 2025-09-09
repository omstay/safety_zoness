import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class EnhancedAddPartyScreen extends StatefulWidget {
  const EnhancedAddPartyScreen({super.key});

  @override
  State<EnhancedAddPartyScreen> createState() => _EnhancedAddPartyScreenState();
}

class _EnhancedAddPartyScreenState extends State<EnhancedAddPartyScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Enhanced Form controllers
  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _openingBalController = TextEditingController();
  final TextEditingController _billingAddressController = TextEditingController();
  final TextEditingController _shippingAddressController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();

  DateTime _asOfDate = DateTime.now();
  String _balanceType = 'To Pay';
  String _partyCategory = 'Customer'; // Customer or Supplier
  String _partyType = 'B2C'; // B2B or B2C
  String _paymentTerms = 'Immediate'; // Immediate, 15 Days, 30 Days, 45 Days
  bool _isGstRegistered = false;
  bool _isLoading = false;
  late TabController _tabController;

  // GST validation
  bool _validateGSTNumber(String gstNumber) {
    if (gstNumber.isEmpty) return !_isGstRegistered;
    if (gstNumber.length != 15) return false;
    final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[Z]{1}[0-9A-Z]{1}$');
    return gstRegex.hasMatch(gstNumber);
  }

  // PAN validation
  bool _validatePANNumber(String panNumber) {
    if (panNumber.isEmpty) return true; // Optional
    if (panNumber.length != 10) return false;
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return panRegex.hasMatch(panNumber);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _partyNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _openingBalController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _gstNumberController.dispose();
    _panNumberController.dispose();
    _creditLimitController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  Future<void> _addParty() async {
    // Enhanced validation
    if (_partyNameController.text.trim().isEmpty) {
      _showSnackBar('Party name is required', Colors.red);
      return;
    }

    if (_isGstRegistered && !_validateGSTNumber(_gstNumberController.text.trim())) {
      _showSnackBar('Invalid GST number format', Colors.red);
      return;
    }

    if (!_validatePANNumber(_panNumberController.text.trim())) {
      _showSnackBar('Invalid PAN number format', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      String userId = user?.uid ?? 'anonymous_user_${DateTime.now().millisecondsSinceEpoch}';

      // Enhanced party data structure for business modules
      final partyData = {
        // Basic Information
        'partyName': _partyNameController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'emailAddress': _emailController.text.trim(),

        // Business Classification
        'partyCategory': _partyCategory, // Customer/Supplier
        'partyType': _partyType, // B2B/B2C
        'paymentTerms': _paymentTerms,

        // Financial Information
        'openingBalance': double.tryParse(_openingBalController.text) ?? 0.0,
        'balanceType': _balanceType,
        'creditLimit': double.tryParse(_creditLimitController.text) ?? 0.0,
        'asOfDate': Timestamp.fromDate(_asOfDate),

        // Address Information
        'billingAddress': _billingAddressController.text.trim(),
        'shippingAddress': _shippingAddressController.text.trim(),

        // Tax Information
        'isGstRegistered': _isGstRegistered,
        'gstNumber': _gstNumberController.text.trim(),
        'panNumber': _panNumberController.text.trim(),

        // Banking Information
        'bankName': _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'ifscCode': _ifscCodeController.text.trim(),

        // System Information
        'userId': userId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isActive': true,

        // Business Module Integration
        'totalSales': 0.0,
        'totalPurchases': 0.0,
        'lastTransactionDate': null,
        'transactionCount': 0,
      };

      final docRef = await _firestore.collection('parties').add(partyData);

      _showSnackBar('Party added successfully!', Colors.green);
      _showSuccessOptions(docRef.id, partyData);
    } catch (e) {
      _showSnackBar('Error adding party: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessOptions(String partyId, Map<String, dynamic> partyData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Party Added Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What would you like to do next with ${partyData['partyName']}?',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildActionOption(
                  icon: Icons.receipt_rounded,
                  label: partyData['partyCategory'] == 'Customer' ? 'Create Invoice' : 'Create Order',
                  color: const Color(0xFF10B981),
                  onTap: () => _createBusinessDocument(partyData),
                ),
                _buildActionOption(
                  icon: Icons.person_add_rounded,
                  label: 'Add Another',
                  color: const Color(0xFF667EEA),
                  onTap: () {
                    Navigator.pop(context);
                    _clearForm();
                  },
                ),
                _buildActionOption(
                  icon: Icons.analytics_rounded,
                  label: 'View Reports',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _viewPartyReports(partyData),
                ),
                _buildActionOption(
                  icon: Icons.share_rounded,
                  label: 'Share Details',
                  color: const Color(0xFF06B6D4),
                  onTap: () => _sharePartyDetails(partyData),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back to Parties',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createBusinessDocument(Map<String, dynamic> partyData) {
    Navigator.pop(context);
    if (partyData['partyCategory'] == 'Customer') {
      _showSnackBar('Creating sale invoice for ${partyData['partyName']}',
          const Color(0xFF10B981), Icons.receipt);
    } else {
      _showSnackBar('Creating purchase order for ${partyData['partyName']}',
          const Color(0xFF3B82F6), Icons.shopping_cart);
    }
  }

  void _viewPartyReports(Map<String, dynamic> partyData) {
    Navigator.pop(context);
    _showSnackBar('Opening reports for ${partyData['partyName']}',
        const Color(0xFF8B5CF6), Icons.analytics);
  }

  void _sharePartyDetails(Map<String, dynamic> partyData) {
    Navigator.pop(context);
    final message = '''🏢 *${partyData['partyCategory']} Details*

👤 Name: ${partyData['partyName']}
📞 Contact: ${partyData['contactNumber']}
📧 Email: ${partyData['emailAddress']}
🏷️ Type: ${partyData['partyType']}
💰 Opening Balance: ₹${partyData['openingBalance']}
⚖️ Balance Type: ${partyData['balanceType']}
📅 As of Date: ${DateFormat('dd MMM, yyyy').format((partyData['asOfDate'] as Timestamp).toDate())}
${partyData['isGstRegistered'] ? '🏛️ GST: ${partyData['gstNumber']}' : ''}
💳 Credit Limit: ₹${partyData['creditLimit']}

Generated by Business Management System''';

    Clipboard.setData(ClipboardData(text: message));
    _showSnackBar('Party details copied to clipboard!', const Color(0xFF06B6D4), Icons.copy);
  }

  void _clearForm() {
    _partyNameController.clear();
    _contactController.clear();
    _emailController.clear();
    _openingBalController.clear();
    _billingAddressController.clear();
    _shippingAddressController.clear();
    _gstNumberController.clear();
    _panNumberController.clear();
    _creditLimitController.clear();
    _bankNameController.clear();
    _accountNumberController.clear();
    _ifscCodeController.clear();

    setState(() {
      _asOfDate = DateTime.now();
      _balanceType = 'To Pay';
      _partyCategory = 'Customer';
      _partyType = 'B2C';
      _paymentTerms = 'Immediate';
      _isGstRegistered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Add New Party',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Enhanced Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _partyCategory == 'Customer'
                          ? Icons.person_add_rounded
                          : Icons.business_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New $_partyCategory',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Complete business profile for GST compliance',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main Form Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Party Category Selection
                  const Text(
                    'Party Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Customer',
                          'Sales & Receivables',
                          Icons.person_rounded,
                          const Color(0xFF10B981),
                          _partyCategory == 'Customer',
                              () => setState(() => _partyCategory = 'Customer'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          'Supplier',
                          'Purchases & Payables',
                          Icons.business_rounded,
                          const Color(0xFF3B82F6),
                          _partyCategory == 'Supplier',
                              () => setState(() => _partyCategory = 'Supplier'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Basic Information
                  _buildInputField(
                    label: 'Party Name',
                    controller: _partyNameController,
                    isRequired: true,
                    prefixIcon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'Contact Number',
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: 'Email Address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Business Type Selection
                  _buildBusinessTypeSection(),
                  const SizedBox(height: 24),
                  // GST Registration Toggle
                  _buildGSTRegistrationSection(),
                  const SizedBox(height: 24),
                  // Tabbed Sections
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Financial'),
                        Tab(text: 'Address'),
                        Tab(text: 'Tax & Banking'),
                      ],
                      labelColor: const Color(0xFF667EEA),
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFinancialTab(),
                        _buildAddressTab(),
                        _buildTaxBankingTab(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _clearForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF667EEA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Clear Form',
                            style: TextStyle(
                              color: Color(0xFF667EEA),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addParty,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                                : const Text(
                              'Save Party',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, IconData icon,
      Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
              : null,
          color: !isSelected ? const Color(0xFFF1F5F9) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _partyType = 'B2B'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _partyType == 'B2B'
                        ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    )
                        : null,
                    color: _partyType != 'B2B'
                        ? const Color(0xFFF1F5F9)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _partyType == 'B2B'
                          ? Colors.transparent
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_rounded,
                        color: _partyType == 'B2B'
                            ? Colors.white
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'B2B (Business)',
                        style: TextStyle(
                          color: _partyType == 'B2B'
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _partyType = 'B2C'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _partyType == 'B2C'
                        ? const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                    )
                        : null,
                    color: _partyType != 'B2C'
                        ? const Color(0xFFF1F5F9)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _partyType == 'B2C'
                          ? Colors.transparent
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: _partyType == 'B2C'
                            ? Colors.white
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'B2C (Consumer)',
                        style: TextStyle(
                          color: _partyType == 'B2C'
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGSTRegistrationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isGstRegistered
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isGstRegistered
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isGstRegistered ? Icons.verified_rounded : Icons.business_rounded,
            color: _isGstRegistered
                ? const Color(0xFF10B981)
                : const Color(0xFF667EEA),
            size: 24,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GST Registration',
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Enable for GST-compliant invoicing',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isGstRegistered,
            onChanged: (value) {
              setState(() {
                _isGstRegistered = value;
                if (!_isGstRegistered) {
                  _gstNumberController.clear();
                  _panNumberController.clear();
                }
              });
            },
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Opening Balance',
                  controller: _openingBalController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'As of Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Color(0xFF667EEA), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_asOfDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balance Type
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _balanceType = 'To Receive'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _balanceType == 'To Receive'
                          ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      )
                          : null,
                      color: _balanceType != 'To Receive'
                          ? const Color(0xFFF1F5F9)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _balanceType == 'To Receive'
                            ? Colors.transparent
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'To Receive',
                      style: TextStyle(
                        color: _balanceType == 'To Receive'
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _balanceType = 'To Pay'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _balanceType == 'To Pay'
                          ? const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      )
                          : null,
                      color: _balanceType != 'To Pay'
                          ? const Color(0xFFF1F5F9)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _balanceType == 'To Pay'
                            ? Colors.transparent
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'To Pay',
                      style: TextStyle(
                        color: _balanceType == 'To Pay'
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Credit Limit',
            controller: _creditLimitController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 16),
          // Payment Terms
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Terms',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentTerms,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: ['Immediate', '15 Days', '30 Days', '45 Days', '60 Days']
                    .map((term) => DropdownMenuItem(
                  value: term,
                  child: Text(term),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _paymentTerms = value!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInputField(
            label: 'Billing Address',
            controller: _billingAddressController,
            maxLines: 3,
            prefixIcon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Shipping Address',
            controller: _shippingAddressController,
            maxLines: 3,
            prefixIcon: Icons.local_shipping_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _billingAddressController.text == _shippingAddressController.text,
                onChanged: (value) {
                  if (value == true) {
                    _shippingAddressController.text = _billingAddressController.text;
                  }
                },
                activeColor: const Color(0xFF667EEA),
              ),
              const Expanded(
                child: Text(
                  'Same as billing address',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBankingTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_isGstRegistered) ...[
            _buildInputField(
              label: 'GST Number',
              controller: _gstNumberController,
              prefixIcon: Icons.receipt_long_rounded,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'PAN Number',
              controller: _panNumberController,
              prefixIcon: Icons.credit_card_rounded,
            ),
            const SizedBox(height: 16),
          ],
          _buildInputField(
            label: 'Bank Name',
            controller: _bankNameController,
            prefixIcon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Account Number',
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: 'IFSC Code',
                  controller: _ifscCodeController,
                  prefixIcon: Icons.code_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isRequired ? const Color(0xFF667EEA) : const Color(0xFF4A5568),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF667EEA), size: 20)
                : null,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667EEA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _asOfDate) {
      setState(() {
        _asOfDate = picked;
      });
    }
  }

  void _showSnackBar(String message, Color color, [IconData? icon]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (color == Colors.green ? Icons.check_circle : Icons.info_outline),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
