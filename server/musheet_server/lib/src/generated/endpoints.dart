/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/admin_endpoint.dart' as _i2;
import '../endpoints/admin_user_endpoint.dart' as _i3;
import '../endpoints/application_endpoint.dart' as _i4;
import '../endpoints/auth_endpoint.dart' as _i5;
import '../endpoints/file_endpoint.dart' as _i6;
import '../endpoints/library_sync_endpoint.dart' as _i7;
import '../endpoints/profile_endpoint.dart' as _i8;
import '../endpoints/score_endpoint.dart' as _i9;
import '../endpoints/setlist_endpoint.dart' as _i10;
import '../endpoints/status_endpoint.dart' as _i11;
import '../endpoints/sync_endpoint.dart' as _i12;
import '../endpoints/team_annotation_endpoint.dart' as _i13;
import '../endpoints/team_endpoint.dart' as _i14;
import '../endpoints/team_score_endpoint.dart' as _i15;
import '../endpoints/team_setlist_endpoint.dart' as _i16;
import 'dart:typed_data' as _i17;
import 'package:musheet_server/src/generated/dto/sync_push_request.dart'
    as _i18;
import 'package:musheet_server/src/generated/score.dart' as _i19;
import 'package:musheet_server/src/generated/annotation.dart' as _i20;
import 'package:musheet_server/src/generated/instrument_score.dart' as _i21;
import 'package:musheet_server/src/generated/setlist.dart' as _i22;
import 'package:musheet_server/src/generated/setlist_score.dart' as _i23;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'admin': _i2.AdminEndpoint()
        ..initialize(
          server,
          'admin',
          null,
        ),
      'adminUser': _i3.AdminUserEndpoint()
        ..initialize(
          server,
          'adminUser',
          null,
        ),
      'application': _i4.ApplicationEndpoint()
        ..initialize(
          server,
          'application',
          null,
        ),
      'auth': _i5.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'file': _i6.FileEndpoint()
        ..initialize(
          server,
          'file',
          null,
        ),
      'librarySync': _i7.LibrarySyncEndpoint()
        ..initialize(
          server,
          'librarySync',
          null,
        ),
      'profile': _i8.ProfileEndpoint()
        ..initialize(
          server,
          'profile',
          null,
        ),
      'score': _i9.ScoreEndpoint()
        ..initialize(
          server,
          'score',
          null,
        ),
      'setlist': _i10.SetlistEndpoint()
        ..initialize(
          server,
          'setlist',
          null,
        ),
      'status': _i11.StatusEndpoint()
        ..initialize(
          server,
          'status',
          null,
        ),
      'sync': _i12.SyncEndpoint()
        ..initialize(
          server,
          'sync',
          null,
        ),
      'teamAnnotation': _i13.TeamAnnotationEndpoint()
        ..initialize(
          server,
          'teamAnnotation',
          null,
        ),
      'team': _i14.TeamEndpoint()
        ..initialize(
          server,
          'team',
          null,
        ),
      'teamScore': _i15.TeamScoreEndpoint()
        ..initialize(
          server,
          'teamScore',
          null,
        ),
      'teamSetlist': _i16.TeamSetlistEndpoint()
        ..initialize(
          server,
          'teamSetlist',
          null,
        ),
    };
    connectors['admin'] = _i1.EndpointConnector(
      name: 'admin',
      endpoint: endpoints['admin']!,
      methodConnectors: {
        'getDashboardStats': _i1.MethodConnector(
          name: 'getDashboardStats',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i2.AdminEndpoint).getDashboardStats(
                    session,
                    params['adminUserId'],
                  ),
        ),
        'getAllUsers': _i1.MethodConnector(
          name: 'getAllUsers',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'page': _i1.ParameterDescription(
              name: 'page',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'pageSize': _i1.ParameterDescription(
              name: 'pageSize',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i2.AdminEndpoint).getAllUsers(
                session,
                params['adminUserId'],
                page: params['page'],
                pageSize: params['pageSize'],
              ),
        ),
        'getAllTeams': _i1.MethodConnector(
          name: 'getAllTeams',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'page': _i1.ParameterDescription(
              name: 'page',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'pageSize': _i1.ParameterDescription(
              name: 'pageSize',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i2.AdminEndpoint).getAllTeams(
                session,
                params['adminUserId'],
                page: params['page'],
                pageSize: params['pageSize'],
              ),
        ),
        'deactivateUser': _i1.MethodConnector(
          name: 'deactivateUser',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i2.AdminEndpoint).deactivateUser(
                    session,
                    params['adminUserId'],
                    params['targetUserId'],
                  ),
        ),
        'reactivateUser': _i1.MethodConnector(
          name: 'reactivateUser',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i2.AdminEndpoint).reactivateUser(
                    session,
                    params['adminUserId'],
                    params['targetUserId'],
                  ),
        ),
        'deleteUser': _i1.MethodConnector(
          name: 'deleteUser',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i2.AdminEndpoint).deleteUser(
                session,
                params['adminUserId'],
                params['targetUserId'],
              ),
        ),
        'promoteToAdmin': _i1.MethodConnector(
          name: 'promoteToAdmin',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i2.AdminEndpoint).promoteToAdmin(
                    session,
                    params['adminUserId'],
                    params['targetUserId'],
                  ),
        ),
        'demoteFromAdmin': _i1.MethodConnector(
          name: 'demoteFromAdmin',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i2.AdminEndpoint).demoteFromAdmin(
                    session,
                    params['adminUserId'],
                    params['targetUserId'],
                  ),
        ),
        'deleteTeam': _i1.MethodConnector(
          name: 'deleteTeam',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i2.AdminEndpoint).deleteTeam(
                session,
                params['adminUserId'],
                params['teamId'],
              ),
        ),
      },
    );
    connectors['adminUser'] = _i1.EndpointConnector(
      name: 'adminUser',
      endpoint: endpoints['adminUser']!,
      methodConnectors: {
        'registerAdmin': _i1.MethodConnector(
          name: 'registerAdmin',
          params: {
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminUser'] as _i3.AdminUserEndpoint)
                  .registerAdmin(
                    session,
                    params['username'],
                    params['password'],
                    params['displayName'],
                  ),
        ),
        'createUser': _i1.MethodConnector(
          name: 'createUser',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'initialPassword': _i1.ParameterDescription(
              name: 'initialPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'isAdmin': _i1.ParameterDescription(
              name: 'isAdmin',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminUser'] as _i3.AdminUserEndpoint).createUser(
                    session,
                    params['adminUserId'],
                    params['username'],
                    params['initialPassword'],
                    params['displayName'],
                    params['isAdmin'],
                  ),
        ),
        'getUsers': _i1.MethodConnector(
          name: 'getUsers',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminUser'] as _i3.AdminUserEndpoint).getUsers(
                    session,
                    params['adminUserId'],
                  ),
        ),
        'getUserById': _i1.MethodConnector(
          name: 'getUserById',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminUser'] as _i3.AdminUserEndpoint).getUserById(
                    session,
                    params['adminUserId'],
                    params['userId'],
                  ),
        ),
        'resetUserPassword': _i1.MethodConnector(
          name: 'resetUserPassword',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminUser'] as _i3.AdminUserEndpoint)
                  .resetUserPassword(
                    session,
                    params['adminUserId'],
                    params['userId'],
                  ),
        ),
        'setUserDisabled': _i1.MethodConnector(
          name: 'setUserDisabled',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'disabled': _i1.ParameterDescription(
              name: 'disabled',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminUser'] as _i3.AdminUserEndpoint)
                  .setUserDisabled(
                    session,
                    params['adminUserId'],
                    params['userId'],
                    params['disabled'],
                  ),
        ),
        'deleteUser': _i1.MethodConnector(
          name: 'deleteUser',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminUser'] as _i3.AdminUserEndpoint).deleteUser(
                    session,
                    params['adminUserId'],
                    params['userId'],
                  ),
        ),
        'setUserAdmin': _i1.MethodConnector(
          name: 'setUserAdmin',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'isAdmin': _i1.ParameterDescription(
              name: 'isAdmin',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminUser'] as _i3.AdminUserEndpoint)
                  .setUserAdmin(
                    session,
                    params['adminUserId'],
                    params['userId'],
                    params['isAdmin'],
                  ),
        ),
        'updateUser': _i1.MethodConnector(
          name: 'updateUser',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['adminUser'] as _i3.AdminUserEndpoint).updateUser(
                    session,
                    params['adminUserId'],
                    params['userId'],
                    params['displayName'],
                  ),
        ),
        'needsAdminRegistration': _i1.MethodConnector(
          name: 'needsAdminRegistration',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['adminUser'] as _i3.AdminUserEndpoint)
                  .needsAdminRegistration(session),
        ),
      },
    );
    connectors['application'] = _i1.EndpointConnector(
      name: 'application',
      endpoint: endpoints['application']!,
      methodConnectors: {
        'getApplications': _i1.MethodConnector(
          name: 'getApplications',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .getApplications(
                    session,
                    params['adminUserId'],
                  ),
        ),
        'registerApplication': _i1.MethodConnector(
          name: 'registerApplication',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'appId': _i1.ParameterDescription(
              name: 'appId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .registerApplication(
                    session,
                    params['adminUserId'],
                    params['appId'],
                    params['name'],
                    description: params['description'],
                  ),
        ),
        'updateApplication': _i1.MethodConnector(
          name: 'updateApplication',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'applicationId': _i1.ParameterDescription(
              name: 'applicationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .updateApplication(
                    session,
                    params['adminUserId'],
                    params['applicationId'],
                    name: params['name'],
                    description: params['description'],
                    isActive: params['isActive'],
                  ),
        ),
        'deleteApplication': _i1.MethodConnector(
          name: 'deleteApplication',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'applicationId': _i1.ParameterDescription(
              name: 'applicationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .deleteApplication(
                    session,
                    params['adminUserId'],
                    params['applicationId'],
                  ),
        ),
        'getApplicationById': _i1.MethodConnector(
          name: 'getApplicationById',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'applicationId': _i1.ParameterDescription(
              name: 'applicationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .getApplicationById(
                    session,
                    params['adminUserId'],
                    params['applicationId'],
                  ),
        ),
        'getApplicationByAppId': _i1.MethodConnector(
          name: 'getApplicationByAppId',
          params: {
            'appId': _i1.ParameterDescription(
              name: 'appId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .getApplicationByAppId(
                    session,
                    params['appId'],
                  ),
        ),
        'activateApplication': _i1.MethodConnector(
          name: 'activateApplication',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'applicationId': _i1.ParameterDescription(
              name: 'applicationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .activateApplication(
                    session,
                    params['adminUserId'],
                    params['applicationId'],
                  ),
        ),
        'deactivateApplication': _i1.MethodConnector(
          name: 'deactivateApplication',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'applicationId': _i1.ParameterDescription(
              name: 'applicationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['application'] as _i4.ApplicationEndpoint)
                  .deactivateApplication(
                    session,
                    params['adminUserId'],
                    params['applicationId'],
                  ),
        ),
      },
    );
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).register(
                session,
                params['username'],
                params['password'],
                displayName: params['displayName'],
              ),
        ),
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'username': _i1.ParameterDescription(
              name: 'username',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).login(
                session,
                params['username'],
                params['password'],
              ),
        ),
        'logout': _i1.MethodConnector(
          name: 'logout',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i5.AuthEndpoint).logout(session),
        ),
        'changePassword': _i1.MethodConnector(
          name: 'changePassword',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'oldPassword': _i1.ParameterDescription(
              name: 'oldPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).changePassword(
                session,
                params['userId'],
                params['oldPassword'],
                params['newPassword'],
              ),
        ),
        'getUserById': _i1.MethodConnector(
          name: 'getUserById',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).getUserById(
                session,
                params['userId'],
              ),
        ),
        'validateToken': _i1.MethodConnector(
          name: 'validateToken',
          params: {
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['auth'] as _i5.AuthEndpoint).validateToken(
                session,
                params['token'],
              ),
        ),
      },
    );
    connectors['file'] = _i1.EndpointConnector(
      name: 'file',
      endpoint: endpoints['file']!,
      methodConnectors: {
        'uploadPdf': _i1.MethodConnector(
          name: 'uploadPdf',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentScoreId': _i1.ParameterDescription(
              name: 'instrumentScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'fileData': _i1.ParameterDescription(
              name: 'fileData',
              type: _i1.getType<_i17.ByteData>(),
              nullable: false,
            ),
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _i6.FileEndpoint).uploadPdf(
                session,
                params['userId'],
                params['instrumentScoreId'],
                params['fileData'],
                params['fileName'],
              ),
        ),
        'downloadPdf': _i1.MethodConnector(
          name: 'downloadPdf',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentScoreId': _i1.ParameterDescription(
              name: 'instrumentScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _i6.FileEndpoint).downloadPdf(
                session,
                params['userId'],
                params['instrumentScoreId'],
              ),
        ),
        'getFileUrl': _i1.MethodConnector(
          name: 'getFileUrl',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentScoreId': _i1.ParameterDescription(
              name: 'instrumentScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _i6.FileEndpoint).getFileUrl(
                session,
                params['userId'],
                params['instrumentScoreId'],
              ),
        ),
        'deletePdf': _i1.MethodConnector(
          name: 'deletePdf',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentScoreId': _i1.ParameterDescription(
              name: 'instrumentScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['file'] as _i6.FileEndpoint).deletePdf(
                session,
                params['userId'],
                params['instrumentScoreId'],
              ),
        ),
      },
    );
    connectors['librarySync'] = _i1.EndpointConnector(
      name: 'librarySync',
      endpoint: endpoints['librarySync']!,
      methodConnectors: {
        'pull': _i1.MethodConnector(
          name: 'pull',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['librarySync'] as _i7.LibrarySyncEndpoint).pull(
                    session,
                    params['userId'],
                    since: params['since'],
                  ),
        ),
        'push': _i1.MethodConnector(
          name: 'push',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i18.SyncPushRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['librarySync'] as _i7.LibrarySyncEndpoint).push(
                    session,
                    params['userId'],
                    params['request'],
                  ),
        ),
        'getLibraryVersion': _i1.MethodConnector(
          name: 'getLibraryVersion',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['librarySync'] as _i7.LibrarySyncEndpoint)
                  .getLibraryVersion(
                    session,
                    params['userId'],
                  ),
        ),
      },
    );
    connectors['profile'] = _i1.EndpointConnector(
      name: 'profile',
      endpoint: endpoints['profile']!,
      methodConnectors: {
        'getProfile': _i1.MethodConnector(
          name: 'getProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i8.ProfileEndpoint).getProfile(
                    session,
                    params['userId'],
                  ),
        ),
        'updateProfile': _i1.MethodConnector(
          name: 'updateProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'bio': _i1.ParameterDescription(
              name: 'bio',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'preferredInstrument': _i1.ParameterDescription(
              name: 'preferredInstrument',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i8.ProfileEndpoint).updateProfile(
                    session,
                    params['userId'],
                    displayName: params['displayName'],
                    bio: params['bio'],
                    preferredInstrument: params['preferredInstrument'],
                  ),
        ),
        'uploadAvatar': _i1.MethodConnector(
          name: 'uploadAvatar',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'imageData': _i1.ParameterDescription(
              name: 'imageData',
              type: _i1.getType<_i17.ByteData>(),
              nullable: false,
            ),
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i8.ProfileEndpoint).uploadAvatar(
                    session,
                    params['userId'],
                    params['imageData'],
                    params['fileName'],
                  ),
        ),
        'deleteAvatar': _i1.MethodConnector(
          name: 'deleteAvatar',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profile'] as _i8.ProfileEndpoint).deleteAvatar(
                    session,
                    params['userId'],
                  ),
        ),
        'getPublicProfile': _i1.MethodConnector(
          name: 'getPublicProfile',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'targetUserId': _i1.ParameterDescription(
              name: 'targetUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profile'] as _i8.ProfileEndpoint)
                  .getPublicProfile(
                    session,
                    params['userId'],
                    params['targetUserId'],
                  ),
        ),
        'deleteAllUserData': _i1.MethodConnector(
          name: 'deleteAllUserData',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profile'] as _i8.ProfileEndpoint)
                  .deleteAllUserData(
                    session,
                    params['userId'],
                  ),
        ),
      },
    );
    connectors['score'] = _i1.EndpointConnector(
      name: 'score',
      endpoint: endpoints['score']!,
      methodConnectors: {
        'getScores': _i1.MethodConnector(
          name: 'getScores',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint).getScores(
                session,
                params['userId'],
                since: params['since'],
              ),
        ),
        'getScoreById': _i1.MethodConnector(
          name: 'getScoreById',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint).getScoreById(
                session,
                params['userId'],
                params['scoreId'],
              ),
        ),
        'upsertScore': _i1.MethodConnector(
          name: 'upsertScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'score': _i1.ParameterDescription(
              name: 'score',
              type: _i1.getType<_i19.Score>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint).upsertScore(
                session,
                params['userId'],
                params['score'],
              ),
        ),
        'createScore': _i1.MethodConnector(
          name: 'createScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'composer': _i1.ParameterDescription(
              name: 'composer',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'bpm': _i1.ParameterDescription(
              name: 'bpm',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint).createScore(
                session,
                params['userId'],
                params['title'],
                composer: params['composer'],
                bpm: params['bpm'],
              ),
        ),
        'updateScore': _i1.MethodConnector(
          name: 'updateScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'composer': _i1.ParameterDescription(
              name: 'composer',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'bpm': _i1.ParameterDescription(
              name: 'bpm',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint).updateScore(
                session,
                params['userId'],
                params['scoreId'],
                title: params['title'],
                composer: params['composer'],
                bpm: params['bpm'],
              ),
        ),
        'deleteScore': _i1.MethodConnector(
          name: 'deleteScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint).deleteScore(
                session,
                params['userId'],
                params['scoreId'],
              ),
        ),
        'permanentlyDeleteScore': _i1.MethodConnector(
          name: 'permanentlyDeleteScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint)
                  .permanentlyDeleteScore(
                    session,
                    params['userId'],
                    params['scoreId'],
                  ),
        ),
        'getInstrumentScores': _i1.MethodConnector(
          name: 'getInstrumentScores',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['score'] as _i9.ScoreEndpoint).getInstrumentScores(
                    session,
                    params['userId'],
                    params['scoreId'],
                  ),
        ),
        'upsertInstrumentScore': _i1.MethodConnector(
          name: 'upsertInstrumentScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentName': _i1.ParameterDescription(
              name: 'instrumentName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'orderIndex': _i1.ParameterDescription(
              name: 'orderIndex',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'pdfPath': _i1.ParameterDescription(
              name: 'pdfPath',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint)
                  .upsertInstrumentScore(
                    session,
                    params['userId'],
                    params['scoreId'],
                    params['instrumentName'],
                    orderIndex: params['orderIndex'],
                    pdfPath: params['pdfPath'],
                  ),
        ),
        'createInstrumentScore': _i1.MethodConnector(
          name: 'createInstrumentScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentName': _i1.ParameterDescription(
              name: 'instrumentName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'orderIndex': _i1.ParameterDescription(
              name: 'orderIndex',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint)
                  .createInstrumentScore(
                    session,
                    params['userId'],
                    params['scoreId'],
                    params['instrumentName'],
                    orderIndex: params['orderIndex'],
                  ),
        ),
        'deleteInstrumentScore': _i1.MethodConnector(
          name: 'deleteInstrumentScore',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentScoreId': _i1.ParameterDescription(
              name: 'instrumentScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['score'] as _i9.ScoreEndpoint)
                  .deleteInstrumentScore(
                    session,
                    params['userId'],
                    params['instrumentScoreId'],
                  ),
        ),
        'getAnnotations': _i1.MethodConnector(
          name: 'getAnnotations',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentScoreId': _i1.ParameterDescription(
              name: 'instrumentScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['score'] as _i9.ScoreEndpoint).getAnnotations(
                    session,
                    params['userId'],
                    params['instrumentScoreId'],
                  ),
        ),
        'saveAnnotation': _i1.MethodConnector(
          name: 'saveAnnotation',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'annotation': _i1.ParameterDescription(
              name: 'annotation',
              type: _i1.getType<_i20.Annotation>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['score'] as _i9.ScoreEndpoint).saveAnnotation(
                    session,
                    params['userId'],
                    params['annotation'],
                  ),
        ),
        'deleteAnnotation': _i1.MethodConnector(
          name: 'deleteAnnotation',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'annotationId': _i1.ParameterDescription(
              name: 'annotationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['score'] as _i9.ScoreEndpoint).deleteAnnotation(
                    session,
                    params['userId'],
                    params['annotationId'],
                  ),
        ),
      },
    );
    connectors['setlist'] = _i1.EndpointConnector(
      name: 'setlist',
      endpoint: endpoints['setlist']!,
      methodConnectors: {
        'getSetlists': _i1.MethodConnector(
          name: 'getSetlists',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setlist'] as _i10.SetlistEndpoint).getSetlists(
                    session,
                    params['userId'],
                  ),
        ),
        'getSetlistById': _i1.MethodConnector(
          name: 'getSetlistById',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setlist'] as _i10.SetlistEndpoint).getSetlistById(
                    session,
                    params['userId'],
                    params['setlistId'],
                  ),
        ),
        'upsertSetlist': _i1.MethodConnector(
          name: 'upsertSetlist',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setlist'] as _i10.SetlistEndpoint).upsertSetlist(
                    session,
                    params['userId'],
                    params['name'],
                    description: params['description'],
                  ),
        ),
        'createSetlist': _i1.MethodConnector(
          name: 'createSetlist',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setlist'] as _i10.SetlistEndpoint).createSetlist(
                    session,
                    params['userId'],
                    params['name'],
                    description: params['description'],
                  ),
        ),
        'updateSetlist': _i1.MethodConnector(
          name: 'updateSetlist',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setlist'] as _i10.SetlistEndpoint).updateSetlist(
                    session,
                    params['userId'],
                    params['setlistId'],
                    name: params['name'],
                    description: params['description'],
                  ),
        ),
        'deleteSetlist': _i1.MethodConnector(
          name: 'deleteSetlist',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setlist'] as _i10.SetlistEndpoint).deleteSetlist(
                    session,
                    params['userId'],
                    params['setlistId'],
                  ),
        ),
        'getSetlistScores': _i1.MethodConnector(
          name: 'getSetlistScores',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setlist'] as _i10.SetlistEndpoint)
                  .getSetlistScores(
                    session,
                    params['userId'],
                    params['setlistId'],
                  ),
        ),
        'addScoreToSetlist': _i1.MethodConnector(
          name: 'addScoreToSetlist',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'orderIndex': _i1.ParameterDescription(
              name: 'orderIndex',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setlist'] as _i10.SetlistEndpoint)
                  .addScoreToSetlist(
                    session,
                    params['userId'],
                    params['setlistId'],
                    params['scoreId'],
                    orderIndex: params['orderIndex'],
                  ),
        ),
        'removeScoreFromSetlist': _i1.MethodConnector(
          name: 'removeScoreFromSetlist',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setlist'] as _i10.SetlistEndpoint)
                  .removeScoreFromSetlist(
                    session,
                    params['userId'],
                    params['setlistId'],
                    params['scoreId'],
                  ),
        ),
        'reorderSetlistScores': _i1.MethodConnector(
          name: 'reorderSetlistScores',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreIds': _i1.ParameterDescription(
              name: 'scoreIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setlist'] as _i10.SetlistEndpoint)
                  .reorderSetlistScores(
                    session,
                    params['userId'],
                    params['setlistId'],
                    params['scoreIds'],
                  ),
        ),
      },
    );
    connectors['status'] = _i1.EndpointConnector(
      name: 'status',
      endpoint: endpoints['status']!,
      methodConnectors: {
        'health': _i1.MethodConnector(
          name: 'health',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['status'] as _i11.StatusEndpoint).health(session),
        ),
        'info': _i1.MethodConnector(
          name: 'info',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['status'] as _i11.StatusEndpoint).info(session),
        ),
        'ping': _i1.MethodConnector(
          name: 'ping',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['status'] as _i11.StatusEndpoint).ping(session),
        ),
      },
    );
    connectors['sync'] = _i1.EndpointConnector(
      name: 'sync',
      endpoint: endpoints['sync']!,
      methodConnectors: {
        'syncAll': _i1.MethodConnector(
          name: 'syncAll',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'lastSyncAt': _i1.ParameterDescription(
              name: 'lastSyncAt',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i12.SyncEndpoint).syncAll(
                session,
                params['userId'],
                lastSyncAt: params['lastSyncAt'],
              ),
        ),
        'pushChanges': _i1.MethodConnector(
          name: 'pushChanges',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scores': _i1.ParameterDescription(
              name: 'scores',
              type: _i1.getType<List<_i19.Score>>(),
              nullable: false,
            ),
            'instrumentScores': _i1.ParameterDescription(
              name: 'instrumentScores',
              type: _i1.getType<List<_i21.InstrumentScore>>(),
              nullable: false,
            ),
            'annotations': _i1.ParameterDescription(
              name: 'annotations',
              type: _i1.getType<List<_i20.Annotation>>(),
              nullable: false,
            ),
            'setlists': _i1.ParameterDescription(
              name: 'setlists',
              type: _i1.getType<List<_i22.Setlist>>(),
              nullable: false,
            ),
            'setlistScores': _i1.ParameterDescription(
              name: 'setlistScores',
              type: _i1.getType<List<_i23.SetlistScore>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i12.SyncEndpoint).pushChanges(
                session,
                params['userId'],
                params['scores'],
                params['instrumentScores'],
                params['annotations'],
                params['setlists'],
                params['setlistScores'],
              ),
        ),
        'getSyncStatus': _i1.MethodConnector(
          name: 'getSyncStatus',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i12.SyncEndpoint).getSyncStatus(
                session,
                params['userId'],
              ),
        ),
      },
    );
    connectors['teamAnnotation'] = _i1.EndpointConnector(
      name: 'teamAnnotation',
      endpoint: endpoints['teamAnnotation']!,
      methodConnectors: {
        'getTeamAnnotations': _i1.MethodConnector(
          name: 'getTeamAnnotations',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamScoreId': _i1.ParameterDescription(
              name: 'teamScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['teamAnnotation'] as _i13.TeamAnnotationEndpoint)
                      .getTeamAnnotations(
                        session,
                        params['userId'],
                        params['teamScoreId'],
                      ),
        ),
        'addTeamAnnotation': _i1.MethodConnector(
          name: 'addTeamAnnotation',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamScoreId': _i1.ParameterDescription(
              name: 'teamScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'instrumentScoreId': _i1.ParameterDescription(
              name: 'instrumentScoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'pageNumber': _i1.ParameterDescription(
              name: 'pageNumber',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'type': _i1.ParameterDescription(
              name: 'type',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'positionX': _i1.ParameterDescription(
              name: 'positionX',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'positionY': _i1.ParameterDescription(
              name: 'positionY',
              type: _i1.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['teamAnnotation'] as _i13.TeamAnnotationEndpoint)
                      .addTeamAnnotation(
                        session,
                        params['userId'],
                        params['teamScoreId'],
                        params['instrumentScoreId'],
                        params['pageNumber'],
                        params['type'],
                        params['data'],
                        params['positionX'],
                        params['positionY'],
                      ),
        ),
        'updateTeamAnnotation': _i1.MethodConnector(
          name: 'updateTeamAnnotation',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'annotationId': _i1.ParameterDescription(
              name: 'annotationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'data': _i1.ParameterDescription(
              name: 'data',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'positionX': _i1.ParameterDescription(
              name: 'positionX',
              type: _i1.getType<double>(),
              nullable: false,
            ),
            'positionY': _i1.ParameterDescription(
              name: 'positionY',
              type: _i1.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['teamAnnotation'] as _i13.TeamAnnotationEndpoint)
                      .updateTeamAnnotation(
                        session,
                        params['userId'],
                        params['annotationId'],
                        params['data'],
                        params['positionX'],
                        params['positionY'],
                      ),
        ),
        'deleteTeamAnnotation': _i1.MethodConnector(
          name: 'deleteTeamAnnotation',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'annotationId': _i1.ParameterDescription(
              name: 'annotationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['teamAnnotation'] as _i13.TeamAnnotationEndpoint)
                      .deleteTeamAnnotation(
                        session,
                        params['userId'],
                        params['annotationId'],
                      ),
        ),
      },
    );
    connectors['team'] = _i1.EndpointConnector(
      name: 'team',
      endpoint: endpoints['team']!,
      methodConnectors: {
        'createTeam': _i1.MethodConnector(
          name: 'createTeam',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['team'] as _i14.TeamEndpoint).createTeam(
                session,
                params['adminUserId'],
                params['name'],
                params['description'],
              ),
        ),
        'getAllTeams': _i1.MethodConnector(
          name: 'getAllTeams',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['team'] as _i14.TeamEndpoint).getAllTeams(
                session,
                params['adminUserId'],
              ),
        ),
        'updateTeam': _i1.MethodConnector(
          name: 'updateTeam',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['team'] as _i14.TeamEndpoint).updateTeam(
                session,
                params['adminUserId'],
                params['teamId'],
                name: params['name'],
                description: params['description'],
              ),
        ),
        'deleteTeam': _i1.MethodConnector(
          name: 'deleteTeam',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['team'] as _i14.TeamEndpoint).deleteTeam(
                session,
                params['adminUserId'],
                params['teamId'],
              ),
        ),
        'addMemberToTeam': _i1.MethodConnector(
          name: 'addMemberToTeam',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['team'] as _i14.TeamEndpoint).addMemberToTeam(
                    session,
                    params['adminUserId'],
                    params['teamId'],
                    params['userId'],
                    params['role'],
                  ),
        ),
        'removeMemberFromTeam': _i1.MethodConnector(
          name: 'removeMemberFromTeam',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['team'] as _i14.TeamEndpoint).removeMemberFromTeam(
                    session,
                    params['adminUserId'],
                    params['teamId'],
                    params['userId'],
                  ),
        ),
        'updateMemberRole': _i1.MethodConnector(
          name: 'updateMemberRole',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['team'] as _i14.TeamEndpoint).updateMemberRole(
                    session,
                    params['adminUserId'],
                    params['teamId'],
                    params['userId'],
                    params['role'],
                  ),
        ),
        'getTeamMembers': _i1.MethodConnector(
          name: 'getTeamMembers',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['team'] as _i14.TeamEndpoint).getTeamMembers(
                    session,
                    params['adminUserId'],
                    params['teamId'],
                  ),
        ),
        'getUserTeams': _i1.MethodConnector(
          name: 'getUserTeams',
          params: {
            'adminUserId': _i1.ParameterDescription(
              name: 'adminUserId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['team'] as _i14.TeamEndpoint).getUserTeams(
                session,
                params['adminUserId'],
                params['userId'],
              ),
        ),
        'getMyTeams': _i1.MethodConnector(
          name: 'getMyTeams',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['team'] as _i14.TeamEndpoint).getMyTeams(
                session,
                params['userId'],
              ),
        ),
        'getTeamById': _i1.MethodConnector(
          name: 'getTeamById',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['team'] as _i14.TeamEndpoint).getTeamById(
                session,
                params['userId'],
                params['teamId'],
              ),
        ),
        'getMyTeamMembers': _i1.MethodConnector(
          name: 'getMyTeamMembers',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['team'] as _i14.TeamEndpoint).getMyTeamMembers(
                    session,
                    params['userId'],
                    params['teamId'],
                  ),
        ),
      },
    );
    connectors['teamScore'] = _i1.EndpointConnector(
      name: 'teamScore',
      endpoint: endpoints['teamScore']!,
      methodConnectors: {
        'getTeamScores': _i1.MethodConnector(
          name: 'getTeamScores',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['teamScore'] as _i15.TeamScoreEndpoint)
                  .getTeamScores(
                    session,
                    params['userId'],
                    params['teamId'],
                  ),
        ),
        'shareScoreToTeam': _i1.MethodConnector(
          name: 'shareScoreToTeam',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['teamScore'] as _i15.TeamScoreEndpoint)
                  .shareScoreToTeam(
                    session,
                    params['userId'],
                    params['teamId'],
                    params['scoreId'],
                  ),
        ),
        'unshareScoreFromTeam': _i1.MethodConnector(
          name: 'unshareScoreFromTeam',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scoreId': _i1.ParameterDescription(
              name: 'scoreId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['teamScore'] as _i15.TeamScoreEndpoint)
                  .unshareScoreFromTeam(
                    session,
                    params['userId'],
                    params['teamId'],
                    params['scoreId'],
                  ),
        ),
      },
    );
    connectors['teamSetlist'] = _i1.EndpointConnector(
      name: 'teamSetlist',
      endpoint: endpoints['teamSetlist']!,
      methodConnectors: {
        'getTeamSetlists': _i1.MethodConnector(
          name: 'getTeamSetlists',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['teamSetlist'] as _i16.TeamSetlistEndpoint)
                  .getTeamSetlists(
                    session,
                    params['userId'],
                    params['teamId'],
                  ),
        ),
        'shareSetlistToTeam': _i1.MethodConnector(
          name: 'shareSetlistToTeam',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['teamSetlist'] as _i16.TeamSetlistEndpoint)
                  .shareSetlistToTeam(
                    session,
                    params['userId'],
                    params['teamId'],
                    params['setlistId'],
                  ),
        ),
        'unshareSetlistFromTeam': _i1.MethodConnector(
          name: 'unshareSetlistFromTeam',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'teamId': _i1.ParameterDescription(
              name: 'teamId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'setlistId': _i1.ParameterDescription(
              name: 'setlistId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['teamSetlist'] as _i16.TeamSetlistEndpoint)
                  .unshareSetlistFromTeam(
                    session,
                    params['userId'],
                    params['teamId'],
                    params['setlistId'],
                  ),
        ),
      },
    );
  }
}
