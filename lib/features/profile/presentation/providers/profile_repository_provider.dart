import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/network/dio_client.dart';
import 'package:stitch_diag_demo/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:stitch_diag_demo/features/profile/data/sources/profile_remote_source.dart';
import 'package:stitch_diag_demo/features/profile/domain/entities/profile_me_entity.dart';
import 'package:stitch_diag_demo/features/profile/domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  initInjector();
  final dioClient = getIt<DioClient>();
  final remoteSource = ProfileRemoteSource(dioClient);
  return ProfileRepositoryImpl(remoteSource);
});

final profileMeProvider = FutureProvider<ProfileMeEntity>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMe();
});
