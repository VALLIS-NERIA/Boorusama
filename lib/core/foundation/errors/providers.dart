// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'reporter.dart';

final errorReporterProvider = FutureProvider<ErrorReporter>(
  (ref) => NoErrorReporter(),
);
