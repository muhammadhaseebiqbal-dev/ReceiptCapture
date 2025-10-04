import 'dart:math';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  // Common company name patterns and known retailers
  static const List<String> knownCompanies = [
    'walmart',
    'target',
    'amazon',
    'starbucks',
    'mcdonalds',
    'mcdonald\'s',
    'home depot',
    'homedepot',
    'best buy',
    'bestbuy',
    'costco',
    'cvs',
    'walgreens',
    'kroger',
    'publix',
    'safeway',
    'whole foods',
    'wholefoods',
    'trader joe\'s',
    'traderjoes',
    'shell',
    'exxon',
    'bp',
    'chevron',
    'subway',
    'chipotle',
    'panera',
    'taco bell',
    'pizza hut',
    'dominos',
    'kfc',
    'burger king',
    'wendy\'s',
    'dunkin',
    'tim hortons',
    'apple',
    'microsoft',
    'google',
    'netflix',
    'spotify',
    'uber',
    'lyft',
  ];

  // Extract text from image (simplified simulation)
  Future<Map<String, dynamic>> extractTextFromImage(String imagePath) async {
    // In a real implementation, this would use:
    // - Google ML Kit OCR
    // - Firebase ML Vision
    // - Azure Computer Vision
    // - AWS Textract
    // - Tesseract OCR

    // For now, we'll simulate OCR with more realistic patterns
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Simulate processing time

    // Generate realistic receipt data based on image analysis patterns
    return _generateRealisticReceiptData(imagePath);
  }

  Map<String, dynamic> _generateRealisticReceiptData(String imagePath) {
    final random = Random();

    // Analyze image name/path for hints (in real OCR, this would be actual text analysis)
    final fileName = imagePath.toLowerCase();

    String? detectedCompany;
    double? detectedAmount;

    // Check if filename contains any known company names
    for (final company in knownCompanies) {
      if (fileName.contains(company.toLowerCase())) {
        detectedCompany = _formatCompanyName(company);
        break;
      }
    }

    // If no company detected from filename, don't guess randomly
    if (detectedCompany == null) {
      // For mock OCR, return null instead of random company names
      // This will let the UI show "Unnamed Receipt" instead of random companies
      detectedCompany = null;
    }

    // Generate realistic amount based on company type
    if (detectedCompany != null) {
      detectedAmount = _generateRealisticAmountForCompany(detectedCompany);
    } else {
      // Random amount for unrecognized receipt
      detectedAmount = _generateRandomAmount();
    }

    // Simulate additional extracted data
    return {
      'company': detectedCompany, // Will be null for unrecognized receipts
      'amount': detectedAmount,
      'confidence': random.nextDouble() * 0.3 + 0.7, // 70-100% confidence
      'date': DateTime.now().subtract(Duration(days: random.nextInt(30))),
      'extractedText': _generateSimulatedText(detectedCompany, detectedAmount),
    };
  }

  String _formatCompanyName(String company) {
    // Capitalize and format company names properly
    return company
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  double _generateRealisticAmountForCompany(String company) {
    final random = Random();
    final companyLower = company.toLowerCase();

    // Generate amounts based on typical spending at different types of businesses
    if (companyLower.contains('starbucks') || companyLower.contains('dunkin')) {
      // Coffee shops: $3-15
      return 3.0 + random.nextDouble() * 12.0;
    } else if (companyLower.contains('mcdonald') ||
        companyLower.contains('subway') ||
        companyLower.contains('taco bell')) {
      // Fast food: $5-25
      return 5.0 + random.nextDouble() * 20.0;
    } else if (companyLower.contains('walmart') ||
        companyLower.contains('target') ||
        companyLower.contains('costco')) {
      // Retail stores: $15-200
      return 15.0 + random.nextDouble() * 185.0;
    } else if (companyLower.contains('gas') ||
        companyLower.contains('shell') ||
        companyLower.contains('exxon')) {
      // Gas stations: $20-80
      return 20.0 + random.nextDouble() * 60.0;
    } else if (companyLower.contains('grocery') ||
        companyLower.contains('kroger') ||
        companyLower.contains('publix')) {
      // Grocery stores: $25-150
      return 25.0 + random.nextDouble() * 125.0;
    } else {
      // General business: $10-100
      return 10.0 + random.nextDouble() * 90.0;
    }
  }

  double _generateRandomAmount() {
    final random = Random();
    // Generate amount between $5-200 with realistic cents
    final dollars = 5 + random.nextInt(195);
    final cents = [0, 25, 50, 75, 99][random.nextInt(5)]; // Common cent amounts
    return dollars + (cents / 100.0);
  }

  String _generateSimulatedText(String? company, double? amount) {
    // Simulate extracted text that would come from OCR
    final random = Random();
    final lines = <String>[];

    if (company != null) {
      lines.add(company.toUpperCase());
      lines.add('Store #${1000 + random.nextInt(9000)}');
    }

    lines.add('${DateTime.now().toString().substring(0, 10)} ${_randomTime()}');
    lines.add(
      'Transaction ID: ${random.nextInt(999999).toString().padLeft(6, '0')}',
    );
    lines.add('');

    // Add some random items
    final items = ['Item A', 'Product B', 'Service C', 'Fee D'];
    for (int i = 0; i < random.nextInt(3) + 1; i++) {
      final itemPrice = (random.nextDouble() * 20 + 1).toStringAsFixed(2);
      lines.add('${items[random.nextInt(items.length)]}\t\$${itemPrice}');
    }

    lines.add('');
    if (amount != null) {
      lines.add('TOTAL\t\$${amount.toStringAsFixed(2)}');
    }

    return lines.join('\n');
  }

  String _randomTime() {
    final random = Random();
    final hour = random.nextInt(12) + 1;
    final minute = random.nextInt(60);
    final ampm = random.nextBool() ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  // Extract specific patterns from text
  List<String> extractCompanyNames(String text) {
    final companies = <String>[];
    final textLower = text.toLowerCase();

    for (final company in knownCompanies) {
      if (textLower.contains(company.toLowerCase())) {
        companies.add(_formatCompanyName(company));
      }
    }

    return companies;
  }

  List<double> extractAmounts(String text) {
    final amounts = <double>[];

    // Regex patterns for common amount formats
    final patterns = [
      RegExp(r'\$(\d+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'total:?\s*\$?(\d+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'amount:?\s*\$?(\d+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'(\d+\.\d{2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0 && amount < 10000) {
            amounts.add(amount);
          }
        }
      }
    }

    return amounts;
  }
}
