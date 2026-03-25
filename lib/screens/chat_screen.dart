import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../main.dart';
import '../widgets/shared_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String? currentBreed;
  const ChatScreen({super.key, this.currentBreed});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMessage> _messages = [];
  final List<Map<String, String>> _apiMessages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _typing = false;

  static const _suggestions = [
    'What should I feed this breed?',
    'Is this breed good for Indian summers?',
    'How much exercise does it need?',
    'Is this dog good for first-time owners?',
    'What health issues should I watch for?',
  ];

  @override
  void initState() {
    super.initState();
    // Greeting message
    final greeting = widget.currentBreed != null
        ? 'Hi! 🐾 I\'m PawBot. Ask me anything about the **${widget.currentBreed}** — diet, exercise, health, India suitability, and more!'
        : 'Hi! 🐾 I\'m PawBot, your AI dog breed expert. Ask me anything about dog breeds!';
    _messages.add(_ChatMessage(text: greeting, isUser: false));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _typing) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _typing = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    _apiMessages.add({'role': 'user', 'content': trimmed});

    try {
      final reply = await AppState.of(context).api.chat(
        List.from(_apiMessages),
        currentBreed: widget.currentBreed,
      );
      _apiMessages.add({'role': 'assistant', 'content': reply});
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _typing = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Sorry, I couldn\'t connect to the server. Please check your connection.',
          isUser: false,
          isError: true,
        ));
        _typing = false;
      });
      _apiMessages.removeLast(); // remove failed user message from history
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PawBot',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700, color: kBrown, fontSize: 20)),
            if (widget.currentBreed != null)
              Text(
                'Discussing: ${widget.currentBreed}',
                style: GoogleFonts.dmSans(fontSize: 11, color: kMuted),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _typing) {
                  return const _TypingBubble();
                }
                return _Bubble(message: _messages[i]);
              },
            ),
          ),
          // Suggestion chips (only when no user message yet)
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: _suggestions
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TagChip(
                            label: s,
                            onTap: () => _send(s),
                            bg: kWarm,
                            fg: kBrown2,
                          ),
                        ))
                    .toList(),
              ),
            ),
          // Input
          _InputBar(ctrl: _ctrl, onSend: _send, disabled: _typing),
        ],
      ),
    );
  }
}

// ─── Chat Bubble ──────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const _ChatMessage(
      {required this.text, required this.isUser, this.isError = false});
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser
              ? kAmber
              : message.isError
                  ? kRedBg
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: kBrown.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: message.isUser
                ? Colors.white
                : message.isError
                    ? kRed
                    : kDark,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAmber.withOpacity(
                        0.3 + 0.7 * (((_ctrl.value + i * 0.3) % 1.0))),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSend;
  final bool disabled;

  const _InputBar(
      {required this.ctrl, required this.onSend, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: kBrown.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              enabled: !disabled,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask PawBot anything…',
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onSend(ctrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: disabled ? kMuted2 : kAmber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}