import 'dart:math';

/// Plant watering profiles
enum PlantProfile {
  succulent,
  succulentLarge,
  tropicalBroadleaf,
  herbaceous,
  woodyPotted,
  largePalmIndoor,
}

/// Visual soil state assessment
enum VisualSoilState {
  wet,
  moist,
  slightlyDry,
  dry,
  veryDry,
  notVisible,
}

/// Watering calculation result
class WateringResult {
  final int amountMl;
  final List<int> rangeMl;
  final int? nextAfterWateringInHours;
  final int? nextCheckInHours;
  final String mode; // 'after_watering' or 'recheck_only'
  final String reason;
  
  WateringResult({
    required this.amountMl,
    required this.rangeMl,
    this.nextAfterWateringInHours,
    this.nextCheckInHours,
    required this.mode,
    required this.reason,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'amount_ml': amountMl,
      'range_ml': rangeMl,
      'next_after_watering_in_hours': nextAfterWateringInHours,
      'next_check_in_hours': nextCheckInHours,
      'mode': mode,
      'reason': reason,
    };
  }
}

/// Container dimensions
class ContainerDimensions {
  final double potDiameterCm;
  final double potHeightCm;
  
  ContainerDimensions({
    required this.potDiameterCm,
    required this.potHeightCm,
  });
}

/// Plant dimensions (for no-pot scenario)
class PlantDimensions {
  final double plantHeightCm;
  final double plantCanopyDiameterCm;
  
  PlantDimensions({
    required this.plantHeightCm,
    required this.plantCanopyDiameterCm,
  });
}

/// Scientific watering calculation service based on plant profiles, soil state, and container size
class WateringCalculatorService {
  
  /// Calculate substrate volume from pot dimensions
  static double calculatePotVolume(ContainerDimensions container) {
    // substrate_volume_ml = π * (d_cm / 2)^2 * h_cm * 0.8
    final radius = container.potDiameterCm / 2;
    final volume = pi * radius * radius * container.potHeightCm * 0.8;
    return volume;
  }
  
  /// Calculate equivalent root volume for ground-grown plants
  static double calculateEquivalentRootVolume(PlantDimensions plant) {
    // equiv_root_radius_cm = max( plant_canopy_diam_cm / 2 , plant_height_cm * 0.05 )
    final canopyRadius = plant.plantCanopyDiameterCm / 2;
    final heightBasedRadius = plant.plantHeightCm * 0.05;
    final equivRadius = max(canopyRadius, heightBasedRadius);
    
    // equiv_depth_cm = clamp( plant_height_cm * 0.12 , 10 , 60 )
    final depthCalculated = plant.plantHeightCm * 0.12;
    final equivDepth = depthCalculated.clamp(10.0, 60.0);
    
    // equiv_substrate_volume_ml = π * equiv_root_radius_cm^2 * equiv_depth_cm * 0.6
    final equivVolume = pi * equivRadius * equivRadius * equivDepth * 0.6;
    return equivVolume;
  }
  
  /// Get base fraction by plant profile
  static List<double> getBaseFraction(PlantProfile profile) {
    switch (profile) {
      case PlantProfile.succulent:
        return [0.015, 0.03];
      case PlantProfile.succulentLarge:
        return [0.02, 0.04];
      case PlantProfile.herbaceous:
        return [0.15, 0.25];
      case PlantProfile.tropicalBroadleaf:
        return [0.18, 0.30];
      case PlantProfile.woodyPotted:
        return [0.10, 0.20];
      case PlantProfile.largePalmIndoor:
        return [0.03, 0.06];
    }
  }
  
  /// Get soil moisture multiplier
  static double getSoilMultiplier(VisualSoilState soilState) {
    switch (soilState) {
      case VisualSoilState.wet:
      case VisualSoilState.moist:
        return 0.0; // No watering needed
      case VisualSoilState.slightlyDry:
        return 0.7;
      case VisualSoilState.dry:
      case VisualSoilState.notVisible:
        return 1.0;
      case VisualSoilState.veryDry:
        return 1.15;
    }
  }
  
  /// Get session cap fraction by profile group
  static double getSessionCapFraction(PlantProfile profile) {
    switch (profile) {
      case PlantProfile.succulent:
      case PlantProfile.succulentLarge:
        return 0.06;
      case PlantProfile.woodyPotted:
        return 0.25;
      case PlantProfile.herbaceous:
      case PlantProfile.tropicalBroadleaf:
        return 0.35;
      case PlantProfile.largePalmIndoor:
        return 0.10;
    }
  }
  
  /// Get baseline watering interval in hours
  static int getBaselineHours(PlantProfile profile) {
    switch (profile) {
      case PlantProfile.succulent:
        return 240; // 10 days
      case PlantProfile.succulentLarge:
        return 336; // 14 days
      case PlantProfile.herbaceous:
        return 96; // 4 days
      case PlantProfile.tropicalBroadleaf:
        return 120; // 5 days (average of 96-144)
      case PlantProfile.woodyPotted:
        return 168; // 7 days
      case PlantProfile.largePalmIndoor:
        return 240; // 10 days
    }
  }
  
  /// Get pot volume modifier
  static double getPotModifier(double volumeMl) {
    if (volumeMl < 1000) return 0.6;
    if (volumeMl >= 1000 && volumeMl < 3000) return 0.8;
    if (volumeMl >= 3000 && volumeMl < 10000) return 1.0;
    if (volumeMl >= 10000 && volumeMl < 30000) return 1.2;
    return 1.4; // >= 30000 ml
  }
  
  /// Round to nearest 10 or 100 ml
  static int roundAmount(double amount) {
    if (amount < 1000) {
      return ((amount / 10).round() * 10).toInt();
    } else {
      return ((amount / 100).round() * 100).toInt();
    }
  }
  
  /// Round to nearest 6 hours
  static int roundTo6Hours(double hours) {
    return ((hours / 6).round() * 6).toInt();
  }
  
  /// Calculate watering amount and schedule
  static WateringResult calculateWatering({
    required PlantProfile profile,
    required VisualSoilState soilState,
    required double effectiveVolumeMl,
    double personalizationK = 1.0,
    bool hasPot = true,
    ContainerDimensions? container,
    PlantDimensions? plantDims,
  }) {
    print('🌱 Watering Calculator: profile=$profile, soil=$soilState, volume=${effectiveVolumeMl.toInt()}ml');
    
    // Handle wet/moist soil - recheck only
    if (soilState == VisualSoilState.wet || soilState == VisualSoilState.moist) {
      // Random next check: 24, 48, or 72 hours
      final checkOptions = [24, 48, 72];
      final nextCheck = checkOptions[Random().nextInt(checkOptions.length)];
      
      return WateringResult(
        amountMl: 0,
        rangeMl: [0, 0],
        nextCheckInHours: nextCheck,
        mode: 'recheck_only',
        reason: 'Soil is ${soilState.name}. No watering needed.',
      );
    }
    
    // Calculate base watering amount
    final baseFractions = getBaseFraction(profile);
    final baseMin = effectiveVolumeMl * baseFractions[0];
    final baseMax = effectiveVolumeMl * baseFractions[1];
    final baseAvg = (baseMin + baseMax) / 2;
    
    // Apply soil multiplier
    final soilMult = getSoilMultiplier(soilState);
    final amountRaw = baseAvg * soilMult;
    
    // Apply session cap
    final capFraction = getSessionCapFraction(profile);
    final amountCapped = min(amountRaw, effectiveVolumeMl * capFraction);
    
    // Round the amount
    final amountMl = roundAmount(amountCapped);
    final rangeMin = roundAmount(amountMl * 0.8);
    final rangeMax = roundAmount(amountMl * 1.2);
    
    // Calculate next watering interval
    final baselineH = getBaselineHours(profile).toDouble();
    final mPot = getPotModifier(effectiveVolumeMl);
    
    double mSoil;
    switch (soilState) {
      case VisualSoilState.slightlyDry:
        mSoil = 0.9;
        break;
      case VisualSoilState.dry:
      case VisualSoilState.notVisible:
        mSoil = 1.0;
        break;
      case VisualSoilState.veryDry:
        mSoil = 1.1;
        break;
      default:
        mSoil = 1.0;
    }
    
    // M_amount = clamp( 0.9 + 0.00005 × amount_ml , 0.85 , 1.20 )
    final mAmount = (0.9 + 0.00005 * amountMl).clamp(0.85, 1.20);
    final mPersonal = personalizationK;
    
    final nextAfterWateringHours = roundTo6Hours(
      baselineH * mPot * mSoil * mAmount * mPersonal
    );
    
    return WateringResult(
      amountMl: amountMl,
      rangeMl: [rangeMin, rangeMax],
      nextAfterWateringInHours: nextAfterWateringHours,
      mode: 'after_watering',
      reason: '$profile: ${amountMl}ml (${effectiveVolumeMl.toInt()}ml vol × ${baseFractions[0]}-${baseFractions[1]} × ${soilMult} soil)',
    );
  }
  
  /// Parse plant profile from AI response
  static PlantProfile parsePlantProfile(String? aiName, String? species) {
    final name = (aiName ?? species ?? '').toLowerCase();
    
    // Large cacti
    if (name.contains('saguaro') || name.contains('organ pipe') || name.contains('prickly pear')) {
      return PlantProfile.succulentLarge;
    }
    
    // Regular succulents/cacti
    if (name.contains('cactus') || name.contains('succulent') || 
        name.contains('aloe') || name.contains('jade') ||
        name.contains('haworthia') || name.contains('echeveria') ||
        species?.toLowerCase().contains('cactaceae') == true) {
      return PlantProfile.succulent;
    }
    
    // Herbs
    if (name.contains('herb') || name.contains('basil') || name.contains('mint') ||
        name.contains('rosemary') || name.contains('thyme') || name.contains('oregano')) {
      return PlantProfile.herbaceous;
    }
    
    // Large palms
    if (name.contains('palm') || name.contains('areca') || name.contains('fan palm')) {
      return PlantProfile.largePalmIndoor;
    }
    
    // Woody/trees
    if (name.contains('tree') || name.contains('bonsai') || species?.toLowerCase().contains('tree') == true) {
      return PlantProfile.woodyPotted;
    }
    
    // Tropical broadleaf (default for most houseplants)
    if (name.contains('monstera') || name.contains('philodendron') || 
        name.contains('fiddle leaf') || name.contains('bird of paradise') ||
        name.contains('pothos') || name.contains('calathea')) {
      return PlantProfile.tropicalBroadleaf;
    }
    
    // Default to tropical broadleaf
    return PlantProfile.tropicalBroadleaf;
  }
  
  /// Parse soil state from AI response
  static VisualSoilState parseSoilState(String? description) {
    if (description == null) return VisualSoilState.notVisible;
    
    final desc = description.toLowerCase();
    
    if (desc.contains('wet') || desc.contains('soggy')) return VisualSoilState.wet;
    if (desc.contains('moist') || desc.contains('damp')) return VisualSoilState.moist;
    if (desc.contains('slightly dry') || desc.contains('somewhat dry')) return VisualSoilState.slightlyDry;
    if (desc.contains('very dry') || desc.contains('extremely dry')) return VisualSoilState.veryDry;
    if (desc.contains('dry')) return VisualSoilState.dry;
    
    return VisualSoilState.notVisible;
  }
  
  /// Convert pot size text to dimensions
  static ContainerDimensions parsePotDimensions(String? potSizeText, String? plantSizeText) {
    if (potSizeText == null || potSizeText == 'none' || potSizeText == 'unknown') {
      // Return default dimensions for unknown pots
      return ContainerDimensions(potDiameterCm: 10, potHeightCm: 12);
    }
    
    // Try to extract numeric dimensions
    final diameter = _extractNumericDimension(potSizeText, 'diameter');
    final height = diameter * 1.2; // Assume height is 1.2x diameter
    
    return ContainerDimensions(potDiameterCm: diameter, potHeightCm: height);
  }
  
  /// Extract numeric dimension from text
  static double _extractNumericDimension(String text, String type) {
    // Look for numbers followed by cm or inches
    final cmPattern = RegExp(r'(\d+(?:\.\d+)?)\s*cm');
    final inchPattern = RegExp(r'(\d+(?:\.\d+)?)\s*in');
    
    final cmMatch = cmPattern.firstMatch(text.toLowerCase());
    if (cmMatch != null) {
      return double.parse(cmMatch.group(1)!);
    }
    
    final inchMatch = inchPattern.firstMatch(text.toLowerCase());
    if (inchMatch != null) {
      return double.parse(inchMatch.group(1)!) * 2.54; // Convert inches to cm
    }
    
    // Fallback to size-based estimates
    if (text.contains('small') || text.contains('4') || text.contains('mini')) {
      return type == 'diameter' ? 10 : 12;
    } else if (text.contains('large') || text.contains('12') || text.contains('big')) {
      return type == 'diameter' ? 25 : 30;
    } else {
      // Medium
      return type == 'diameter' ? 15 : 18;
    }
  }
}

