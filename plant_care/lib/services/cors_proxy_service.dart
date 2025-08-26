import 'package:flutter/foundation.dart';

class CorsProxyService {
  /// Returns a CORS-free URL for Firebase Storage images on web
  static String getCorsFreeUrl(String originalUrl) {
    if (!kIsWeb) return originalUrl;
    
    // For web, we can try different approaches to bypass CORS
    // Option 1: Use a CORS proxy service (temporary solution)
    // Option 2: Use Firebase Storage with proper CORS headers (recommended)
    
    // For now, return the original URL - the user needs to fix CORS in Firebase
    return originalUrl;
  }
  
  /// Alternative method to load images that might bypass CORS
  static String getAlternativeUrl(String originalUrl) {
    if (!kIsWeb) return originalUrl;
    
    // You can add alternative image loading methods here
    // For example, using a different CDN or proxy service
    return originalUrl;
  }
  
  /// Check if the current platform is web and might have CORS issues
  static bool get hasCorsIssues => kIsWeb;
} 