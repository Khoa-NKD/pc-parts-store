import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';

// ── Message model ──────────────────────────────────────────────────────────

enum _Sender { user, bot }

class _Message {
  final _Sender sender;
  final String text;
  final List<ProductModel> products;
  _Message.user(this.text) : sender = _Sender.user, products = [];
  _Message.bot(this.text, [this.products = const []]) : sender = _Sender.bot;
}

// ── Chat logic ─────────────────────────────────────────────────────────────

class _ChatBot {
  static const _greetings = ['xin chào', 'hello', 'hi', 'chào', 'hey'];
  static const _keywords = {
    'cpu': ['cpu', 'vi xử lý', 'processor', 'intel', 'amd ryzen'],
    'gpu': ['gpu', 'card đồ họa', 'card màn hình', 'rtx', 'rx ', 'nvidia', 'radeon'],
    'ram': ['ram', 'bộ nhớ', 'ddr'],
    'ssd': ['ssd', 'ổ cứng', 'nvme', 'storage'],
    'motherboard': ['mainboard', 'bo mạch', 'motherboard', 'asus rog', 'z790'],
    'psu': ['psu', 'nguồn', 'power supply', 'seasonic'],
  };

  static String _detectCategory(String msg) {
    final lower = msg.toLowerCase();
    for (final entry in _keywords.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) return entry.key;
    }
    return '';
  }

  static bool _isGreeting(String msg) =>
      _greetings.any((g) => msg.toLowerCase().contains(g));

  static bool _isHelp(String msg) {
    final l = msg.toLowerCase();
    return l.contains('giúp') || l.contains('help') || l.contains('tìm') ||
        l.contains('mua') || l.contains('cần') || l.contains('muốn');
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_Message.bot(
      'Xin chào! 👋 Tôi có thể giúp bạn tìm linh kiện PC.\n'
      'Hãy nhập tên sản phẩm hoặc loại linh kiện bạn cần (CPU, GPU, RAM, SSD...)',
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_Message.user(text));
      _loading = true;
    });
    _scrollDown();

    await Future.delayed(const Duration(milliseconds: 400));

    final reply = await _buildReply(text);
    if (mounted) {
      setState(() {
        _messages.add(reply);
        _loading = false;
      });
      _scrollDown();
    }
  }

  Future<_Message> _buildReply(String text) async {
    if (_ChatBot._isGreeting(text)) {
      return _Message.bot('Chào bạn! 😊 Bạn đang tìm linh kiện gì? Tôi có CPU, GPU, RAM, SSD, Mainboard, PSU...');
    }

    final category = _ChatBot._detectCategory(text);
    final service = ref.read(productServiceProvider);

    // Search by keyword first
    final bySearch = await service.getProducts(
      filter: ProductFilter(searchQuery: text),
    );

    // Also search by category if detected
    List<ProductModel> byCat = [];
    if (category.isNotEmpty) {
      byCat = await service.getProducts(filter: ProductFilter(category: category));
    }

    // Merge, deduplicate, limit 4
    final seen = <String>{};
    final results = <ProductModel>[];
    for (final p in [...bySearch, ...byCat]) {
      if (seen.add(p.id)) results.add(p);
      if (results.length >= 4) break;
    }

    if (results.isEmpty) {
      if (_ChatBot._isHelp(text)) {
        return _Message.bot(
          'Tôi có thể tìm các loại linh kiện sau:\n'
          '• CPU (Intel, AMD)\n• GPU (NVIDIA, AMD)\n• RAM (DDR4, DDR5)\n'
          '• SSD (NVMe, SATA)\n• Mainboard\n• PSU (Nguồn)\n\n'
          'Hãy nhập tên cụ thể hơn nhé!',
        );
      }
      return _Message.bot('Không tìm thấy sản phẩm nào cho "$text". Thử tìm: CPU, GPU, RAM, SSD...');
    }

    final label = category.isNotEmpty ? category.toUpperCase() : 'linh kiện';
    return _Message.bot('Tìm thấy ${results.length} sản phẩm $label cho bạn 🎯', results);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(
            radius: 16, backgroundColor: DesignTokens.primary,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PC Assistant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Tìm linh kiện nhanh', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) return const _TypingIndicator();
              return _MessageBubble(msg: _messages[i]);
            },
          ),
        ),
        // Quick chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            for (final chip in ['CPU', 'GPU', 'RAM', 'SSD', 'Mainboard', 'PSU'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(chip, style: const TextStyle(fontSize: 12)),
                  onPressed: () { _ctrl.text = chip; _send(); },
                  backgroundColor: DesignTokens.primary.withValues(alpha: 0.08),
                ),
              ),
          ]),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Tìm linh kiện...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _Message msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == _Sender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 14, backgroundColor: DesignTokens.primary,
                  child: Icon(Icons.smart_toy, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? DesignTokens.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          if (msg.products.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: msg.products.length,
                itemBuilder: (_, i) => _ProductChip(product: msg.products[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  final ProductModel product;
  const _ProductChip({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              product.mainImage.isNotEmpty
                  ? product.mainImage
                  : 'https://picsum.photos/seed/${product.id}/300/300',
              height: 100, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100, color: Colors.grey.shade100,
                child: const Icon(Icons.computer, color: Colors.grey, size: 36),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.brand,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  Text(product.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatVND(product.effectivePrice),
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: product.isOnSale ? Colors.red : DesignTokens.primary,
                    ),
                  ),
                ]),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary, borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Xem chi tiết',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const CircleAvatar(
          radius: 14, backgroundColor: DesignTokens.primary,
          child: Icon(Icons.smart_toy, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Transform.translate(
                  offset: Offset(0, i == 1 ? -4 * _anim.value : (i == 0 ? -4 * (_anim.value * 0.5) : -4 * (_anim.value * 0.7))),
                  child: Container(width: 7, height: 7,
                      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}


