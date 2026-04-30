import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';

class PlantChatScreen extends StatefulWidget {
  final String plantName;
  const PlantChatScreen({super.key, this.plantName = 'Plant'});

  @override
  State<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends State<PlantChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _hasFirstMessage = true;
  bool _typing = false;

  final List<_Msg> _messages = [];

  static const _quickReplies = [
    'Should I water today?',
    'Leaves turning yellow',
    'What should I do now?',
    'Is this healthy?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_Msg(
      text:
          "Hi! I'm here to help take care of your ${widget.plantName}. Ask me anything — watering, light, yellow leaves, pests, repotting.",
      isUser: false,
      time: _now(),
    ));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isUser: true, time: _now()));
      _input.clear();
      _hasFirstMessage = true;
      _typing = true;
    });
    _scrollDown();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_Msg(
        text:
            "That's a great question about ${widget.plantName}. Based on its profile and recent health check, I'd suggest a gentle adjustment to its care routine.",
        isUser: false,
        time: _now(),
        source: 'From plant profile',
      ));
    });
    _scrollDown();
  }

  String _now() {
    final d = DateTime.now();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BotanlyColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            if (!_hasFirstMessage || _messages.length <= 1) _quickRepliesBar(),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('TODAY',
                          style: GoogleFonts.dmSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: BotanlyColors.inkMute,
                          )),
                    ),
                  ),
                  ..._messages.map(_bubble),
                  if (_typing) _typingBubble(),
                ],
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: BotanlyColors.paper,
        border: Border(bottom: BorderSide(color: BotanlyColors.sand)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: BotanlyColors.sageDark),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 6),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [BotanlyColors.sagePale, BotanlyColors.sage],
              ),
            ),
            child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat with ${widget.plantName}',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.moss,
                      letterSpacing: -.2,
                    )),
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
                    Text('AI Plant Assistant · online',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: BotanlyColors.inkMute,
                        )),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: BotanlyColors.inkMute),
            onPressed: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(280, 70, 12, 0),
                items: [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 18, color: BotanlyColors.inkMute),
                        const SizedBox(width: 8),
                        Text('Clear history',
                            style: GoogleFonts.dmSans(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ).then((v) {
                if (v == 'clear') {
                  setState(() {
                    _messages.clear();
                    _hasFirstMessage = false;
                  });
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _quickRepliesBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickReplies
              .map((q) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        _input.text = q;
                        _send();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: BotanlyColors.sagePale),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(q,
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: BotanlyColors.sageDark,
                            )),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!m.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [BotanlyColors.sagePale, BotanlyColors.sage],
                ),
              ),
              child:
                  const Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                decoration: BoxDecoration(
                  gradient: m.isUser
                      ? const LinearGradient(
                          colors: [BotanlyColors.sage, BotanlyColors.sageDark],
                        )
                      : null,
                  color: m.isUser ? null : Colors.white,
                  border: m.isUser
                      ? null
                      : Border.all(color: BotanlyColors.sand),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(m.isUser ? 18 : 4),
                    bottomRight: Radius.circular(m.isUser ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.text,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: m.isUser ? Colors.white : BotanlyColors.ink,
                          height: 1.4,
                        )),
                    if (m.source != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: BotanlyColors.sagePale2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco_outlined,
                                size: 10, color: BotanlyColors.sageDark),
                            const SizedBox(width: 4),
                            Text(m.source!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: BotanlyColors.sageDark,
                                )),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(m.time,
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w300,
                          color: m.isUser
                              ? Colors.white.withOpacity(.7)
                              : BotanlyColors.inkMute,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MiniAvatar(),
          SizedBox(width: 6),
          _TypingDots(),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: BotanlyColors.paper,
        border: Border(top: BorderSide(color: BotanlyColors.sand)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: BotanlyColors.sand, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _input,
                focusNode: _focus,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: BotanlyColors.ink),
                decoration: InputDecoration(
                  hintText: 'Ask about your plant…',
                  hintStyle: GoogleFonts.dmSans(
                    color: BotanlyColors.inkMute,
                    fontWeight: FontWeight.w300,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [BotanlyColors.sage, BotanlyColors.sageDark],
                ),
                boxShadow: BotanlyShadows.primaryGlow,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  final String time;
  final String? source;
  _Msg(
      {required this.text,
      required this.isUser,
      required this.time,
      this.source});
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [BotanlyColors.sagePale, BotanlyColors.sage],
        ),
      ),
      child: const Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BotanlyColors.sand),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final phase = (_ctrl.value + i * .15) % 1.0;
                final scale =
                    0.7 + (phase < .5 ? phase * 0.6 : (1 - phase) * 0.6);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: BotanlyColors.inkMute,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
