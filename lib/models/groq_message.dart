enum GroqMessageRole {
  system,
  user,
  assistant,
}

class GroqMessageRoleParser {
  static GroqMessageRole? tryParse(String role) {
    switch (role) {
      case 'system':
        return GroqMessageRole.system;
      case 'user':
        return GroqMessageRole.user;
      case 'assistant':
        return GroqMessageRole.assistant;
      default:
        return null;
    }
  }

  static String toId(GroqMessageRole role) {
    switch (role) {
      case GroqMessageRole.system:
        return 'system';
      case GroqMessageRole.user:
        return 'user';
      case GroqMessageRole.assistant:
        return 'assistant';
    }
  }
}

class GroqMessage {
  final String content;
  final String? username;
  final GroqMessageRole role;
  final bool isToolCall;
  final List<GroqToolCall> toolCalls;

  GroqMessage({
    required this.content,
    this.role = GroqMessageRole.user,
    this.toolCalls = const [],
    this.isToolCall = false,
    this.username,
  });

  @override
  String toString() {
    return isToolCall
        ? 'GroqMessage{toolCall: $toolCalls}'
        : 'GroqMessage{content: $content, username: $username, role: $role}';
  }
}

class GroqToolCall {
  final String callId;
  final String functionName;
  final Map<String, dynamic> arguments;

  GroqToolCall({
    required this.callId,
    required this.functionName,
    required this.arguments,
  });

  @override
  String toString() {
    return 'GroqToolCall{callId: $callId, functionName: $functionName, arguments: $arguments}';
  }
}
