import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../components/market_safety_banner.dart';
import '../components/market_shell.dart';
import '../models/market_models.dart';
import '../providers/market_providers.dart';
import '../services/api_market_repository.dart';

class MarketChatScreen extends ConsumerStatefulWidget {
  const MarketChatScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<MarketChatScreen> createState() => _MarketChatScreenState();
}

class _MarketChatScreenState extends ConsumerState<MarketChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reloadMessages(scrollToEnd: true);
      _poll = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(_reloadMessages());
      });
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reloadMessages({bool scrollToEnd = false}) async {
    final repo = ref.read(marketRepositoryProvider);
    if (repo is! ApiMarketRepository) return;
    await repo.loadMessages(widget.threadId);
    if (!mounted) return;
    final count =
        ref.read(marketRepositoryProvider).getMessages(widget.threadId).length;
    final shouldScroll = scrollToEnd || count > _lastMessageCount;
    _lastMessageCount = count;
    if (shouldScroll) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _send() async {
    final userId = ref.read(marketUserIdProvider);
    if (userId == null) return;
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(marketRepositoryProvider).sendMessage(
          threadId: widget.threadId,
          senderId: userId,
          body: text,
        );
    _lastMessageCount =
        ref.read(marketRepositoryProvider).getMessages(widget.threadId).length;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(marketMessagesProvider(widget.threadId));
    final threads = ref.watch(marketThreadsProvider);
    final userId = ref.watch(marketUserIdProvider);
    final repo = ref.watch(marketRepositoryProvider);

    ChatThread? t;
    for (final thread in threads) {
      if (thread.id == widget.threadId) {
        t = thread;
        break;
      }
    }
    final ad = t == null ? null : repo.getAd(t.adId);
    final otherId = t == null
        ? null
        : (t.buyerId == userId ? t.sellerId : t.buyerId);
    final other = otherId == null ? null : repo.getSeller(otherId);

    return MarketShell(
      title: ad?.title ?? 'Chat',
      showBottomNav: false,
      actions: [
        if (other?.showPhone == true)
          IconButton(
            onPressed: () =>
                launchUrl(Uri(scheme: 'tel', path: other!.phoneE164)),
            icon: const Icon(Icons.call_rounded),
            color: MaekelColors.signal,
          ),
      ],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: MarketSafetyBanner(
              compact: true,
              message: MarketSafetyCopy.chatBanner,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMine = msg.senderId == userId;
                final isSystem = msg.senderId == 'system';
                final align = isSystem
                    ? Alignment.center
                    : (isMine ? Alignment.centerRight : Alignment.centerLeft);
                final bg = isSystem
                    ? MaekelColors.panelLift
                    : (isMine
                        ? MaekelColors.signal.withValues(alpha: 0.2)
                        : MaekelColors.panel);
                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MaekelColors.glassBorder),
                    ),
                    child: Text(
                      msg.body,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 14,
                            color: isSystem
                                ? MaekelColors.muted
                                : MaekelColors.ink,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: MaekelColors.ink),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(
                      backgroundColor: MaekelColors.signal,
                      foregroundColor: MaekelColors.voidBlack,
                    ),
                    icon: const Icon(Icons.send_rounded),
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
