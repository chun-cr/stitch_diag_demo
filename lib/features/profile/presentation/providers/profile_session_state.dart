import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stitch_diag_demo/features/profile/data/stores/profile_address_store.dart';

import 'profile_address_provider.dart';
import 'profile_points_provider.dart';
import 'profile_repository_provider.dart';

Future<void> clearProfileScopedPersistence() async {
  await ProfileAddressStore().clear();
}

void invalidateProfileScopedProvidersInContainer(ProviderContainer container) {
  container.invalidate(profileMeProvider);
  container.invalidate(profileAddressesProvider);
  container.invalidate(profileDefaultShippingAddressProvider);
  container.invalidate(profilePointsBalanceProvider);
  container.invalidate(profilePointsProvider);
}

void invalidateProfileScopedProviders(WidgetRef ref) {
  ref.invalidate(profileMeProvider);
  ref.invalidate(profileAddressesProvider);
  ref.invalidate(profileDefaultShippingAddressProvider);
  ref.invalidate(profilePointsBalanceProvider);
  ref.invalidate(profilePointsProvider);
}
