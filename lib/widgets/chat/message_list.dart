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
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _scrollController = widget.controller!;
    } else {
      _scrollController = ScrollController();
      _internalController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Show button if user scrolled up more than 200 pixels from bottom
    final show = (maxScroll - currentScroll) > 200;
    if (show != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = show;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    _scrollController.removeListener(_onScroll);
    if (_internalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.itemCount == 0 && widget.emptyState != null) {
      return Center(child: widget.emptyState);
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            top: MiraloSpacing.md,
            bottom: MiraloSpacing.lg,
          ),
          itemCount: widget.itemCount,
          itemBuilder: widget.itemBuilder,
        ),
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showScrollToBottom ? 1.0 : 0.0,
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: isDark ? MiraloColors.darkSurfaceElevated : MiraloColors.lightSurfacePrimary,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _scrollToBottom,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? MiraloColors.darkBorderHighlight : MiraloColors.lightBorderHighlight,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
