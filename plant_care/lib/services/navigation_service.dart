import 'package:shared_preferences/shared_preferences.dart';

class NavigationService {
  static const String _lastPlantIdKey = 'last_plant_id';
  static const String _lastScreenKey = 'last_screen';
  
  // Save the current plant details screen state
  static Future<void> savePlantDetailsState(String plantId) async {
    print('🌱 NavigationService: Saving plant details state for plant: $plantId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlantIdKey, plantId);
    await prefs.setString(_lastScreenKey, 'plant_details');
    print('✅ NavigationService: Navigation state saved successfully');
  }
  
  // Get the last viewed plant ID
  static Future<String?> getLastPlantId() async {
    final prefs = await SharedPreferences.getInstance();
    final plantId = prefs.getString(_lastPlantIdKey);
    print('🌱 NavigationService: Retrieved last plant ID: $plantId');
    return plantId;
  }
  
  // Get the last viewed screen
  static Future<String?> getLastScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final screen = prefs.getString(_lastScreenKey);
    print('🌱 NavigationService: Retrieved last screen: $screen');
    return screen;
  }
  
  // Clear navigation state (e.g., on logout)
  static Future<void> clearNavigationState() async {
    print('🌱 NavigationService: Clearing navigation state');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPlantIdKey);
    await prefs.remove(_lastScreenKey);
    print('✅ NavigationService: Navigation state cleared');
  }
  
  // Check if user should return to plant details
  static Future<bool> shouldReturnToPlantDetails() async {
    final lastScreen = await getLastScreen();
    final lastPlantId = await getLastPlantId();
    final shouldReturn = lastScreen == 'plant_details' && lastPlantId != null;
    print('🌱 NavigationService: Should return to plant details? $shouldReturn (screen: $lastScreen, plantId: $lastPlantId)');
    return shouldReturn;
  }
} 