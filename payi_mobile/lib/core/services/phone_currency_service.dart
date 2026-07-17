class PhoneCurrencyService {
  /// Defines default currency based on the country code of the phone number.
  /// Used during user registration when extracting phone from Clerk or manually.
  static String getCurrencyFromPhone(String phoneNumber) {
    if (phoneNumber.startsWith('+1')) return 'USD';
    if (phoneNumber.startsWith('+254')) return 'KES';
    if (phoneNumber.startsWith('+234')) return 'NGN';
    if (phoneNumber.startsWith('+44')) return 'GBP';
    if (phoneNumber.startsWith('+27')) return 'ZAR';
    if (phoneNumber.startsWith('+255')) return 'TZS';
    if (phoneNumber.startsWith('+256')) return 'UGX';
    
    // Default fallback
    return 'USD';
  }

  /// Extracts standard country name from the phone prefix
  static String getCountryFromPhone(String phoneNumber) {
    if (phoneNumber.startsWith('+1')) return 'USA';
    if (phoneNumber.startsWith('+254')) return 'Kenya';
    if (phoneNumber.startsWith('+234')) return 'Nigeria';
    if (phoneNumber.startsWith('+44')) return 'UK';
    if (phoneNumber.startsWith('+27')) return 'South Africa';
    if (phoneNumber.startsWith('+255')) return 'Tanzania';
    if (phoneNumber.startsWith('+256')) return 'Uganda';
    
    // Default fallback
    return 'Global';
  }
}
