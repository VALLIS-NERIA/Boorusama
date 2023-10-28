// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:boorusama/flutter.dart';

class RecommendSectionPlaceHolder extends StatelessWidget {
  const RecommendSectionPlaceHolder({
    super.key,
    required this.header,
  });

  final Widget header;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header,
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: context.screenHeight * 0.3,
            child: const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
        ),
      ],
    );
  }
}
