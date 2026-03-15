import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/superadmin/data/superadmin_repository.dart';

final superadminUsersProvider = FutureProvider.autoDispose
    .family<SuperadminUsersPage, SuperadminUsersQuery>((ref, query) async {
      final repository = ref.watch(superadminRepositoryProvider);
      return repository.fetchUsers(query);
    });
