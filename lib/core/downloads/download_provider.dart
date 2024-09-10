// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:boorusama/boorus/booru_builder.dart';
import 'package:boorusama/boorus/providers.dart';
import 'package:boorusama/core/configs/configs.dart';
import 'package:boorusama/core/configs/manage/manage.dart';
import 'package:boorusama/core/downloads/downloads.dart';
import 'package:boorusama/core/images/providers.dart';
import 'package:boorusama/core/posts/posts.dart';
import 'package:boorusama/core/settings/settings.dart';
import 'package:boorusama/foundation/http/http.dart';
import 'package:boorusama/foundation/networking/networking.dart';
import 'package:boorusama/foundation/path.dart';
import 'package:boorusama/foundation/permissions.dart';
import 'package:boorusama/foundation/platform.dart';
import 'package:boorusama/foundation/toast.dart';

final downloadNotificationProvider = Provider<DownloadNotifications>((ref) {
  throw UnimplementedError();
});

String? getDownloadFileUrl(Post post, Settings settings) {
  if (post.isVideo) return post.videoUrl;

  final urls = [
    post.originalImageUrl,
    post.sampleImageUrl,
    post.thumbnailImageUrl
  ];

  return switch (settings.downloadQuality) {
    DownloadQuality.original => urls.firstWhereOrNull((e) => e.isNotEmpty),
    DownloadQuality.sample =>
      urls.skip(1).firstWhereOrNull((e) => e.isNotEmpty),
    DownloadQuality.preview => post.thumbnailImageUrl,
  };
}

final downloadServiceProvider = Provider.family<DownloadService, BooruConfig>(
  (ref, config) {
    final useLegacy = ref
        .watch(settingsProvider.select((value) => value.useLegacyDownloader));

    if (!useLegacy) {
      return BackgroundDownloader();
    }

    final dio = newDio(ref.watch(dioArgsProvider(config)));
    final notifications = ref.watch(downloadNotificationProvider);

    return DioDownloadService(
      dio,
      notifications,
      retryOn404: config.booruType.hasUnknownFullImageUrl,
    );
  },
  dependencies: [
    dioArgsProvider,
    downloadNotificationProvider,
    currentBooruConfigProvider,
    settingsProvider,
  ],
);

String generateMd5FileNameFor(Post item, String fileUrl) =>
    '${item.md5}${sanitizedExtension(fileUrl)}';

String sanitizedExtension(String url) {
  return extension(sanitizedUrl(url));
}

String sanitizedUrl(String url) {
  final ext = extension(url);
  final indexOfQuestionMark = ext.indexOf('?');

  if (indexOfQuestionMark != -1) {
    final trimmedExt = ext.substring(0, indexOfQuestionMark);

    return url.replaceFirst(ext, trimmedExt);
  } else {
    return url;
  }
}

extension BooruConfigDownloadX on BooruConfig {
  bool get hasCustomDownloadLocation =>
      customDownloadLocation != null && customDownloadLocation!.isNotEmpty;
}

extension PostDownloadX on WidgetRef {
  Future<void> download(
    Post post, {
    String? group,
    String? downloadPath,
  }) async {
    final perm = await read(deviceStoragePermissionProvider.future);
    final settings = read(settingsProvider);

    await _download(
      this,
      post,
      permission: isAndroid() || isIOS() ? perm.storagePermission : null,
      settings: settings,
      group: group,
      downloadPath: downloadPath,
    );
  }
}

Future<void> _download(
  WidgetRef ref,
  Post downloadable, {
  PermissionStatus? permission,
  required Settings settings,
  String? group,
  String? downloadPath,
}) async {
  final booruConfig = ref.readConfig;
  final service = ref.read(downloadServiceProvider(booruConfig));
  final fileNameBuilder =
      ref.readBooruBuilder(booruConfig)?.downloadFilenameBuilder;
  final downloadUrl = getDownloadFileUrl(downloadable, settings);

  final logger = ref.read(loggerProvider);

  if (fileNameBuilder == null) {
    logger.logE('Single Download', 'No file name builder found, aborting...');
    showErrorToast(ref.context, 'Download aborted, cannot create file name');
    return;
  }

  if (downloadUrl == null || downloadUrl.isEmpty) {
    logger.logE('Single Download', 'No download url found, aborting...');
    showErrorToast(ref.context, 'Download aborted, no download url found');
    return;
  }

  Future<void> download() async => service
      .downloadWithSettings(
        settings,
        config: booruConfig,
        metadata: DownloaderMetadata(
          thumbnailUrl: downloadable.thumbnailImageUrl,
          fileSize: downloadable.fileSize,
          siteUrl: PostSource.from(downloadable.thumbnailImageUrl).url,
          group: group,
        ),
        url: downloadUrl,
        filename: fileNameBuilder.generate(
          settings,
          booruConfig,
          downloadable,
        ),
        headers: {
          AppHttpHeaders.userAgentHeader:
              ref.read(userAgentGeneratorProvider(booruConfig)).generate(),
          ...ref.read(extraHttpHeaderProvider(booruConfig)),
        },
        path: downloadPath,
      )
      .run();

  // Platform doesn't require permissions, just download it right away
  if (permission == null) {
    download();
    return;
  }

  if (permission == PermissionStatus.granted) {
    download();
  } else {
    logger.logI('Single Download', 'Permission not granted, requesting...');
    ref.read(deviceStoragePermissionProvider.notifier).requestPermission(
      onDone: (isGranted) {
        if (isGranted) {
          download();
        } else {
          logger.logI('Single Download',
              'Storage permission request denied, aborting...');
        }
      },
    );
  }
}
