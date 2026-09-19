import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Unified scaffold for AI Chat and Private Chat screens.
class ChatScaffold extends StatelessWidget {
  final PreferredSizeWidget? header;
  final Widget body;
  final Widget? composer;
  final Widget? drawer;

  const ChatScaffold({
    super.key,
    this.header,
    required this.body,
    this.composer,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = MiraloColors.bg(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: header,
      drawer: drawer,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            ?composer,
          ],
        ),
      ),
    );
  }
}
