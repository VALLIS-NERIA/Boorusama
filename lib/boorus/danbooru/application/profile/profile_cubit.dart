// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/domain/profile/i_profile_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/profile/profile.dart';

class ProfileCubit extends Cubit<AsyncLoadState<Profile>> {
  ProfileCubit({
    required this.profileRepository,
  }) : super(const AsyncLoadState.initial());

  final IProfileRepository profileRepository;

  void getProfile() {
    tryAsync<Profile?>(
        action: () => profileRepository.getProfile(),
        onLoading: () => emit(const AsyncLoadState.loading()),
        onFailure: (stackTrace, error) => emit(const AsyncLoadState.failure()),
        onSuccess: (profile) {
          if (profile == null) {
            emit(const AsyncLoadState.failure());
            return;
          }

          emit(AsyncLoadState.success(profile));
        });
  }
}
