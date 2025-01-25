// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Project imports:
import '../../../../analytics.dart';
import '../../../../boorus/engine/engine.dart';
import '../../../../boorus/engine/providers.dart';
import '../../../../cache/providers.dart';
import '../../../../configs/config.dart';
import '../../../../configs/current.dart';
import '../../../../configs/ref.dart';
import '../../../../foundation/display.dart';
import '../../../../foundation/platform.dart';
import '../../../../notes/notes.dart';
import '../../../../premiums/providers.dart';
import '../../../../router.dart';
import '../../../../settings/providers.dart';
import '../../../../settings/settings.dart';
import '../../../../videos/play_pause_button.dart';
import '../../../../videos/providers.dart';
import '../../../../videos/sound_control_button.dart';
import '../../../../videos/video_progress.dart';
import '../../../../widgets/widgets.dart';
import '../../../details_manager/types.dart';
import '../../../details_pageview/widgets.dart';
import '../../../post/post.dart';
import '../../../post/routes.dart';
import '../../../shares/providers.dart';
import 'post_details_controller.dart';
import 'post_details_full_info_sheet.dart';
import 'post_details_preload_image.dart';
import 'post_media.dart';
import 'video_controls.dart';
import 'volume_key_page_navigator.dart';

const String kShowInfoStateCacheKey = 'showInfoCacheStateKey';

class PostDetailsPageScaffold<T extends Post> extends ConsumerStatefulWidget {
  const PostDetailsPageScaffold({
    required this.posts,
    required this.controller,
    super.key,
    this.onExpanded,
    this.imageUrlBuilder,
    this.topRightButtonsBuilder,
    this.uiBuilder,
    this.preferredParts,
    this.preferredPreviewParts,
  });

  final List<T> posts;
  final void Function()? onExpanded;
  final String Function(T post)? imageUrlBuilder;
  final List<Widget> Function(PostDetailsPageViewController controller)?
      topRightButtonsBuilder;
  final PostDetailsController<T> controller;
  final PostDetailsUIBuilder? uiBuilder;
  final Set<DetailsPart>? preferredParts;
  final Set<DetailsPart>? preferredPreviewParts;

  @override
  ConsumerState<PostDetailsPageScaffold<T>> createState() =>
      _PostDetailPageScaffoldState<T>();
}

class _PostDetailPageScaffoldState<T extends Post>
    extends ConsumerState<PostDetailsPageScaffold<T>> {
  late final _posts = widget.posts;
  late final _controller = PostDetailsPageViewController(
    initialPage: widget.controller.initialPage,
    initialHideOverlay: ref.read(settingsProvider).hidePostDetailsOverlay,
    slideshowOptions: toSlideShowOptions(ref.read(settingsProvider)),
    hoverToControlOverlay: widget.posts[widget.controller.initialPage].isVideo,
    checkIfLargeScreen: () => context.isLargeScreen,
    totalPage: _posts.length,
    disableAnimation:
        ref.read(settingsProvider.select((value) => value.reduceAnimations)),
  );
  late final _volumeKeyPageNavigator = VolumeKeyPageNavigator(
    pageViewController: _controller,
    totalPosts: _posts.length,
    visibilityNotifier: visibilityNotifier,
    enableVolumeKeyViewerNavigation: () => ref.read(
      settingsProvider.select((value) => value.volumeKeyViewerNavigation),
    ),
  );

  final _transformController = TransformationController();

  ValueNotifier<bool> visibilityNotifier = ValueNotifier(false);

  List<T> get posts => _posts;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final videoPlayerEngine =
          ref.read(settingsProvider.select((value) => value.videoPlayerEngine));

      widget.controller.setPage(
        widget.controller.initialPage,
        useDefaultEngine: _isDefaultEngine(videoPlayerEngine),
      );

      if (ref.readConfig.autoFetchNotes) {
        ref.read(notesProvider(ref.readConfigAuth).notifier).load(
              posts[widget.controller.initialPage],
            );
      }
    });

    widget.controller.isVideoPlaying.addListener(_isVideoPlayingChanged);

    _volumeKeyPageNavigator.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformController.dispose();
    _volumeKeyPageNavigator.dispose();
    widget.controller.isVideoPlaying.removeListener(_isVideoPlayingChanged);

    super.dispose();
  }

  var _previouslyPlaying = false;

  bool _isDefaultEngine(VideoPlayerEngine engine) {
    return engine != VideoPlayerEngine.mdk;
  }

  SlideshowOptions toSlideShowOptions(Settings settings) {
    return SlideshowOptions(
      duration: settings.slideshowDuration,
      direction: settings.slideshowDirection,
      skipTransition: settings.skipSlideshowTransition,
    );
  }

  void _isVideoPlayingChanged() {
    // force overlay to be on when video is not playing
    if (!widget.controller.isVideoPlaying.value) {
      _controller.disableHoverToControlOverlay();
    } else {
      if (widget.controller.currentPost.value.isVideo) {
        _controller.enableHoverToControlOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final useDefaultEngine = ref.watch(
      settingsProvider.select(
        (value) => _isDefaultEngine(value.videoPlayerEngine),
      ),
    );

    // Sync slideshow options with settings
    ref.listen(
      settingsProvider.select(
        toSlideShowOptions,
      ),
      (prev, next) {
        if (prev != next) {
          _controller.slideshowOptions = next;
        }
      },
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.keyF,
          control: true,
        ): () => goToOriginalImagePage(
              context,
              widget.posts[_controller.page],
            ),
      },
      child: CustomContextMenuOverlay(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: VisibilityDetector(
          key: const Key('post_details_page_scaffold'),
          onVisibilityChanged: (info) {
            if (!mounted) return;

            if (info.visibleFraction == 0) {
              visibilityNotifier.value = false;
              _previouslyPlaying = widget.controller.isVideoPlaying.value;
              if (_previouslyPlaying) {
                widget.controller.pauseCurrentVideo(
                  useDefaultEngine: useDefaultEngine,
                );
              }
            } else if (info.visibleFraction == 1) {
              visibilityNotifier.value = true;
              if (_previouslyPlaying) {
                widget.controller.playCurrentVideo(
                  useDefaultEngine: useDefaultEngine,
                );
              }
            }
          },
          child: _build(),
        ),
      ),
    );
  }

  Widget _build() {
    final booruBuilder = ref.watch(currentBooruBuilderProvider);
    final postGesturesHandler = booruBuilder?.postGestureHandlerBuilder;
    final gestures = ref.watchPostGestures?.fullview;

    final imageUrlBuilder =
        widget.imageUrlBuilder ?? defaultPostImageUrlBuilder(ref);

    final uiBuilder = widget.uiBuilder ?? booruBuilder?.postDetailsUIBuilder;

    final videoPlayerEngine =
        ref.watch(settingsProvider.select((value) => value.videoPlayerEngine));
    final reduceAnimations =
        ref.watch(settingsProvider.select((value) => value.reduceAnimations));

    void onItemTap() {
      final controller = widget.controller;

      if (isDesktopPlatform()) {
        if (controller.currentPost.value.isVideo) {
          if (controller.isVideoPlaying.value) {
            controller.pauseCurrentVideo(
              useDefaultEngine: _isDefaultEngine(videoPlayerEngine),
            );
          } else {
            controller.playCurrentVideo(
              useDefaultEngine: _isDefaultEngine(videoPlayerEngine),
            );
          }
        } else {
          if (_controller.isExpanded) return;

          _controller.toggleOverlay();
        }
      } else {
        if (_controller.isExpanded) return;

        _controller.toggleOverlay();
      }
    }

    return Scaffold(
      body: PostDetailsPageView(
        disableAnimation: reduceAnimations,
        onPageChanged: (page) {
          widget.controller.setPage(
            page,
            useDefaultEngine: _isDefaultEngine(videoPlayerEngine),
          );

          if (_controller.overlay.value) {
            if (posts[page].isVideo) {
              _controller.enableHoverToControlOverlay();
            } else {
              _controller.disableHoverToControlOverlay();
            }
          }

          ref
              .read(postShareProvider(posts[page]).notifier)
              .updateInformation(posts[page]);

          final config = ref.readConfig;

          if (config.autoFetchNotes) {
            ref.read(notesProvider(config.auth).notifier).load(posts[page]);
          }
        },
        sheetStateStorage: SheetStateStorageBuilder(
          save: (expanded) => ref
              .read(miscDataProvider(kShowInfoStateCacheKey).notifier)
              .put(expanded.toString()),
          load: () =>
              ref.read(miscDataProvider(kShowInfoStateCacheKey)) == 'true',
        ),
        checkIfLargeScreen: () => context.isLargeScreen,
        controller: _controller,
        onExit: () {
          ref.invalidate(notesProvider(ref.readConfigAuth));

          widget.controller.onExit();
        },
        itemCount: posts.length,
        leftActions: [
          CircularIconButton(
            icon: const Icon(
              Symbols.home,
              fill: 1,
            ),
            onPressed: () => goToHomePage(context),
          ),
        ],
        onSwipeDownThresholdReached:
            gestures.canSwipeDown && postGesturesHandler != null
                ? () {
                    _controller.resetSheet();

                    postGesturesHandler(
                      ref,
                      gestures?.swipeDown,
                      posts[_controller.page],
                    );
                  }
                : null,
        sheetBuilder: (context, scrollController) {
          return Consumer(
            builder: (_, ref, __) {
              final layoutDetails = ref.watch(
                currentReadOnlyBooruConfigLayoutProvider
                    .select((value) => value?.details),
              );
              final preferredParts = widget.preferredParts ??
                  getLayoutParsedParts(
                    details: layoutDetails,
                    hasPremium: ref.watch(hasPremiumProvider),
                  ) ??
                  uiBuilder?.full.keys.toSet();

              return ValueListenableBuilder(
                valueListenable: _controller.sheetState,
                builder: (context, state, _) => PostDetailsFullInfoSheet(
                  scrollController: scrollController,
                  sheetState: state,
                  uiBuilder: uiBuilder,
                  preferredParts: preferredParts,
                  canCustomize: kPremiumEnabled && widget.uiBuilder == null,
                ),
              );
            },
          );
        },
        itemBuilder: (context, index) {
          final post = posts[index];
          final (previousPost, nextPost) = posts.getPrevAndNextPosts(index);

          return ValueListenableBuilder(
            valueListenable: _controller.sheetState,
            builder: (_, state, __) => GestureDetector(
              // let the user tap the image to toggle overlay
              onTap: onItemTap,
              child: InteractiveViewerExtended(
                controller: _transformController,
                enable: !state.isExpanded,
                onZoomUpdated: _controller.onZoomUpdated,
                onTap: onItemTap,
                onDoubleTap:
                    gestures.canDoubleTap && postGesturesHandler != null
                        ? () => postGesturesHandler(
                              ref,
                              gestures?.doubleTap,
                              posts[_controller.page],
                            )
                        : null,
                onLongPress:
                    gestures.canLongPress && postGesturesHandler != null
                        ? () => postGesturesHandler(
                              ref,
                              gestures?.longPress,
                              posts[_controller.page],
                            )
                        : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // preload next image only, not the post itself
                    if (nextPost != null && !nextPost.isVideo)
                      Offstage(
                        child: PostDetailsPreloadImage(
                          url: imageUrlBuilder(nextPost),
                        ),
                      ),
                    PostMedia<T>(
                      post: post,
                      imageUrlBuilder: imageUrlBuilder,
                      controller: _controller,
                    ),
                    if (previousPost != null && !previousPost.isVideo)
                      Offstage(
                        child: PostDetailsPreloadImage(
                          url: imageUrlBuilder(previousPost),
                        ),
                      ),
                    if (post.isVideo)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: state.isExpanded && !context.isLargeScreen
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    // duplicate codes, maybe refactor later
                                    PlayPauseButton(
                                      isPlaying:
                                          widget.controller.isVideoPlaying,
                                      onPlayingChanged: (value) {
                                        if (value) {
                                          widget.controller.pauseVideo(
                                            post.id,
                                            post.isWebm,
                                            _isDefaultEngine(videoPlayerEngine),
                                          );
                                        } else if (!value) {
                                          widget.controller.playVideo(
                                            post.id,
                                            post.isWebm,
                                            _isDefaultEngine(videoPlayerEngine),
                                          );
                                        } else {
                                          // do nothing
                                        }
                                      },
                                    ),
                                    VideoSoundScope(
                                      builder: (context, soundOn) =>
                                          SoundControlButton(
                                        padding: const EdgeInsets.all(8),
                                        soundOn: soundOn,
                                        onSoundChanged: (value) =>
                                            ref.setGlobalVideoSound(value),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        bottomSheet: Consumer(
          builder: (_, ref, __) {
            final layoutPreviewDetails = ref.watch(
              currentReadOnlyBooruConfigLayoutProvider
                  .select((value) => value?.previewDetails),
            );

            return widget.uiBuilder != null
                ? _buildCustomPreview(widget.uiBuilder!, layoutPreviewDetails)
                : uiBuilder != null && uiBuilder.preview.isNotEmpty
                    ? _buildCustomPreview(uiBuilder, layoutPreviewDetails)
                    : _buildFallbackPreview();
          },
        ),
        actions: [
          if (widget.topRightButtonsBuilder != null)
            ...widget.topRightButtonsBuilder!(
              _controller,
            )
          else ...[
            ValueListenableBuilder(
              valueListenable: widget.controller.currentPost,
              builder: (context, post, _) => NoteActionButtonWithProvider(
                post: post,
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder(
              valueListenable: widget.controller.currentPost,
              builder: (context, post, _) => GeneralMoreActionButton(
                post: post,
                onStartSlideshow: () => _controller.startSlideshow(),
              ),
            ),
          ],
        ],
        onExpanded: () {
          widget.onExpanded?.call();
          // Reset zoom when expanded
          _transformController.value = Matrix4.identity();
          ref.read(analyticsProvider).logScreenView('/details/info');
        },
        onShrink: () {
          final routeName = ModalRoute.of(context)?.settings.name;
          if (routeName != null) {
            ref.read(analyticsProvider).logScreenView(routeName);
          }
        },
      ),
    );
  }

  Widget _buildCustomPreview(
    PostDetailsUIBuilder uiBuilder,
    List<CustomDetailsPartKey>? layoutPreviewDetails,
  ) {
    final preferredPreviewParts = widget.preferredPreviewParts ??
        getLayoutPreviewParsedParts(
          previewDetails: layoutPreviewDetails,
          hasPremium: ref.watch(hasPremiumProvider),
        ) ??
        uiBuilder.preview.keys.toSet();

    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverToBoxAdapter(
          child: _buildVideoControls(),
        ),
        DecoratedSliver(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          sliver: MultiSliver(
            children: preferredPreviewParts
                .map((p) => uiBuilder.buildPart(context, p))
                .nonNulls
                .toList(),
          ),
        ),
        DecoratedSliver(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          sliver: SliverSizedBox(
            height: MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackPreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVideoControls(),
        SizedBox(
          height: MediaQuery.paddingOf(context).bottom,
        ),
      ],
    );
  }

  Widget _buildVideoControls() {
    return ValueListenableBuilder(
      valueListenable: widget.controller.currentPost,
      builder: (context, post, _) => post.isVideo
          ? PostDetailsVideoControls(
              controller: widget.controller,
            )
          : const SizedBox.shrink(),
    );
  }
}

mixin PostDetailsPageMixin<T extends StatefulWidget, E extends Post>
    on State<T> {
  final _videoProgress = ValueNotifier(VideoProgress.zero);

  //TODO: should have an abstraction for this crap, but I'm too lazy to do it since there are only 2 types of video anyway
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, WebmVideoController> _webmVideoControllers = {};

  List<E> get posts;
  ValueNotifier<VideoProgress> get videoProgress => _videoProgress;

  void onPageChanged(int page) {
    _videoProgress.value = VideoProgress.zero;
  }

  void onCurrentPositionChanged(
    double current,
    double total,
    String url,
    int page,
  ) {
    // check if the current video is the same as the one being played
    if (posts[page].videoUrl != url) return;

    _videoProgress.value = VideoProgress(
      Duration(milliseconds: (total * 1000).toInt()),
      Duration(milliseconds: (current * 1000).toInt()),
    );
  }

  void onVideoSeekTo(Duration position, int page) {
    if (posts[page].videoUrl.endsWith('.webm')) {
      _webmVideoControllers[page]?.seek(position.inSeconds.toDouble());
    } else {
      _videoControllers[page]?.seekTo(position);
    }
  }

  void onWebmVideoPlayerCreated(WebmVideoController controller, int page) {
    _webmVideoControllers[page] = controller;
  }

  void onVideoPlayerCreated(VideoPlayerController controller, int page) {
    _videoControllers[page] = controller;
  }
}

extension PostDetailsUtils<T extends Post> on List<T> {
  (T? prev, T? next) getPrevAndNextPosts(int index) {
    final next = index + 1 < length ? this[index + 1] : null;
    final prev = index - 1 >= 0 ? this[index - 1] : null;

    return (prev, next);
  }
}
