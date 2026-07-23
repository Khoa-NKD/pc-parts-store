import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/payos_client_service.dart';

class PayOSWebViewScreen extends StatefulWidget {
  final String url;
  final int orderCode;
  const PayOSWebViewScreen({super.key, required this.url, required this.orderCode});

  @override
  State<PayOSWebViewScreen> createState() => _PayOSWebViewScreenState();
}

class _PayOSWebViewScreenState extends State<PayOSWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  Timer? _statusTimer;
  final _payOSClient = PayOSClientService();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _loading = true);
            // Vẫn giữ kiểm tra URL callback để đóng nhanh nếu web chuyển hướng
            if (url.contains('payment-success') || url.contains('status=PAID')) {
              _statusTimer?.cancel();
              Navigator.pop(context, 'success');
            } else if (url.contains('payment-cancel') || url.contains('status=CANCELLED')) {
              _statusTimer?.cancel();
              Navigator.pop(context, 'cancel');
            }
          },
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Bắt đầu thăm dò trạng thái mỗi 3 giây
    _startPolling();
  }

  void _startPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final status = await _payOSClient.getPaymentStatus(widget.orderCode);
      if (status == 'PAID') {
        timer.cancel();
        if (mounted) Navigator.pop(context, 'success');
      } else if (status == 'CANCELLED' || status == 'EXPIRED') {
        timer.cancel();
        if (mounted) Navigator.pop(context, 'cancel');
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán PayOS'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, 'cancel'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
