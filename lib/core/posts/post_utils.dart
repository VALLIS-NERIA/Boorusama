// Project imports:
import 'package:boorusama/core/tags/tags.dart';
import 'post.dart';

Set<String> splitRawTagString(String? rawTagString) {
  if (rawTagString == null) return {};
  if (rawTagString.isEmpty) return {};

  return rawTagString.split(' ').where((element) => element.isNotEmpty).toSet();
}

extension TagStringSplitter on String? {
  Set<String> splitTagString() => splitRawTagString(this);
}

extension PostTagX on Post {
  List<Tag> extractTags() => tags
      .map((e) => Tag.noCount(
            name: e,
            category: TagCategory.general(),
          ))
      .toList();
}

extension PostsX on Iterable<Post> {
  Map<String, int> extractTagsWithoutCount() {
    final tagCounts = <String, int>{};

    for (final item in this) {
      for (final tag in item.tags) {
        if (tagCounts.containsKey(tag)) {
          tagCounts[tag] = tagCounts[tag]! + 1;
        } else {
          tagCounts[tag] = 1;
        }
      }
    }

    return tagCounts;
  }
}
