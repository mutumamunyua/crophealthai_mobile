// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';

// ─── SPACING & STYLE CONSTANTS ──────────────────────────────────────────
const double kDefaultPadding = 16.0;
const double kBubbleRadius   = 12.0;
const double kInputHeight    = 50.0;

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // User message
      _messages.add(_ChatMessage(text: text, isUser: true));
      // Bot placeholder reply
      _messages.add(_ChatMessage(text: "Coming soon…", isUser: false));
    });

    _controller.clear();
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Expert'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Messages list ───────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  // Align right if user, left otherwise
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment:
                      msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!msg.isUser) const SizedBox(width: 40),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(kDefaultPadding / 2),
                            decoration: BoxDecoration(
                              color: msg.isUser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(kBubbleRadius),
                                topRight: Radius.circular(kBubbleRadius),
                                bottomLeft: Radius.circular(
                                    msg.isUser ? kBubbleRadius : 0),
                                bottomRight: Radius.circular(
                                    msg.isUser ? 0 : kBubbleRadius),
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: msg.isUser
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        if (msg.isUser) const SizedBox(width: 40),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── Input bar ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 4,
              ),
              color: theme.scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: kInputHeight,
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type your message…',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kBubbleRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    height: kInputHeight,
                    child: ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple message model
class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}