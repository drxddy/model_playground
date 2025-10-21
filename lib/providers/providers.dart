import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:okara_chat/data/database_service.dart';
import 'package:okara_chat/data/repositories/conversation_repository.dart';
import 'package:okara_chat/services/ai_gateway_service.dart';
import 'package:okara_chat/services/parallel_response_handler.dart';
import 'package:okara_chat/services/token_calculator.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ConversationRepository(dbService);
});

final aiGatewayServiceProvider = Provider<AIGatewayService>((ref) {
  return AIGatewayService();
});

final tokenCalculatorProvider = Provider<TokenCalculator>((ref) {
  return TokenCalculator();
});

final parallelResponseHandlerProvider = Provider<ParallelResponseHandler>((
  ref,
) {
  final aiGateway = ref.watch(aiGatewayServiceProvider);
  final tokenCalculator = ref.watch(tokenCalculatorProvider);
  return ParallelResponseHandler(
    aiGateway: aiGateway,
    tokenCalculator: tokenCalculator,
  );
});
