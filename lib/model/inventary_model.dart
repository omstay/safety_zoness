class InventoryItem {
  final String itemName;
  final String hsnCode;
  final double gstRate;
  final double unitPrice;
  final int currentStock;
  final InventoryStatus status;

  InventoryItem({
    required this.itemName,
    required this.hsnCode,
    required this.gstRate,
    required this.unitPrice,
    required this.currentStock,
    required this.status,
  });

  InventoryStatus get calculatedStatus {
    if (currentStock <= 3) {
      return InventoryStatus.lowStock;
    } else if (currentStock >= 15) {
      return InventoryStatus.inStock;
    } else {
      return InventoryStatus.lowStock;
    }
  }
}

enum InventoryStatus {
  lowStock,
  inStock,
}

// Sample data
class InventoryData {
  static List<InventoryItem> getSampleItems() {
    return [
      InventoryItem(
        itemName: 'Printer Ink Cartridge',
        hsnCode: '8443.99.51',
        gstRate: 18.0,
        unitPrice: 950,
        currentStock: 3,
        status: InventoryStatus.lowStock,
      ),
      InventoryItem(
        itemName: 'A4 Paper 500 Sheets',
        hsnCode: '4802.56.10',
        gstRate: 12.0,
        unitPrice: 300,
        currentStock: 7,
        status: InventoryStatus.lowStock,
      ),
      InventoryItem(
        itemName: 'Laptop Charger',
        hsnCode: '8504.40.90',
        gstRate: 18.0,
        unitPrice: 1200,
        currentStock: 2,
        status: InventoryStatus.lowStock,
      ),
      InventoryItem(
        itemName: 'Office Chair',
        hsnCode: '9401.30.00',
        gstRate: 18.0,
        unitPrice: 4500,
        currentStock: 15,
        status: InventoryStatus.inStock,
      ),
      InventoryItem(
        itemName: 'Desk Lamp LED',
        hsnCode: '9405.20.00',
        gstRate: 12.0,
        unitPrice: 850,
        currentStock: 22,
        status: InventoryStatus.inStock,
      ),
    ];
  }
}