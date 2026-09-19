import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Shared scrollable message list for AI Chat and Private Chat.
class MessageList extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? emptyState;
  final ScrollController? controller;

  const MessageList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.emptyState,
    this.controller,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late final ScrollController _scrollController;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _scrollController = widget.controller!;
    } else {
      _scrollController = ScrollController();
      _internalController = true;
    }
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount > oldWidget.itemCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0 && widget.emptyState != null) {
      return Center(child: widget.emptyState);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: MiraloSpacing.md,
        bottom: MiraloSpacing.lg,
      ),
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }
}
