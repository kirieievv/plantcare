import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/image_upload_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/models/chat_proposal.dart';
import 'package:plant_care/utils/care_sections.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/services/task_service.dart';
import 'package:plant_care/screens/plant_memory_screen.dart';
import 'package:plant_care/utils/chat_topics.dart';
import 'package:plant_care/utils/cloud_functions.dart';
import 'package:plant_care/utils/image_source_picker.dart';
import 'package:plant_care/widgets/botanly_loader.dart';
import 'package:plant_care/widgets/botanly_shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plant chat — UI from `Botanly /screens/plant_chat_screen.html`. Logic
/// preserved from the production version: persists messages in Firestore,
/// calls the cloud function, supports quick replies, source labels, and
/// photo attachment with daily quota.
class PlantChatScreen extends StatefulWidget {
  final Plant plant;

  /// Asked automatically once history has loaded.
  ///
  /// SPEC 1.4: entering the chat from a task or an analysis carries the question
  /// with it — an empty chat makes the user retype what the app already knew.
  final String? initialQuestion;

  /// Which care topic the user came in from — `water`, `light`, … — or null for
  /// the general chat.
  ///
  /// It chooses the hints and the status line above them, and nothing else. The
  /// conversation is one conversation and looks the same from every door: it is
  /// not filtered, not tagged, and the assistant's prompt does not depend on
  /// which card was tapped.
  final String? topic;

  /// Called when a confirmed proposal has changed the plant's stored data, so
  /// the screen underneath can reload rather than keep showing the old figures.
  final VoidCallback? onPlantChanged;

  const PlantChatScreen({
    super.key,
    required this.plant,
    this.initialQuestion,
    this.topic,
    this.onPlantChanged,
  });

  @override
  State<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends State<PlantChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isLoadingHistory = true;
  bool _hasUserMessage = false;
  bool _inputFocused = false;
  bool _hasText = false;

  // Photo attach state
  Uint8List? _pendingImageBytes;
  bool _isUploadingImage = false;

  bool _quotaLoaded = true; // show badge immediately with defaults
  int _quotaUsed = 0;
  int _quotaLimit = 2;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// The section the owner came in from.
  ///
  /// It chooses the hints and the status line above them, and nothing else.
  /// There is one conversation and it looks the same from every door — a list
  /// that changed with the entry point could show an answer whose question was
  /// filed elsewhere, which is exactly what it did.
  String? get _activeTopic =>
      widget.topic == ChatTopic.general ? null : widget.topic;

  /// The per-plant chat document. Never written before — it existed only as a
  /// path segment above `messages`. It now carries the clear marker.
  DocumentReference<Map<String, dynamic>>? _chatDoc() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plant_chats')
        .doc(widget.plant.id);
  }

  CollectionReference<Map<String, dynamic>>? _messagesCollection() =>
      _chatDoc()?.collection('messages');

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _loadImageQuota();
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
    _inputFocus.addListener(() {
      setState(() => _inputFocused = _inputFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  String _welcomeMessage() => l10n.plantChatWelcome(widget.plant.name);

  String? _topicLabel(String? topic) => switch (topic) {
    ChatTopic.water => l10n.chatTopicWater,
    ChatTopic.soil => l10n.chatTopicSoil,
    ChatTopic.light => l10n.chatTopicLight,
    ChatTopic.temperature => l10n.chatTopicTemperature,
    ChatTopic.fertilizer => l10n.chatTopicFertilizer,
    ChatTopic.diagnostics => l10n.chatTopicDiagnostics,
    _ => null,
  };

  /// Openers, not a menu. They exist because a blank chat asks the owner to
  /// invent a question, and the ones worth asking depend on the topic — and, for
  /// watering, on whether the plant is actually due.
  /// What the app already knows about this topic, in one line.
  ///
  /// Shown before a word is typed because it often answers the question by
  /// itself — "next watering in 4 days, soil still damp" is the reply to "should
  /// I water today?" without a model call. Only real data goes in: an invented
  /// line here is the first thing the owner reads, and being wrong there costs
  /// more trust than saying nothing.
  String? _topicContext() {
    final p = widget.plant;
    final d = p.careDetails ?? const <String, String>{};
    String? v(String key) {
      final value = d[key]?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    switch (_activeTopic) {
      case ChatTopic.water:
        if (p.shouldWaterNow) return l10n.chatCtxWaterToday;
        final due = p.nextDueAt ?? p.nextWatering;
        final days = due.difference(DateTime.now()).inDays;
        if (days >= 0) return l10n.chatCtxNextWatering(days);
        final last = p.lastWateredAt;
        return last == null
            ? null
            : l10n.chatCtxLastWatered(DateFormat.MMMd().format(last));
      case ChatTopic.light:
        final hours = v(CareDetail.lightHours);
        final type = v(CareDetail.lightType);
        if (hours == null || type == null) return null;
        return l10n.chatCtxLight(hours, type);
      case ChatTopic.temperature:
        final optimal = v(CareDetail.temperatureOptimal);
        return optimal == null ? null : l10n.chatCtxTemperature(optimal);
      case ChatTopic.fertilizer:
        final freq = v(CareDetail.fertilizerFrequency);
        return freq == null ? null : l10n.chatCtxFertilizer(freq);
      default:
        // Soil, diagnostics and the general chat have no standing figure worth
        // a line. An empty strip is better than a filled one.
        return null;
    }
  }

  List<String> _quickQuestions() {
    final entry = widget.initialQuestion?.trim();
    return [if (entry != null && entry.isNotEmpty) entry, ..._topicQuestions()];
  }

  List<String> _topicQuestions() {
    switch (_activeTopic) {
      case ChatTopic.water:
        return [
          if (widget.plant.shouldWaterNow)
            l10n.plantChatQuickWaterToday
          else
            l10n.plantChatQuickWaterEarly,
          l10n.plantChatQuickSoilSlowToDry,
          l10n.plantChatQuickYellowLeaves,
        ];
      case ChatTopic.light:
        return [
          l10n.plantChatQuickEnoughLight,
          l10n.plantChatQuickLeggyGrowth,
          l10n.plantChatQuickShouldMove,
        ];
      case ChatTopic.soil:
        return [
          l10n.plantChatQuickRepotWhen,
          l10n.plantChatQuickSoilCompacted,
          l10n.plantChatQuickWhichSoil,
        ];
      case ChatTopic.diagnostics:
        return [
          l10n.plantChatQuickWhatToDoNow,
          l10n.plantChatQuickYellowLeaves,
        ];
      default:
        return [
          l10n.plantChatQuickWaterToday,
          l10n.plantChatQuickYellowLeaves,
          l10n.plantChatQuickWhatToDoNow,
        ];
    }
  }

  // ─────────────────────── Image quota ───────────────────────

  String get _quotaCacheKey =>
      'quota_used_${FirebaseAuth.instance.currentUser?.uid}_${widget.plant.id}';
  String get _quotaDateKey =>
      'quota_date_${FirebaseAuth.instance.currentUser?.uid}_${widget.plant.id}';

  /// Loads the history. Nothing is sent.
  ///
  /// Opening a screen is not asking a question. This used to fire
  /// [PlantChatScreen.initialQuestion] the moment the history landed, so
  /// glancing at the watering card and backing out still wrote "tell me more
  /// about watering" into the conversation and paid for an answer nobody read —
  /// and doing it twice left two identical questions in a row.
  ///
  /// The question it carried is not thrown away: it becomes the first quick
  /// reply, one tap from being asked, which is where it belonged.
  Future<void> _bootstrap() async {
    await _loadMessageHistory();
  }

  Future<void> _loadImageQuota() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Read cached value immediately so badge shows correct state on re-open
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final cachedDate = prefs.getString(_quotaDateKey);
    final cachedUsed = cachedDate == today
        ? (prefs.getInt(_quotaCacheKey) ?? 0)
        : 0;
    if (mounted) {
      setState(() {
        _quotaUsed = cachedUsed;
        _quotaLoaded = true;
      });
    }

    // Then fetch real value from CF and update
    try {
      final idToken = await user.getIdToken();
      if (idToken == null) return; // keep the cached badge rather than 401-ing
      final response = await http.post(
        Uri.parse(chatImageQuotaUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'plantId': widget.plant.id}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverUsed = (data['usedToday'] ?? 0) as int;
        final serverLimit = (data['dailyLimit'] ?? 2) as int;
        // Persist to cache
        await prefs.setInt(_quotaCacheKey, serverUsed);
        await prefs.setString(_quotaDateKey, today);
        if (!mounted) return;
        setState(() {
          _quotaUsed = serverUsed;
          _quotaLimit = serverLimit;
        });
      }
    } catch (_) {
      // CF unavailable — cached value already applied above
    }
  }

  Future<void> _saveQuotaCache(int used) async {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quotaCacheKey, used);
    await prefs.setString(_quotaDateKey, today);
  }

  bool get _canAttachImage => !_quotaLoaded || _quotaUsed < _quotaLimit;

  // ─────────────────────── Pick image ───────────────────────

  Future<void> _pickImage() async {
    if (!_canAttachImage) {
      _showSnackBar(l10n.plantChatImageQuotaReached);
      return;
    }
    try {
      final bytes = await pickImageBytes(
        context,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (bytes == null || !mounted) return;
      setState(() => _pendingImageBytes = bytes);
    } catch (e) {
      _showSnackBar(l10n.errorPickingImage('$e'));
    }
  }

  void _removePendingImage() {
    setState(() => _pendingImageBytes = null);
  }

  // ─────────────────────── History ───────────────────────

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

      // Everything before the clear marker stays in the database and out of
      // sight. Read first so a cleared chat opens empty rather than flashing
      // the old conversation.
      Timestamp? clearedAt;
      try {
        final chat = await _chatDoc()?.get();
        final value = chat?.data()?['historyClearedAt'];
        if (value is Timestamp) clearedAt = value;
      } catch (_) {
        // Showing more than intended is the wrong way to fail here, but there
        // is nothing better to do than carry on with the full history.
      }

      Query<Map<String, dynamic>> query = ref;
      if (clearedAt != null) {
        query = query.where('createdAt', isGreaterThan: clearedAt);
      }

      final snapshot = await query.orderBy('createdAt').limit(60).get();
      final loaded = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final createdAt = _parseMessageDate(data);
            return _ChatMessage(
              role: (data['role'] ?? 'assistant').toString(),
              text: (data['text'] ?? '').toString(),
              source: data['source']?.toString(),
              imageUrl: data['imageUrl']?.toString(),
              createdAt: createdAt,
              // Falls back to the message's own timestamp: a card written before
              // `offeredAt` existed still has to know when it was offered, or it
              // would read as brand new forever.
              proposal: ChatProposal.fromJson(
                (data['proposal'] as Map?)?.cast<String, dynamic>(),
                offeredAt: createdAt,
              ),
            )..docId = doc.id;
          })
          .where((m) => m.text.trim().isNotEmpty || m.imageUrl != null)
          .toList();

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            loaded.isEmpty
                ? [
                    _ChatMessage(
                      role: 'assistant',
                      text: _welcomeMessage(),
                      createdAt: DateTime.now(),
                    ),
                  ]
                : loaded,
          );
        _hasUserMessage = _messages.any((m) => m.role == 'user');
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
    final doc = await ref.add({
      'role': message.role,
      'text': message.text,
      'source': message.source,
      if (message.proposal != null) 'proposal': message.proposal!.toMap(),
      if (message.imageUrl != null) 'imageUrl': message.imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      // The message's own instant, not the moment of saving. They differ by
      // however long the request took, and anything matching on this later
      // would silently never match.
      'createdAtClient': message.createdAt.toIso8601String(),
      'plantId': widget.plant.id,
    });
    message.docId = doc.id;
  }

  // ─────────────────────── Send ───────────────────────

  Future<void> _sendMessage([String? overrideText]) async {
    if (_isSending) return;

    final text = (overrideText ?? _inputController.text).trim();
    final hasImage = _pendingImageBytes != null;
    if (text.isEmpty && !hasImage) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(l10n.plantChatLoginAgain);
      return;
    }
    final localeCode = Localizations.localeOf(context).languageCode;
    final requestFailedText = l10n.plantChatRequestFailed;
    final couldNotGenerateText = l10n.plantChatCouldNotGenerateResponse;
    final connectionErrorText = l10n.plantChatConnectionError;

    // Capture and clear pending image
    final imageBytes = _pendingImageBytes;

    setState(() {
      _isSending = true;
      _hasUserMessage = true;
      _inputController.clear();
      _pendingImageBytes = null;
    });

    // Convert image to base64 — no Storage upload needed, sent directly to CF
    String? base64Image;
    String? imageUrl; // kept for display in chat UI (local data: URI)
    if (imageBytes != null) {
      _quotaUsed++;
      _saveQuotaCache(_quotaUsed);
      base64Image = base64Encode(imageBytes);
      imageUrl = 'data:image/jpeg;base64,$base64Image';
    }

    final userMessage = _ChatMessage(
      role: 'user',
      text: text,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    setState(() => _messages.add(userMessage));
    _scrollToBottom();
    // Persist message without the heavy base64 data URI
    await _persistMessage(
      _ChatMessage(
        role: 'user',
        text: text,
        imageUrl: null, // don't store base64 in Firestore
        createdAt: userMessage.createdAt,
      ),
    );

    try {
      // The conversation window is no longer assembled here. The server reads
      // it from Firestore itself, which is both why it can be retuned without
      // a release and why it can no longer be sent from the wrong end of the
      // list — this used to `.take(14)` off an oldest-first list.
      final requestBody = <String, dynamic>{
        'plantId': widget.plant.id,
        'plantName': widget.plant.name,
        'species': widget.plant.species,
        'message': text.isNotEmpty ? text : 'I attached a photo of my plant.',
        'locale': localeCode,
      };
      if (base64Image != null) {
        requestBody['base64Image'] = base64Image;
      }

      // Nullable by signature. Interpolating it blind would post the literal
      // string "Bearer null" and come back as an unexplained 401.
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception(requestFailedText);

      final response = await http.post(
        Uri.parse(chatPlantAssistantUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(requestBody),
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
      final assistantMessage = _ChatMessage(
        role: 'assistant',
        text: assistantText,
        source: source,
        createdAt: DateTime.now(),
        proposal: ChatProposal.fromJson(
          payload['proposal'] as Map<String, dynamic>?,
        ),
        suggestedTask: SuggestedTask.fromJson(
          payload['task'] as Map<String, dynamic>?,
        ),
      );
      setState(() => _messages.add(assistantMessage));
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
      setState(() => _messages.add(fallback));
      await _persistMessage(fallback);
      _showSnackBar(e.toString());
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Sends the owner's verdict on a proposed change.
  ///
  /// Optimistic on purpose: the card settles the moment it is tapped, and rolls
  /// back only if the server refuses. Making someone watch a spinner to find out
  /// whether their own "no" registered is worse than the rare rollback.
  Future<void> _decideProposal(_ChatMessage message, bool accepted) async {
    final proposal = message.proposal;
    if (proposal == null || !proposal.isActionableAt(DateTime.now())) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final outcome = accepted
        ? ProposalOutcome.applied
        : ProposalOutcome.declined;
    _replaceProposal(message, proposal.resolved(outcome));

    try {
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception(l10n.plantChatRequestFailed);

      final response = await http.post(
        Uri.parse(applyChatProposalUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'plantId': widget.plant.id,
          'decision': accepted ? 'apply' : 'decline',
          'proposal': proposal.toMap(),
          'locale': Localizations.localeOf(context).languageCode,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception(
          jsonDecode(response.body)['error'] ?? l10n.plantChatRequestFailed,
        );
      }
      // The plant's numbers have moved; whoever pushed this screen is showing
      // the old ones.
      if (accepted && mounted) widget.onPlantChanged?.call();
    } catch (e) {
      if (!mounted) return;
      _replaceProposal(message, proposal);
      _showSnackBar(e.toString());
    }
  }

  /// Writes the reminder the assistant offered.
  ///
  /// The card is dropped either way once tapped: the deck is where a task lives
  /// afterwards, and leaving a spent offer in the transcript invites a second
  /// identical reminder.
  Future<void> _acceptSuggestedTask(_ChatMessage message) async {
    final task = message.suggestedTask;
    if (task == null) return;

    final index = _messages.indexOf(message);
    if (index != -1) {
      setState(
        () => _messages[index] = _ChatMessage(
          role: message.role,
          text: message.text,
          source: message.source,
          imageUrl: message.imageUrl,
          createdAt: message.createdAt,
          proposal: message.proposal,
        ),
      );
    }

    try {
      await TaskService().createFromChat(
        plantId: widget.plant.id,
        title: task.title,
        dueInDays: task.dueInDays,
        category: switch (_activeTopic) {
          ChatTopic.water => TaskCategory.water,
          ChatTopic.light => TaskCategory.light,
          ChatTopic.soil => TaskCategory.soil,
          ChatTopic.fertilizer => TaskCategory.fertilizer,
          ChatTopic.diagnostics => TaskCategory.scan,
          _ => TaskCategory.other,
        },
      );
      if (mounted) _showSnackBar(l10n.chatTaskCreated);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString());
    }
  }

  /// Swaps a proposal in place, in memory and in the stored message.
  void _replaceProposal(_ChatMessage message, ChatProposal next) {
    final index = _messages.indexOf(message);
    if (index == -1) return;
    final updated = message.withProposal(next);
    setState(() => _messages[index] = updated);

    // Best effort on the write, but never silent: the owner's decision has to
    // survive reopening the chat, and a failure here is the difference between
    // a settled card and one that quietly offers itself again.
    final ref = _messagesCollection();
    final id = message.docId;
    if (ref == null || id == null) {
      debugPrint('⚠️ Chat: proposal outcome not stored — message has no id');
      return;
    }
    ref.doc(id).update({'proposal': next.toMap()}).catchError((Object e) {
      debugPrint('⚠️ Chat: could not store proposal outcome: $e');
    });
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _clearHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clearHistoryAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // A mark, not a delete. Nothing leaves the database — the list and the
    // model's window both simply start after it, which is what "clear" means to
    // someone looking at the screen. The assistant has to honour it too, or it
    // goes on quoting a conversation the owner is staring at an empty page for.
    //
    // Facts and memory deliberately survive: this forgets the conversation, not
    // the plant. "I moved it to the east window" stays known.
    final chat = _chatDoc();
    if (chat != null) {
      try {
        await chat.set({
          'historyClearedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Nothing was destroyed, so a failure here costs the gesture and
        // nothing else.
      }
    }

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
      _hasUserMessage = false;
    });
  }

  void _openMemory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlantMemoryScreen(plant: widget.plant)),
    );
  }

  String _sourceLabel(String source) {
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
      } catch (_) {}
    }
    return DateTime.now();
  }

  String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  // ─────────────────────── Build ───────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              title: l10n.plantChatTitle(widget.plant.name),
              onBack: () => Navigator.of(context).maybePop(),
              onClear: _clearHistory,
              onOpenMemory: _openMemory,
              statusLabel: l10n.aiAssistantOnline,
            ),
            if (_topicContext() case final ctx?) _TopicContextBar(text: ctx),
            if (!_isLoadingHistory && !_hasText && !_isSending)
              _QuickReplies(
                items: _quickQuestions(),
                onTap: (q) => _sendMessage(q),
              ),
            Expanded(
              child: _isLoadingHistory
                  ? BotanlyShimmer(child: const ShimmerChatHistory())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isSending && index == _messages.length) {
                          return const _TypingBubble();
                        }
                        final m = _messages[index];
                        return _MessageBubble(
                          message: m,
                          isFirstInGroup: _isFirstInGroup(index),
                          formatTime: _formatTime,
                          sourceLabel: _sourceLabel,
                          onProposalDecision: _decideProposal,
                          onTaskAccepted: _acceptSuggestedTask,
                        );
                      },
                    ),
            ),
            _InputBar(
              focused: _inputFocused,
              focusNode: _inputFocus,
              controller: _inputController,
              hasText: _hasText,
              isSending: _isSending,
              onSend: _sendMessage,
              onAttach: _pickImage,
              onRemoveImage: _removePendingImage,
              pendingImageBytes: _pendingImageBytes,
              isUploadingImage: _isUploadingImage,
              quotaLoaded: _quotaLoaded,
              quotaUsed: _quotaUsed,
              quotaLimit: _quotaLimit,
              canAttach: _canAttachImage,
              hint: l10n.plantChatInputHint,
            ),
          ],
        ),
      ),
    );
  }

  bool _isFirstInGroup(int index) {
    if (index == 0) return true;
    return _messages[index - 1].role != _messages[index].role;
  }
}

// ────────────────────────────────────────────────────────────
//  App bar
// ────────────────────────────────────────────────────────────

/// The one line of real state above the hints.
///
/// Belongs to the section the owner came in from, like the hints themselves —
/// not to the conversation, which is the same from every door. Often it answers
/// the question outright: "watering due today" is the reply to "should I water
/// it?" without a model call.
class _TopicContextBar extends StatelessWidget {
  final String text;

  const _TopicContextBar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7FAF5),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: BotanlyColors.inkMute,
        ),
      ),
    );
  }
}

class _AppBar extends StatefulWidget {
  final String title;
  final String statusLabel;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback onOpenMemory;
  const _AppBar({
    required this.title,
    required this.statusLabel,
    required this.onBack,
    required this.onClear,
    required this.onOpenMemory,
  });

  @override
  State<_AppBar> createState() => _AppBarState();
}

class _AppBarState extends State<_AppBar> {
  final GlobalKey _menuButtonKey = GlobalKey();
  OverlayEntry? _menuOverlay;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  void _toggleMenu() {
    if (_menuOverlay != null) {
      _removeOverlay();
      return;
    }

    final renderBox =
        _menuButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _menuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Scrim to close on tap-away
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 4,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              shadowColor: const Color(0x33000000),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE4EBE1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _removeOverlay();
                          widget.onOpenMemory();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.psychology_outlined,
                                size: 15,
                                color: BotanlyColors.inkMute,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.memoryTitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: BotanlyColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _removeOverlay();
                          widget.onClear();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                size: 15,
                                color: BotanlyColors.inkMute,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.clearHistoryAction,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1B2A18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_menuOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF5),
        border: Border(bottom: BorderSide(color: Color(0xFFE4EBE1))),
      ),
      child: Row(
        children: [
          _IconCircle(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: widget.onBack,
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BotanlyColors.sagePale, BotanlyColors.sage],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x404A6741),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text('🌿', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                    height: 1.1,
                    color: BotanlyColors.moss,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7AAF6A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        widget.statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: BotanlyColors.inkMute,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            key: _menuButtonKey,
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggleMenu,
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: BotanlyColors.inkMute,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F8EB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: BotanlyColors.sageDark),
      ),
    );
  }
}

/// Attach (paperclip) button with quota badge below.
/// Greyed out and non-tappable when quota is exhausted.
class _AttachButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool quotaLoaded;
  final int quotaRemaining;
  final int quotaLimit;

  const _AttachButton({
    required this.onTap,
    required this.quotaLoaded,
    required this.quotaRemaining,
    required this.quotaLimit,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final iconColor = disabled
        ? const Color(0xFFBBBBBB)
        : BotanlyColors.sageDark;
    final bgColor = disabled
        ? const Color(0xFFF0F0F0)
        : const Color(0xFFF1F8EB);
    final remaining = quotaRemaining.clamp(0, quotaLimit);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(Icons.attach_file_rounded, size: 16, color: iconColor),
          ),
          if (quotaLoaded) ...[
            const SizedBox(height: 3),
            Text(
              '$remaining/$quotaLimit',
              style: GoogleFonts.dmMono(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: disabled
                    ? const Color(0xFFBBBBBB)
                    : BotanlyColors.inkMute,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Quick replies
// ────────────────────────────────────────────────────────────

class _QuickReplies extends StatelessWidget {
  final List<String> items;
  final void Function(String)? onTap;
  const _QuickReplies({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final label = items[i];
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTap == null ? null : () => onTap!(label),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: BotanlyColors.sagePale),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: BotanlyColors.sageDark,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Message bubble (text + optional photo)
// ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isFirstInGroup;
  final String Function(DateTime) formatTime;
  final String Function(String) sourceLabel;
  final void Function(_ChatMessage, bool accepted)? onProposalDecision;
  final void Function(_ChatMessage)? onTaskAccepted;
  const _MessageBubble({
    required this.message,
    required this.isFirstInGroup,
    required this.formatTime,
    required this.sourceLabel,
    this.onProposalDecision,
    this.onTaskAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _MiniAvatar(visible: isFirstInGroup),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Photo bubble (if image attached)
                  if (message.imageUrl != null) ...[
                    _PhotoBubble(
                      imageUrl: message.imageUrl!,
                      isUser: isUser,
                      time: formatTime(message.createdAt),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 4),
                  ],
                  // Text bubble
                  if (message.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? null : Colors.white,
                        gradient: isUser
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  BotanlyColors.sage,
                                  BotanlyColors.sageDark,
                                ],
                              )
                            : null,
                        border: isUser
                            ? null
                            : Border.all(color: const Color(0xFFE4EBE1)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.text,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              color: isUser
                                  ? Colors.white
                                  : const Color(0xFF1B2A18),
                            ),
                          ),
                          if (!isUser && message.source != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F1D6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                sourceLabel(message.source!),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: BotanlyColors.sageDark,
                                ),
                              ),
                            ),
                          ],
                          if (!isUser && message.suggestedTask != null) ...[
                            const SizedBox(height: 10),
                            _SuggestedTaskCard(
                              task: message.suggestedTask!,
                              onAccept: () => onTaskAccepted?.call(message),
                            ),
                          ],
                          if (!isUser && message.proposal != null) ...[
                            const SizedBox(height: 10),
                            _ProposalCard(
                              proposal: message.proposal!,
                              onDecision: (accepted) =>
                                  onProposalDecision?.call(message, accepted),
                            ),
                          ],
                          if (message.imageUrl == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              formatTime(message.createdAt),
                              style: GoogleFonts.dmSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w300,
                                color: isUser
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : BotanlyColors.inkMute,
                              ),
                            ),
                          ],
                        ],
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

// ────────────────────────────────────────────────────────────
//  Photo bubble
// ────────────────────────────────────────────────────────────

class _PhotoBubble extends StatelessWidget {
  final String imageUrl;
  final bool isUser;
  final String time;
  const _PhotoBubble({
    required this.imageUrl,
    required this.isUser,
    required this.time,
  });

  Widget _buildImageWidget() {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _brokenImage(),
        );
      } catch (_) {
        return _brokenImage();
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _brokenImage(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFE3F1D6),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _brokenImage() => Container(
    color: const Color(0xFFE3F1D6),
    child: const Center(
      child: Icon(Icons.broken_image, color: BotanlyColors.inkMute),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isUser ? 18 : 4),
        bottomRight: Radius.circular(isUser ? 4 : 18),
      ),
      child: SizedBox(
        width: 240,
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageWidget(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB31E2C1C)],
                  ),
                ),
                child: Text(
                  time,
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final bool visible;
  const _MiniAvatar({required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 28);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BotanlyColors.sagePale, BotanlyColors.sage],
        ),
      ),
      child: const Text('🌿', style: TextStyle(fontSize: 14)),
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
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _MiniAvatar(visible: true),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE4EBE1)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ac,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_ac.value * 3) - i * 0.4;
                    final v = (t.clamp(0.0, 1.0));
                    final scale = 0.7 + (v < 0.5 ? v : 1 - v) * 0.6;
                    final opacity = 0.5 + (v < 0.5 ? v : 1 - v);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: BotanlyColors.inkMute,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  Input bar (with attach button, image preview, quota)
// ────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool focused;
  final bool hasText;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onRemoveImage;
  final Uint8List? pendingImageBytes;
  final bool isUploadingImage;
  final bool quotaLoaded;
  final int quotaUsed;
  final int quotaLimit;
  final bool canAttach;
  final String hint;
  const _InputBar({
    required this.focusNode,
    required this.controller,
    required this.focused,
    required this.hasText,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
    required this.onRemoveImage,
    required this.pendingImageBytes,
    required this.isUploadingImage,
    required this.quotaLoaded,
    required this.quotaUsed,
    required this.quotaLimit,
    required this.canAttach,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = (hasText || pendingImageBytes != null) && !isSending;
    final quotaWarn = quotaUsed >= quotaLimit;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF5),
        border: Border(top: BorderSide(color: Color(0xFFE4EBE1))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview strip
            if (pendingImageBytes != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE4EBE1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        pendingImageBytes!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Photo attached',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1B2A18),
                        ),
                      ),
                    ),
                    Material(
                      color: const Color(0xFFF1F8EB),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRemoveImage,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: BotanlyColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            // Upload spinner
            if (isUploadingImage) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(BotanlyColors.sage),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading photo…',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w300,
                      color: BotanlyColors.inkMute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AttachButton(
                  onTap: canAttach ? onAttach : null,
                  quotaLoaded: quotaLoaded,
                  quotaRemaining: quotaLimit - quotaUsed,
                  quotaLimit: quotaLimit,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: focused
                            ? BotanlyColors.sage
                            : const Color(0xFFE4EBE1),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      cursorColor: BotanlyColors.sage,
                      mouseCursor: SystemMouseCursors.text,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF1B2A18),
                      ),
                      onSubmitted: (_) {
                        if (canSend) onSend();
                      },
                      decoration: InputDecoration(
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hoverColor: Colors.transparent,
                        filled: false,
                        hintText: hint,
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: BotanlyColors.inkMute,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(
                  enabled: canSend,
                  loading: isSending,
                  onTap: onSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [BotanlyColors.sage, BotanlyColors.sageDark],
                  )
                : null,
            color: enabled ? null : const Color(0xFFE4EBE1),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x525FA346),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Icon(
                  Icons.send_rounded,
                  size: 17,
                  color: enabled ? Colors.white : BotanlyColors.inkMute,
                ),
        ),
      ),
    );
  }
}

/// The change offered under an answer.
///
/// Deliberately quiet: it sits inside the assistant's own bubble rather than
/// interrupting the conversation, because most of the time the answer is what
/// the owner came for and the change is a footnote to it.
///
/// Three states, and the third is the one that matters. Open shows both
/// buttons. Resolved states its outcome. Expired greys out but stays in the
/// transcript — the conversation happened, and a card that vanishes leaves the
/// reply above it referring to nothing.
class _ProposalCard extends StatelessWidget {
  final ChatProposal proposal;
  final void Function(bool accepted) onDecision;

  const _ProposalCard({required this.proposal, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actionable = proposal.isActionableAt(DateTime.now());
    final settled = proposal.outcome != ProposalOutcome.open;

    final String status = switch (proposal.outcome) {
      ProposalOutcome.applied => l10n.chatProposalApplied,
      ProposalOutcome.declined => l10n.chatProposalDeclined,
      ProposalOutcome.open => actionable ? '' : l10n.chatProposalOutdated,
    };

    return Opacity(
      opacity: actionable ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F7EE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33489B58)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _headline(l10n),
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: BotanlyColors.sageDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              proposal.reason,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                height: 1.35,
                color: const Color(0xFF41513E),
              ),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                status,
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: BotanlyColors.inkMute,
                ),
              ),
            ],
            if (actionable && !settled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ProposalButton(
                      label: l10n.chatProposalApply,
                      filled: true,
                      onTap: () => onDecision(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProposalButton(
                      label: l10n.chatProposalDecline,
                      filled: false,
                      onTap: () => onDecision(false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Every 9 days → every 11 days" where both ends are known, otherwise just
  /// the new value: a plant that never had the field set has no "from" to show,
  /// and inventing one would misdescribe what is happening.
  String _headline(AppLocalizations l10n) {
    final to = _format(proposal.to, l10n);
    if (proposal.from == null) return l10n.chatProposalSet(_label(l10n), to);
    return l10n.chatProposalChange(
      _label(l10n),
      _format(proposal.from, l10n),
      to,
    );
  }

  String _label(AppLocalizations l10n) => switch (proposal.field) {
    'wateringIntervalDays' => l10n.careKvFrequency,
    'wateringAmountMl' => l10n.wateringAmount,
    'placement' => l10n.careSectionPlacement,
    'potMaterial' || 'potDiameterCm' || 'hasDrainage' => l10n.chatProposalPot,
    'nearHeatSource' => l10n.careSectionTemperature,
    'species' => l10n.chatProposalSpecies,
    'tasksPausedUntil' => l10n.chatProposalPause,
    'nextDueAt' => l10n.chatProposalNextWatering,
    _ => proposal.field,
  };

  String _format(Object? value, AppLocalizations l10n) {
    if (value == null) return '—';
    if (value is bool) return value ? '✓' : '✗';
    final text = value.toString();

    // Both of these are stored as instants and read as days.
    if (proposal.field == 'tasksPausedUntil' || proposal.field == 'nextDueAt') {
      final at = DateTime.tryParse(text);
      if (at == null) return text.length >= 10 ? text.substring(0, 10) : text;
      // "Today" says what the change means; a date makes the reader work it out.
      final now = DateTime.now();
      final sameDay =
          at.year == now.year && at.month == now.month && at.day == now.day;
      return sameDay ? l10n.chatProposalToday : DateFormat.MMMd().format(at);
    }
    return text;
  }
}

/// The reminder offer. One button, because declining a reminder is just not
/// tapping it — unlike a change to the plant's data, an ignored offer leaves
/// nothing wrong behind.
class _SuggestedTaskCard extends StatelessWidget {
  final SuggestedTask task;
  final VoidCallback onAccept;

  const _SuggestedTaskCard({required this.task, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332F6FB4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chatTaskOffer,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2F6FB4),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${task.title} · ${l10n.chatTaskInDays(task.dueInDays)}',
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              height: 1.35,
              color: const Color(0xFF3C4A5A),
            ),
          ),
          const SizedBox(height: 10),
          _ProposalButton(
            label: l10n.chatProposalApply,
            filled: true,
            onTap: onAccept,
          ),
        ],
      ),
    );
  }
}

class _ProposalButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ProposalButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? BotanlyColors.sageDark : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? BotanlyColors.sageDark : const Color(0x33489B58),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : BotanlyColors.sageDark,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final String? source;
  final String? imageUrl;
  final DateTime createdAt;

  /// Firestore document id, once the message has been written or loaded.
  ///
  /// Mutable and assigned exactly once, which earns the exception: the
  /// alternative was finding the row again by timestamp, and the timestamp
  /// written into the document was taken at save time while the one searched
  /// for was taken at construction. They were never equal, so a proposal's
  /// outcome was never actually stored — the buttons settled on screen and came
  /// back alive on reopening.
  String? docId;

  /// A change the assistant offered alongside this answer, if any.
  final ChatProposal? proposal;

  /// A one-off reminder it offered to set. Not persisted: once the owner has
  /// answered, the task itself is the record, and an offer they ignored is not
  /// worth carrying forward.
  final SuggestedTask? suggestedTask;

  _ChatMessage({
    required this.role,
    required this.text,
    this.source,
    this.imageUrl,
    required this.createdAt,
    this.proposal,
    this.suggestedTask,
  });

  _ChatMessage withProposal(ChatProposal? next) => _ChatMessage(
    role: role,
    text: text,
    source: source,
    imageUrl: imageUrl,
    createdAt: createdAt,
    proposal: next,
  )..docId = docId;
}
