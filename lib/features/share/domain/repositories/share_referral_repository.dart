import '../entities/app_id_mapping_entity.dart';
import '../entities/share_identity_entity.dart';
import '../entities/share_touch_result_entity.dart';

abstract class ShareReferralRepository {
  Future<ShareTouchResultEntity> createShareTouch({
    required String shareId,
    required String landingPage,
    String? visitorKey,
  });

  Future<AppIdMappingEntity> getAppIdMapping();

  Future<ShareIdentityEntity> getRefererId();
}
