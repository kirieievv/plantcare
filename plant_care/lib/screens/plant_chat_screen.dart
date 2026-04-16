import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/utils/cloud_functions.dart';

class PlantChatScreen extends StatefulWidget {
  final Plant plant;

  const PlantChatScreen({super.key, required this.plant});

  @override
  State<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends State<PlantChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isLoadingHistory = true;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  CollectionReference<Map<String, dynamic>>? _messagesCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plant_chats')
        .doc(widget.plant.id)
        .collection('messages');
  }

  @override
  void initState() {
    super.initState();
    _loadMessageHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _welcomeMessage() {
    return l10n.plantChatWelcome(widget.plant.name);
  }

  List<String> _quickQuestions() {
    return [
      l10n.plantChatQuickWaterToday,
      l10n.plantChatQuickYellowLeaves,
      l10n.plantChatQuickWhatToDoNow,
    ];
  }

  Future<void> _loadMessageHistory() async {
    try {
      final ref = _messagesCollection();
      if (ref == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingHistory = false;
          _messages
            ..clear()
            ..add(
              _ChatMessage(
                role: 'assistant',
                text: _welcomeMessage(),
                createdAt: DateTime.now(),
              ),
            );
        });
        return;
      }

      final snapshot = await ref.orderBy('createdAt').limit(60).get();
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        return _ChatMessage(
          role: (data['role'] ?? 'assistant').toString(),
          text: (data['text'] ?? '').toString(),
          source: data['source']?.toString(),
          createdAt: _parseMessageDate(data),
        );
      }).where((m) => m.text.trim().isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded.isEmpty
              ? [
                  _ChatMessage(
                    role: 'assistant',
                    text: _welcomeMessage(),
                    createdAt: DateTime.now(),
                  ),
                ]
              : loaded);
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..add(
            _ChatMessage(
              role: 'assistant',
              text: _welcomeMessage(),
              createdAt: DateTime.now(),
            ),
          );
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _persistMessage(_ChatMessage message) async {
    final ref = _messagesCollection();
    if (ref == null) return;
    await ref.add({
      'role': message.role,
      'text': message.text,
      'source': message.source,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': DateTime.now().toIso8601String(),
      'plantId': widget.plant.id,
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(l10n.plantChatLoginAgain);
      return;
    }
    final localeCode = Localizations.localeOf(context).languageCode;
    final requestFailedText = l10n.plantChatRequestFailed;
    final couldNotGenerateText = l10n.plantChatCouldNotGenerateResponse;
    final connectionErrorText = l10n.plantChatConnectionError;

    final userMessage = _ChatMessage(
      role: 'user',
      text: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _inputController.clear();
    });
    _scrollToBottom();
    await _persistMessage(userMessage);

    try {
      final conversation = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .take(14)
          .map((m) => {'role': m.role, 'text': m.text})
          .toList();

      final response = await http.post(
        Uri.parse(chatPlantAssistantUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.uid,
          'plantId': widget.plant.id,
          'plantName': widget.plant.name,
          'species': widget.plant.species,
          'message': text,
          'conversation': conversation,
          'locale': localeCode,
        }),
      );

      if (response.statusCode != 200) {
        final payload = jsonDecode(response.body);
        throw Exception(payload['error'] ?? requestFailedText);
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final assistantText =
          payload['answer']?.toString().trim().isNotEmpty == true
              ? payload['answer'].toString()
              : couldNotGenerateText;
      final source = payload['source']?.toString();

      if (!mounted) return;
      final assistantMessage =
          _ChatMessage(
            role: 'assistant',
            text: assistantText,
            source: source,
            createdAt: DateTime.now(),
          );
      setState(() {
        _messages.add(assistantMessage);
      });
      await _persistMessage(assistantMessage);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final fallback = _ChatMessage(
        role: 'assistant',
        text: connectionErrorText,
        source: 'agent',
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.add(fallback);
      });
      await _persistMessage(fallback);
      _showSnackBar(e.toString());
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _sourceLabel(String source) {
    final l10n = AppLocalizations.of(context)!;
    switch (source) {
      case 'knowledge_base':
        return l10n.chatSourceKnowledgeBase;
      case 'context':
        return l10n.chatSourceContext;
      case 'agent':
      default:
        return l10n.chatSourceAgent;
    }
  }

  DateTime _parseMessageDate(Map<String, dynamic> data) {
    final rawServer = data['createdAt'];
    if (rawServer is Timestamp) return rawServer.toDate();

    final rawClient = data['createdAtClient'];
    if (rawClient is String) {
      try {
        return DateTime.parse(rawClient);
      } catch (_) {
        // fall back below
      }
    }
    return DateTime.now();
  }

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  Widget _buildTypingBubble() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F6EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.assistantTyping),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userBg = Theme.of(context).colorScheme.primary;
    final assistantBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F6EF);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? userBg : assistantBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUser
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                : (isDark ? Colors.white12 : Colors.black12),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                height: 1.35,
                color: isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (!isUser && message.source != null) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.chatSourceLabel(_sourceLabel(message.source!)),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isUser
                    ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plantChatTitle(widget.plant.name)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _quickQuestions()
                    .map(
                      (question) => ActionChip(
                        label: Text(question),
                        onPressed: _isSending
                            ? null
                            : () {
                                _inputController.text = question;
                                _sendMessage();
                              },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return _buildTypingBubble();
                      }
                      final message = _messages[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('msg_${index}_${message.createdAt.toIso8601String()}'),
                        duration: const Duration(milliseconds: 220),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 8),
                              child: child,
                            ),
                          );
                        },
                        child: _buildMessageBubble(message),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: l10n.plantChatInputHint,
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final String? source;
  final DateTime createdAt;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.source,
    required this.createdAt,
  });
}
