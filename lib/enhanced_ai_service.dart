import 'ml_crop_service.dart';

class EnhancedAiService {
  final MlCropService _mlService = MlCropService();

  /// Gets a crop recommendation for the given soil type and season.
  /// This wrapper uses the ML model logic as primarily defined in MlCropService.
  Future<String> getCropRecommendation(String soilType, String season) async {
    return await _mlService.getRecommendation(soilType, season);
  }
}
