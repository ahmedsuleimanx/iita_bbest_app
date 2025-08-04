class AppConstants {
  // App Info
  static const String appName = 'IITA BBEST';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Agricultural Products E-commerce Marketplace';
  
  // URLs
  static const String websiteUrl = 'https://www.iitabbest.org';
  static const String supportEmail = 'support@iitabbest.org';
  static const String privacyPolicyUrl = '$websiteUrl/privacy';
  static const String termsOfServiceUrl = '$websiteUrl/terms';
  
  // Default Values
  static const double defaultShippingFee = 5.00;
  static const double defaultTaxRate = 0.08; // 8%
  static const int defaultProductsPerPage = 20;
  static const int maxCartItems = 50;
  
  // Animation Durations
  static const Duration splashScreenDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  
  // Limits
  static const int maxSearchResultsPerPage = 20;
  static const int maxRecentSearches = 10;
  static const double minOrderAmount = 10.00;
  static const double maxOrderAmount = 10000.00;
  
  // Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String noProductsMessage = 'No products found matching your criteria.';
  static const String emptyCartMessage = 'Your cart is empty. Start shopping to add items.';
  
  // Product Categories
  static const List<String> productCategories = [
    'Animal Feed',
    'Organic Fertilizer',
    'Seeds',
    'Tools',
    'Fertilizer',
    'Pesticides',
    'Equipment',
    'Other',
  ];
  
  // Countries
  static const List<String> targetCountries = [
    'Democratic Republic of Congo',
    'Ghana',
    'Mali',
    'Niger',
  ];
  
  // Currency
  static const String defaultCurrency = 'USD';
  static const String currencySymbol = '\$';
  
  // Image Placeholders
  static const String logoAsset = 'assets/images/iita-logo.jpeg';
  static const String placeholderProductImage = 'assets/images/product-placeholder.png';
  static const String placeholderUserImage = 'assets/images/user-placeholder.png';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String cartDataKey = 'cart_data';
  static const String recentSearchesKey = 'recent_searches';
  static const String appSettingsKey = 'app_settings';
} 