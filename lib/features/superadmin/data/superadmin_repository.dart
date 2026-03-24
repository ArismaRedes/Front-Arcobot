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
    this.primaryPhone,
    this.avatar,
    this.isSuspended = false,
  });

  final String id;
  final String? name;
  final String? username;
  final String? primaryEmail;
  final String? primaryPhone;
  final String? avatar;
  final bool isSuspended;
  final List<String> roles;

  String get displayLabel =>
      name?.trim().isNotEmpty == true
          ? name!
          : username?.trim().isNotEmpty == true
          ? username!
          : id;
}

class SuperadminOrganizationRole {
  const SuperadminOrganizationRole({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
}

class CreateSuperadminUserInput {
  const CreateSuperadminUserInput({
    this.name,
    this.username,
    this.primaryEmail,
    this.primaryPhone,
    this.avatar,
    this.password,
    this.isSuspended = false,
    this.organizationRoleNames = const <String>[],
  });

  final String? name;
  final String? username;
  final String? primaryEmail;
  final String? primaryPhone;
  final String? avatar;
  final String? password;
  final bool isSuspended;
  final List<String> organizationRoleNames;
}

class UpdateSuperadminUserInput {
  const UpdateSuperadminUserInput({
    this.name,
    this.username,
    this.primaryEmail,
    this.primaryPhone,
    this.avatar,
    this.isSuspended,
    this.organizationRoleNames,
  });

  final String? name;
  final String? username;
  final String? primaryEmail;
  final String? primaryPhone;
  final String? avatar;
  final bool? isSuspended;
  final List<String>? organizationRoleNames;
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

  Future<List<SuperadminOrganizationRole>> fetchOrganizationRoles() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/superadmin/organization-roles',
    );

    final payload = response.data;
    final data = payload?['data'];
    if (data is! List) {
      throw const FormatException('Missing organization roles payload');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(_parseOrganizationRole)
        .toList(growable: false);
  }

  Future<SuperadminUser> createUser(CreateSuperadminUserInput input) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/superadmin/users',
      data: _buildCreatePayload(input),
    );

    return _parseUserFromEnvelope(response.data);
  }

  Future<SuperadminUser> updateUser(
    String userId,
    UpdateSuperadminUserInput input,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/superadmin/users/$userId',
      data: _buildUpdatePayload(input),
    );

    return _parseUserFromEnvelope(response.data);
  }

  Future<void> deleteUser(String userId) {
    return _dio.delete<void>('/api/v1/superadmin/users/$userId');
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
      primaryPhone: _readString(data['primaryPhone']),
      avatar: _readString(data['avatar']),
      isSuspended: data['isSuspended'] == true,
      roles: roles,
    );
  }

  SuperadminOrganizationRole _parseOrganizationRole(Map<String, dynamic> data) {
    return SuperadminOrganizationRole(
      id: _readString(data['id']) ?? '',
      name: _readString(data['name']) ?? '',
      description: _readString(data['description']),
    );
  }

  SuperadminUser _parseUserFromEnvelope(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing superadmin user payload');
    }

    return _parseUser(data);
  }

  Map<String, dynamic> _buildCreatePayload(CreateSuperadminUserInput input) {
    return <String, dynamic>{
      if (_hasText(input.name)) 'name': input.name!.trim(),
      if (_hasText(input.username)) 'username': input.username!.trim(),
      if (_hasText(input.primaryEmail))
        'primaryEmail': input.primaryEmail!.trim(),
      if (_hasText(input.primaryPhone))
        'primaryPhone': input.primaryPhone!.trim(),
      if (_hasText(input.avatar)) 'avatar': input.avatar!.trim(),
      if (_hasText(input.password)) 'password': input.password!.trim(),
      'isSuspended': input.isSuspended,
      'organizationRoleNames': input.organizationRoleNames,
    };
  }

  Map<String, dynamic> _buildUpdatePayload(UpdateSuperadminUserInput input) {
    return <String, dynamic>{
      'name': _clearable(input.name),
      'username': _clearable(input.username),
      'primaryEmail': _clearable(input.primaryEmail),
      'primaryPhone': _clearable(input.primaryPhone),
      'avatar': _clearable(input.avatar),
      if (input.isSuspended != null) 'isSuspended': input.isSuspended,
      if (input.organizationRoleNames != null)
        'organizationRoleNames': input.organizationRoleNames,
    };
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

  Object? _clearable(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _hasText(String? value) => value?.trim().isNotEmpty == true;
}
