import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/network/api_client.dart';

class SuperadminUser {
  const SuperadminUser({
    required this.id,
    required this.roles,
    this.name,
    this.username,
    this.primaryEmail,
    this.avatar,
  });

  final String id;
  final String? name;
  final String? username;
  final String? primaryEmail;
  final String? avatar;
  final List<String> roles;

  String get displayLabel =>
      name?.trim().isNotEmpty == true
          ? name!
          : username?.trim().isNotEmpty == true
          ? username!
          : id;
}

class SuperadminUsersPage {
  const SuperadminUsersPage({
    required this.users,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<SuperadminUser> users;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total || users.length == pageSize;
}

class SuperadminUsersQuery {
  const SuperadminUsersQuery({
    this.search = '',
    this.page = 1,
    this.pageSize = 20,
  });

  final String search;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is SuperadminUsersQuery &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(search, page, pageSize);
}

final superadminRepositoryProvider = Provider<SuperadminRepository>((ref) {
  return SuperadminRepository(dio: ref.watch(apiClientProvider));
});

class SuperadminRepository {
  const SuperadminRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<SuperadminUsersPage> fetchUsers(SuperadminUsersQuery query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/superadmin/users',
      queryParameters: {
        'search': query.search,
        'page': query.page,
        'pageSize': query.pageSize,
      },
    );

    final payload = response.data;
    final data = payload?['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing superadmin users payload');
    }

    final rawUsers = data['users'];
    final users =
        rawUsers is List
            ? rawUsers
                .whereType<Map<String, dynamic>>()
                .map(_parseUser)
                .toList(growable: false)
            : const <SuperadminUser>[];

    return SuperadminUsersPage(
      users: users,
      page: _readInt(data['page'], fallback: query.page),
      pageSize: _readInt(data['pageSize'], fallback: query.pageSize),
      total: _readInt(data['total'], fallback: users.length),
    );
  }

  SuperadminUser _parseUser(Map<String, dynamic> data) {
    final rawRoles = data['roles'];
    final roles =
        rawRoles is List
            ? rawRoles
                .whereType<String>()
                .map((role) => role.trim())
                .where((role) => role.isNotEmpty)
                .toList(growable: false)
            : const <String>[];

    return SuperadminUser(
      id: _readString(data['id']) ?? '',
      name: _readString(data['name']),
      username: _readString(data['username']),
      primaryEmail: _readString(data['primaryEmail']),
      avatar: _readString(data['avatar']),
      roles: roles,
    );
  }

  int _readInt(Object? value, {required int fallback}) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    if (parsed == null || parsed < 0) {
      return fallback;
    }

    return parsed;
  }

  String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
