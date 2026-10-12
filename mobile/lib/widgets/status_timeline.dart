import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/order.dart';
import '../data/models/order_status.dart';

enum _StepState { done, current, upcoming }

/// Vertical timeline of an order's progress, with the time each step was
/// reached. A cancelled order shows only "placed" and "cancelled".
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.status,
    required this.history,
  });

  final OrderStatus status;
  final List<StatusChange> history;

  @override
  Widget build(BuildContext context) {
    final steps = status == OrderStatus.cancelled
        ? const [OrderStatus.placed, OrderStatus.cancelled]
        : OrderStatus.flow;
    final reachedAt = {for (final change in history) change.status: change.at};
    final currentIndex = steps.indexOf(status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            status: steps[i],
            state: i < currentIndex || (i == currentIndex && status.isFinal)
                ? _StepState.done
                : i == currentIndex
                ? _StepState.current
                : _StepState.upcoming,
            reachedAt: reachedAt[steps[i]],
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.state,
    required this.reachedAt,
    required this.isLast,
  });

  final OrderStatus status;
  final _StepState state;
  final DateTime? reachedAt;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = reachedAt == null
        ? null
        : DateFormat.jm().format(reachedAt!.toLocal());
    final active = state != _StepState.upcoming;
    final color = status == OrderStatus.cancelled
        ? scheme.error
        : active
        ? scheme.primary
        : scheme.outlineVariant;

    final description = switch (state) {
      _StepState.done => time == null ? 'done' : 'done at $time',
      _StepState.current => 'in progress',
      _StepState.upcoming => 'not yet',
    };

    return Semantics(
      label: '${status.label}, $description',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                _Dot(state: state, color: color, status: status),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: state == _StepState.done
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: active ? null : scheme.onSurfaceVariant,
                        fontWeight: state == _StepState.current
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                    if (time != null)
                      Text(time, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.color, required this.status});

  final _StepState state;
  final Color color;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final onColor = Theme.of(context).colorScheme.onPrimary;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == _StepState.done ? color : null,
        border: Border.all(color: color, width: 2),
      ),
      child: switch (state) {
        _StepState.done => Icon(
          status == OrderStatus.cancelled ? Icons.close : Icons.check,
          size: 16,
          color: onColor,
        ),
        _StepState.current => Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
        _StepState.upcoming => null,
      },
    );
  }
}
