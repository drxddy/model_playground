import 'package:okara_chat/models/model_response.dart';

class TokenCalculator {
  static const int _charsPerToken = 4;

  int estimatePromptTokens(String prompt) {
    return (prompt.length / _charsPerToken).ceil();
  }

  int estimateCompletionTokens(String completion) {
    return (completion.length / _charsPerToken).ceil();
  }

  double calculateCost({
    required AIModel model,
    required int promptTokens,
    required int completionTokens,
  }) {
    final pricing = _getPricing(model);
    final promptCost = (promptTokens / 1000000) * pricing.inputPerMillion;
    final completionCost =
        (completionTokens / 1000000) * pricing.outputPerMillion;
    return promptCost + completionCost;
  }

  ModelPricing _getPricing(AIModel model) {
    switch (model) {
      case AIModel.openaiGpt4o:
        return ModelPricing(inputPerMillion: 5.0, outputPerMillion: 15.0);
      case AIModel.anthropicClaude:
        return ModelPricing(inputPerMillion: 3.0, outputPerMillion: 15.0);
      case AIModel.xaiGrok:
        return ModelPricing(inputPerMillion: 7.0, outputPerMillion: 21.0);
      case AIModel.groqLlama31Instant:
        return ModelPricing(inputPerMillion: 2.0, outputPerMillion: 8.0);
    }
  }
}

class ModelPricing {
  final double inputPerMillion;
  final double outputPerMillion;

  ModelPricing({required this.inputPerMillion, required this.outputPerMillion});
}
