import 'package:flutter/cupertino.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:okara_chat/models/model_response.dart';

class ModelResponseCard extends StatefulWidget {
  final ModelResponse response;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isFast;

  const ModelResponseCard({
    super.key,
    required this.response,
    this.isExpanded = false,
    required this.onTap,
    this.isFast = false,
  });

  @override
  State<ModelResponseCard> createState() => _ModelResponseCardState();
}

class _ModelResponseCardState extends State<ModelResponseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.response.status == ResponseStatus.streaming) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ModelResponseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.response.status != oldWidget.response.status) {
      if (widget.response.status == ResponseStatus.streaming) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Column(
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: widget.isExpanded ? 8 : 2,
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getModelName(
                          widget.response.model,
                          isFast: widget.isFast,
                        ),
                        style: theme.textTheme.navTitleTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontFamily: 'Poly',
                        ),
                      ),
                      if (widget.isFast)
                        const Icon(
                          CupertinoIcons.bolt_fill,
                          color: CupertinoColors.systemYellow,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  AnimatedCrossFade(
                    firstChild: _buildPreviewContent(context),
                    secondChild: _buildExpandedContent(context),
                    crossFadeState: widget.isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!widget.isExpanded &&
            (widget.response.status == ResponseStatus.completed ||
                widget.response.status == ResponseStatus.streaming)) ...[
          const SizedBox(height: 8.0),
          _buildMetrics(context),
        ],
      ],
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    return Text(
      widget.response.content,
      maxLines: 8,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: CupertinoColors.black.withOpacity(0.8)),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GptMarkdown(
          widget.response.content,
          style: TextStyle(color: CupertinoColors.black.withOpacity(0.8)),
        ),
        const SizedBox(height: 16.0),
        _buildMetrics(context),
      ],
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(context, 'Tokens', '${widget.response.tokens}'),
            _buildMetricItem(
              context,
              'Latency',
              '${(widget.response.latency / 1000).toStringAsFixed(1)}s',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value) {
    final theme = CupertinoTheme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.tabLabelTextStyle.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getModelName(AIModel model, {bool isFast = false}) {
    if (isFast) {
      return 'Groq Llama 3.1';
    }
    switch (model) {
      case AIModel.openaiGpt4o:
        return 'GPT-4o';
      case AIModel.anthropicClaude:
        return 'Claude';
      case AIModel.xaiGrok:
        return 'Grok';
    }
  }
}
