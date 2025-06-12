import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'dart:io';

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({super.key});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form controllers
  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _openingBalController = TextEditingController();
  final TextEditingController _billingAddressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();

  DateTime _asOfDate = DateTime.now();
  String _balanceType = 'To Pay'; // 'To Pay' or 'To Receive'
  bool _isLoading = false;
  late TabController _tabController;
  bool _showCreditLimitField = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _partyNameController.dispose();
    _contactController.dispose();
    _openingBalController.dispose();
    _billingAddressController.dispose();
    _emailController.dispose();
    _gstNumberController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _addParty() async {
    if (_partyNameController.text.trim().isEmpty) {
      _showSnackBar('Party name is required', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      // Remove the authentication requirement and provide fallback
      String userId = user?.uid ?? 'anonymous_user_${DateTime.now().millisecondsSinceEpoch}';

      final partyData = {
        'partyName': _partyNameController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'openingBalance': double.tryParse(_openingBalController.text) ?? 0.0,
        'balanceType': _balanceType,
        'asOfDate': Timestamp.fromDate(_asOfDate),
        'billingAddress': _billingAddressController.text.trim(),
        'emailAddress': _emailController.text.trim(),
        'gstNumber': _gstNumberController.text.trim(),
        'creditLimit': double.tryParse(_creditLimitController.text) ?? 0.0,
        'userId': userId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      final docRef = await _firestore.collection('parties').add(partyData);

      _showSnackBar('Party added successfully!', Colors.green);

      // Show options after successful addition
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
              'What would you like to do with ${partyData['partyName']}?',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Save as PDF',
                  color: const Color(0xFFEF4444),
                  onTap: () => _generatePDF(partyData),
                ),
                _buildActionOption(
                  icon: Icons.print_rounded,
                  label: 'Print',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _printPartyDetails(partyData),
                ),
                _buildActionOption(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: const Color(0xFF10B981),
                  onTap: () => _sharePartyDetails(partyData),
                ),
                _buildActionOption(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'New Party',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    _clearForm();
                  },
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

  Widget _buildActionOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(Map<String, dynamic> partyData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Party Details', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _buildPdfRow('Party Name', partyData['partyName'] ?? 'N/A'),
              _buildPdfRow('Contact Number', partyData['contactNumber'] ?? 'N/A'),
              _buildPdfRow('Opening Balance', '₹${partyData['openingBalance']?.toString() ?? '0.0'}'),
              _buildPdfRow('Balance Type', partyData['balanceType'] ?? 'N/A'),
              _buildPdfRow('As of Date', DateFormat('dd/MM/yyyy').format((partyData['asOfDate'] as Timestamp).toDate())),
              _buildPdfRow('Billing Address', partyData['billingAddress'] ?? 'N/A'),
              _buildPdfRow('Email Address', partyData['emailAddress'] ?? 'N/A'),
              _buildPdfRow('GST Number', partyData['gstNumber'] ?? 'N/A'),
              _buildPdfRow('Credit Limit', '₹${partyData['creditLimit']?.toString() ?? '0.0'}'),
              pw.SizedBox(height: 40),
              pw.Text('Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${partyData['partyName']}_details.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);
      _showSnackBar('PDF saved to ${file.path}', Colors.green);

      // Open the PDF
      Share.shareXFiles([XFile(file.path)], text: 'Party Details for ${partyData['partyName']}');
    } catch (e) {
      _showSnackBar('Error generating PDF: $e', Colors.red);
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _printPartyDetails(Map<String, dynamic> partyData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Party Details', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _buildPdfRow('Party Name', partyData['partyName'] ?? 'N/A'),
              _buildPdfRow('Contact Number', partyData['contactNumber'] ?? 'N/A'),
              _buildPdfRow('Opening Balance', '₹${partyData['openingBalance']?.toString() ?? '0.0'}'),
              _buildPdfRow('Balance Type', partyData['balanceType'] ?? 'N/A'),
              _buildPdfRow('As of Date', DateFormat('dd/MM/yyyy').format((partyData['asOfDate'] as Timestamp).toDate())),
              _buildPdfRow('Billing Address', partyData['billingAddress'] ?? 'N/A'),
              _buildPdfRow('Email Address', partyData['emailAddress'] ?? 'N/A'),
              _buildPdfRow('GST Number', partyData['gstNumber'] ?? 'N/A'),
              _buildPdfRow('Credit Limit', '₹${partyData['creditLimit']?.toString() ?? '0.0'}'),
              pw.SizedBox(height: 40),
              pw.Text('Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    try {
      Navigator.pop(context);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${partyData['partyName']}_details.pdf',
      );
    } catch (e) {
      _showSnackBar('Error printing: $e', Colors.red);
    }
  }

  void _sharePartyDetails(Map<String, dynamic> partyData) {
    final message = '''
🏢 *Party Details*

👤 Name: ${partyData['partyName']}
📞 Contact: ${partyData['contactNumber']}
💰 Opening Balance: ₹${partyData['openingBalance']}
⚖️ Balance Type: ${partyData['balanceType']}
📅 As of Date: ${DateFormat('dd/MM/yyyy').format((partyData['asOfDate'] as Timestamp).toDate())}
📧 Email: ${partyData['emailAddress']}
🏛️ GST Number: ${partyData['gstNumber']}
💳 Credit Limit: ₹${partyData['creditLimit']}

Generated by Business Management App
    ''';

    Navigator.pop(context);
    Share.share(message, subject: 'Party Details for ${partyData['partyName']}');
  }

  Future<void> _saveAndNew() async {
    if (_partyNameController.text.trim().isEmpty) {
      _showSnackBar('Party name is required', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      // Remove the authentication requirement and provide fallback
      String userId = user?.uid ?? 'anonymous_user_${DateTime.now().millisecondsSinceEpoch}';

      final partyData = {
        'partyName': _partyNameController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'openingBalance': double.tryParse(_openingBalController.text) ?? 0.0,
        'balanceType': _balanceType,
        'asOfDate': Timestamp.fromDate(_asOfDate),
        'billingAddress': _billingAddressController.text.trim(),
        'emailAddress': _emailController.text.trim(),
        'gstNumber': _gstNumberController.text.trim(),
        'creditLimit': double.tryParse(_creditLimitController.text) ?? 0.0,
        'userId': userId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('parties').add(partyData);

      _showSnackBar('Party added successfully!', Colors.green);
      _clearForm();
    } catch (e) {
      _showSnackBar('Error adding party: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _partyNameController.clear();
    _contactController.clear();
    _openingBalController.clear();
    _billingAddressController.clear();
    _emailController.clear();
    _gstNumberController.clear();
    _creditLimitController.clear();
    setState(() {
      _asOfDate = DateTime.now();
      _balanceType = 'To Pay';
      _showCreditLimitField = false;
    });
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

  void _addFromContacts() {
    _showSnackBar('Contact integration will be implemented', Colors.blue);
  }

  void _showCreditLimitInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF667EEA)),
            SizedBox(width: 12),
            Text(
              'Credit Limit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a credit limit for this party. You will be notified when transactions exceed this limit.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4A5568),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Benefits:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Control your financial exposure\n• Get alerts for high-value transactions\n• Manage credit risk effectively',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF718096),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showCreditLimitField = true;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Set Limit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.info_outline,
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
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_outline, color: Color(0xFF667EEA)),
            ),
            onPressed: () {
              _showSnackBar('Help documentation will be available soon', Colors.blue);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
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
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Party',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Add customer or supplier details',
                          style: TextStyle(
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
                  // Party Name
                  _buildInputField(
                    label: 'Party Name',
                    controller: _partyNameController,
                    isRequired: true,
                    prefixIcon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _addFromContacts,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.contact_phone_rounded,
                          color: Color(0xFF667EEA),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Add party through contacts',
                          style: TextStyle(
                            color: Color(0xFF667EEA),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact Number
                  _buildInputField(
                    label: 'Contact Number',
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Opening Balance and As of Date
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'Opening Balance',
                          controller: _openingBalController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.currency_rupee_rounded,
                          onTap: () {
                            _showSnackBar(
                              'Enter the initial balance for this party',
                              const Color(0xFF3B82F6),
                            );
                          },
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A5568),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_asOfDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF667EEA),
                                      size: 20,
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
                  const SizedBox(height: 24),

                  // Balance Type
                  const Text(
                    'Balance Type',
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
                          onTap: () {
                            setState(() {
                              _balanceType = 'To Receive';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: _balanceType == 'To Receive'
                                  ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                                  : null,
                              color: _balanceType != 'To Receive'
                                  ? const Color(0xFFF1F5F9)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _balanceType == 'To Receive'
                                    ? Colors.transparent
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: _balanceType == 'To Receive'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'To Receive',
                                  style: TextStyle(
                                    color: _balanceType == 'To Receive'
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
                          onTap: () {
                            setState(() {
                              _balanceType = 'To Pay';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: _balanceType == 'To Pay'
                                  ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              )
                                  : null,
                              color: _balanceType != 'To Pay'
                                  ? const Color(0xFFF1F5F9)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _balanceType == 'To Pay'
                                    ? Colors.transparent
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  color: _balanceType == 'To Pay'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'To Pay',
                                  style: TextStyle(
                                    color: _balanceType == 'To Pay'
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
                  const SizedBox(height: 24),

                  // Credit Limit
                  if (!_showCreditLimitField)
                    GestureDetector(
                      onTap: _showCreditLimitInfo,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.credit_card_rounded,
                                color: Color(0xFF667EEA),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Set Credit Limit',
                                    style: TextStyle(
                                      color: Color(0xFF2D3748),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Control your financial exposure',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF64748B),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildInputField(
                      label: 'Credit Limit',
                      controller: _creditLimitController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.credit_card_rounded,
                    ),
                  const SizedBox(height: 24),

                  // Tabs for Address and GST
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Addresses'),
                        Tab(text: 'GST Details'),
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
                    height: 200,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAddressesTab(),
                        _buildGstDetailsTab(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF667EEA),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Parties are people you do business with. Use them for invoices and to keep track of your payables & receivables.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _saveAndNew,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF667EEA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Save & New',
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

  Widget _buildAddressesTab() {
    return Column(
      children: [
        _buildInputField(
          label: 'Billing Address',
          controller: _billingAddressController,
          maxLines: 3,
          prefixIcon: Icons.location_on_rounded,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Email Address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_rounded,
        ),
      ],
    );
  }

  Widget _buildGstDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'GST Number',
          controller: _gstNumberController,
          prefixIcon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'GST number format: 22AAAAA0000A1Z5',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    int maxLines = 1,
    IconData? prefixIcon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
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
                  fontSize: 16,
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
          onTap: onTap,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
              prefixIcon,
              color: const Color(0xFF667EEA),
            )
                : null,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}