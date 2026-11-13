import 'package:flutter/material.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/home_theme.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/trip_view_logic.dart';

/// Hành trình dạng timeline: chấm xanh (xong), vòng vàng (đang diễn ra), vòng xám (chưa tới).
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.steps});
  final List<TimelineStep> steps;

  Widget _dot(TimelineStepState s) {
    switch (s) {
      case TimelineStepState.done:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(color: HomeColors.primaryMid, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case TimelineStepState.current:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: HomeColors.yellow, width: 6),
          ),
        );
      case TimelineStepState.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: HomeColors.grey, width: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      _dot(steps[i].state),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 2,
                              color: steps[i].state == TimelineStepState.done
                                  ? HomeColors.primaryMid
                                  : HomeColors.greySoft,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, bottom: i < steps.length - 1 ? 18 : 0),
                    child: Text(
                      steps[i].title,
                      style: homeText(
                        14,
                        steps[i].state == TimelineStepState.current
                            ? FontWeight.w700
                            : FontWeight.w500,
                        HomeColors.ink,
                      ),
                    ),
                  ),
                ),
                if (steps[i].time != null) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      steps[i].time!,
                      style: homeText(
                        13,
                        steps[i].state == TimelineStepState.current
                            ? FontWeight.w700
                            : FontWeight.w400,
                        HomeColors.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}