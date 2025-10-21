import 'package:flutter/cupertino.dart';
import 'package:okara_chat/models/model_response.dart';
import 'package:okara_chat/widgets/model_response_card.dart';

class ModelResponsesView extends StatefulWidget {
  final int index;
  final Map<AIModel, ModelResponse> responses;

  const ModelResponsesView({
    super.key,
    required this.index,
    required this.responses,
  });

  @override
  State<ModelResponsesView> createState() => _ModelResponsesViewState();
}

class _ModelResponsesViewState extends State<ModelResponsesView> {
  AIModel? _expandedModel;

  @override
  void initState() {
    super.initState();
    // If there is only one response, expand it by default.
    if (widget.responses.length == 1) {
      _expandedModel = widget.responses.keys.first;
    }
  }

  void _handleTap(AIModel model) {
    // Do not allow collapsing the card if there is only one response.
    if (widget.responses.length == 1) {
      return;
    }

    setState(() {
      if (_expandedModel == model) {
        _expandedModel = null;
      } else {
        _expandedModel = model;
      }
    });
  }

  Alignment get _alignment {
    if (_expandedModel?.index == 0) {
      return Alignment.topLeft;
    } else if (_expandedModel?.index == 2) {
      return Alignment.topRight;
    } else {
      return Alignment.topCenter;
    }
  }

  bool get _allResponsesCompleted {
    return widget.responses.isNotEmpty &&
        widget.responses.values.every(
          (r) => r.status == ResponseStatus.completed,
        );
  }

  AIModel? get _fastestModel {
    if (!_allResponsesCompleted) return null;

    AIModel? fastestModel;
    double maxTokensPerSec = 0;

    widget.responses.forEach((model, response) {
      if (response.latency > 0) {
        final tokensPerSec = response.tokens / (response.latency / 1000);
        if (tokensPerSec > maxTokensPerSec) {
          maxTokensPerSec = tokensPerSec;
          fastestModel = model;
        }
      }
    });

    return fastestModel;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(children: [if (currentChild != null) currentChild]);
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: _alignment,
            scale: animation,
            child: child,
          ),
        );
      },
      child: _expandedModel == null
          ? _buildPreviewLayout()
          : _buildExpandedLayout(),
    );
  }

  Widget _buildPreviewLayout() {
    final fastestModel = _fastestModel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.responses.keys.map((model) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ModelResponseCard(
              response: widget.responses[model]!,
              isExpanded: false,
              onTap: () => _handleTap(model),
              isFast: widget.responses.length == 1,
              isFastest: model == fastestModel,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedLayout() {
    final expandedResponse = widget.responses[_expandedModel]!;
    final otherModels = widget.responses.keys
        .where((m) => m != _expandedModel)
        .toList();

    return Column(
      children: [
        ModelResponseCard(
          response: expandedResponse,
          isExpanded: true,
          onTap: () => _handleTap(_expandedModel!),
          isFast: widget.responses.length == 1,
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: otherModels.map((model) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CupertinoButton(
                onPressed: () => _handleTap(model),
                color: CupertinoColors.systemGrey4,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(_getModelName(model)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getModelName(AIModel model) {
    switch (model) {
      case AIModel.openaiGpt4o:
        return 'GPT-4o';
      case AIModel.anthropicClaude:
        return 'Claude 3.5 Sonnet';
      case AIModel.xaiGrok:
        return 'Grok-4';
    }
  }
}
