import 'package:boorusama/domain/posts/i_post_repository.dart';
import 'package:boorusama/domain/posts/post.dart';
import 'package:boorusama/domain/posts/time_scale.dart';
import 'package:boorusama/infrastructure/repositories/posts/post_repository.dart';
import 'package:boorusama/infrastructure/repositories/settings/i_setting_repository.dart';
import 'package:boorusama/infrastructure/repositories/settings/setting_repository.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../post_filter.dart';

part 'curated_state.dart';
part 'curated_state_notifier.freezed.dart';

class CuratedStateNotifier extends StateNotifier<CuratedState> {
  final IPostRepository _postRepository;
  final ISettingRepository _settingRepository;

  CuratedStateNotifier(ProviderReference ref)
      : _postRepository = ref.read(postProvider),
        _settingRepository = ref.read(settingsProvider),
        super(CuratedState.initial());

  void getPosts(DateTime date, int page, TimeScale scale) async {
    try {
      state = CuratedState.loading();

      final dtos = await _postRepository.getCuratedPosts(date, page, scale);
      final settings = await _settingRepository.load();
      final filteredPosts = filter(dtos, settings);

      state = CuratedState.fetched(
        posts: filteredPosts,
        page: page,
        date: date,
        scale: scale,
      );
    } on DatabaseTimeOut catch (e) {
      state =
          CuratedState.error(name: "Errors", message: "Something went wrong");
    }
  }

  void refresh() async {
    try {
      state = CuratedState.loading();

      final date = DateTime.now();
      final page = 1;
      final scale = TimeScale.day;

      final dtos = await _postRepository.getCuratedPosts(date, page, scale);
      final settings = await _settingRepository.load();
      final filteredPosts = filter(dtos, settings);

      state = CuratedState.fetched(
        posts: filteredPosts,
        page: page,
        scale: scale,
        date: date,
      );
    } on DatabaseTimeOut catch (e) {}
  }

  void getMorePosts(
      List<Post> currentPosts, DateTime date, int page, TimeScale scale) async {
    try {
      final nextPage = page + 1;
      final dtos = await _postRepository.getCuratedPosts(date, nextPage, scale);
      final settings = await _settingRepository.load();
      final filteredPosts = filter(dtos, settings);

      state = CuratedState.fetched(
        posts: currentPosts..addAll(filteredPosts),
        page: nextPage,
        scale: scale,
        date: date,
      );
    } on DatabaseTimeOut catch (e) {}
  }
}
