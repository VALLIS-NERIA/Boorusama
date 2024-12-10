// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:boorusama/router.dart';

void goToForumPage(BuildContext context) {
  context.push(
    Uri(
      pathSegments: [
        '',
        'danbooru',
        'forum_topics',
      ],
    ).toString(),
  );
}
