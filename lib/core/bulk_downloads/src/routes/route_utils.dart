// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../router.dart';
import 'internal_routes.dart';

Future<void> goToBulkDownloadPage(
  BuildContext context,
  List<String>? tags, {
  required WidgetRef ref,
}) async {
  if (tags != null) {
    goToNewBulkDownloadTaskPage(
      ref,
      context,
      initialValue: tags,
    );
  } else {
    unawaited(context.pushNamed(kBulkdownload));
  }
}
