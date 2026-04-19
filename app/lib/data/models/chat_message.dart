class ChatMessageModel {
  final String role; // "user" or "assistant"
  final String content;

  ChatMessageModel({required this.role, required this.content});
}
