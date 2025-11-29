
class ChecksumUtils {
  static const String _tag = 'CHECKSUM_UTILS';

  /// Calculate SUM-based checksum for data validation
  ///
  /// [data] - String data to calculate checksum for
  /// Returns 4-digit uppercase hexadecimal checksum string
  ///
  /// Example:
  /// input: "010A1A" → checksum: "XXXX"
  ///
  /// SUM method chosen over XOR for:
  /// - Better burst error detection
  /// - More reliable for fire alarm systems
  /// - Consistent with enhanced_zone_parser implementation
  static String calculateChecksum(String data) {
    try {
      if (data.isEmpty) {
        
        return '0000';
      }

      int sum = 0;
      for (int i = 0; i < data.length; i++) {
        sum += data.codeUnitAt(i);
      }

      final checksum = sum.toRadixString(16).toUpperCase().padLeft(4, '0');

      
      return checksum;

    } catch (e) {
      
      return '0000';
    }
  }

  /// Validate data integrity using checksum
  ///
  /// [data] - Original data string
  /// [expectedChecksum] - Expected checksum to validate against
  /// Returns true if checksum matches, false otherwise
  static bool validateChecksum(String data, String expectedChecksum) {
    try {
      final calculatedChecksum = calculateChecksum(data);
      final isValid = calculatedChecksum.toUpperCase() == expectedChecksum.toUpperCase();

      

      return isValid;
    } catch (e) {
      
      return false;
    }
  }

  /// Extract and validate checksum from complete data packet
  ///
  /// Complete packet format: [DATA][CHECKSUM]
  /// [completePacket] - Full packet including data and checksum
  /// [checksumLength] - Length of checksum portion (default: 4)
  /// Returns tuple (isValid, dataOnly, expectedChecksum)
  static (bool, String, String) extractAndValidateChecksum(String completePacket, {int checksumLength = 4}) {
    try {
      if (completePacket.length <= checksumLength) {
        
        return (false, completePacket, '0000');
      }

      final dataOnly = completePacket.substring(0, completePacket.length - checksumLength);
      final expectedChecksum = completePacket.substring(completePacket.length - checksumLength);

      final isValid = validateChecksum(dataOnly, expectedChecksum);

      

      return (isValid, dataOnly, expectedChecksum);
    } catch (e) {
      
      return (false, completePacket, '0000');
    }
  }

  /// Calculate checksum for batch processing (multiple data strings)
  ///
  /// [dataList] - List of data strings to calculate batch checksum for
  /// Returns combined checksum string
  static String calculateBatchChecksum(List<String> dataList) {
    try {
      if (dataList.isEmpty) {
        return '0000';
      }

      int totalSum = 0;
      for (final data in dataList) {
        for (int i = 0; i < data.length; i++) {
          totalSum += data.codeUnitAt(i);
        }
      }

      final checksum = totalSum.toRadixString(16).toUpperCase().padLeft(4, '0');

      
      return checksum;

    } catch (e) {
      
      return '0000';
    }
  }

  /// Generate checksum for debugging and testing purposes
  ///
  /// Creates test data with known checksum for validation testing
  static (String, String) generateTestData(String baseData) {
    final checksum = calculateChecksum(baseData);
    final testData = '$baseData$checksum';

    

    return (testData, checksum);
  }

  /// Verify checksum consistency across different implementations
  ///
  /// This method can be used during migration to ensure the new unified
  /// checksum implementation produces the same results as old implementations
  static bool verifyChecksumConsistency(String data, String oldChecksum, String oldMethod) {
    final newChecksum = calculateChecksum(data);
    final isConsistent = newChecksum.toUpperCase() == oldChecksum.toUpperCase();

    
    
    
    

    return isConsistent;
  }

  /// Performance benchmark for checksum calculation
  ///
  /// Used for performance testing and optimization
  static void benchmarkChecksumCalculation(String testData, {int iterations = 1000}) {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      calculateChecksum(testData);
    }

    stopwatch.stop();

    
    
  }
}

/// Checksum validation result for detailed error reporting
class ChecksumValidationResult {
  final bool isValid;
  final String data;
  final String expectedChecksum;
  final String calculatedChecksum;
  final String? errorMessage;

  const ChecksumValidationResult({
    required this.isValid,
    required this.data,
    required this.expectedChecksum,
    required this.calculatedChecksum,
    this.errorMessage,
  });

  @override
  String toString() {
    if (isValid) {
      return 'ChecksumValidationResult(VALID: data="$data", checksum=$expectedChecksum)';
    } else {
      return 'ChecksumValidationResult(INVALID: data="$data", expected=$expectedChecksum, calculated=$calculatedChecksum, error=$errorMessage)';
    }
  }
}