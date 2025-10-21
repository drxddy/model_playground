import 'package:okara_chat/models/model_response.dart';

class TokenCalculator {
  // Rough estimation: 1 token ≈ 4 characters.
  // For production, a more accurate tokenizer like `tiktoken` should be used.
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
    // Note: These prices are for demonstration and should be verified.
    switch (model) {
      case AIModel.openaiGpt4o:
        return ModelPricing(inputPerMillion: 5.0, outputPerMillion: 15.0);
      case AIModel.anthropicClaude:
        return ModelPricing(inputPerMillion: 3.0, outputPerMillion: 15.0);
      case AIModel.xaiGrok:
        // Pricing for Grok-2 is not publicly available as of writing.
        // Using a placeholder value.
        return ModelPricing(inputPerMillion: 7.0, outputPerMillion: 21.0);
    }
  }
}

class ModelPricing {
  final double inputPerMillion;
  final double outputPerMillion;

  ModelPricing({required this.inputPerMillion, required this.outputPerMillion});
}
