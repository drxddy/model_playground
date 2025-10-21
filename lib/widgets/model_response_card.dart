import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:okara_chat/models/model_response.dart';

class ModelResponseCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: CupertinoColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: isExpanded ? 8 : 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getModelName(response.model, isFast: isFast),
                  style: theme.textTheme.navTitleTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                if (isFast)
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
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    return Text(
      response.content,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: CupertinoTheme.of(context).textTheme.textStyle,
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GptMarkdown(
          response.content,
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
        const SizedBox(height: 16.0),
        _buildMetrics(context),
      ],
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(context, 'Tokens', '${response.tokens}T'),
          _buildMetricItem(context, 'Latency', '${response.latency} ms'),
        ],
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
