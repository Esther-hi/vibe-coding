import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import 'api_client_provider.dart';

class ChatState {
  final List<ChatMessageModel> messages;
  final String? sessionId;
  final bool isLoading;

  ChatState({this.messages = const [], this.sessionId, this.isLoading = false});
  ChatState copyWith({List<ChatMessageModel>? messages, String? sessionId, bool? isLoading}) =>
      ChatState(messages: messages ?? this.messages, sessionId: sessionId ?? this.sessionId, isLoading: isLoading ?? this.isLoading);
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  ChatNotifier(this._repo) : super(ChatState());

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessageModel(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final response = await _repo.sendMessage(message: text, sessionId: state.sessionId);
      final data = response['data'] ?? {};
      final assistantMsg = ChatMessageModel(role: 'assistant', content: data['response'] ?? '抱歉，我暂时无法回答。');
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        sessionId: data['session_id'] ?? state.sessionId,
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = ChatMessageModel(role: 'assistant', content: '网络错误，请稍后重试。');
      state = state.copyWith(messages: [...state.messages, errorMsg], isLoading: false);
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ChatRepository(apiClient: ref.watch(apiClientProvider))),
);
