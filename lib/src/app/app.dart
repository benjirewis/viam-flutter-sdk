import 'dart:async';

import 'package:viam_sdk/src/gen/google/protobuf/struct.pb.dart';

import '../gen/app/v1/app.pbgrpc.dart';
import 'permissions.dart';

typedef RobotPartLogPage = GetRobotPartLogsResponse;

/// gRPC client for connecting to Viam's App Service
///
/// All calls must be authenticated.
class AppClient {
  final AppServiceClient _client;

  AppClient(this._client);

  /// List all the [Organization] the currently authenticated user has access to
  Future<List<Organization>> listOrganizations() async {
    final listOrganizationsRequest = ListOrganizationsRequest();
    final ListOrganizationsResponse response = await _client.listOrganizations(listOrganizationsRequest);
    return response.organizations;
  }

  /// Get a specific [Organization] by ID
  Future<Organization> getOrganization(String organizationId) async {
    final getOrganizationRequest = GetOrganizationRequest()..organizationId = organizationId;
    final GetOrganizationResponse response = await _client.getOrganization(getOrganizationRequest);
    return response.organization;
  }

  /// List the [Location] of a specific [Organization] that the currently authenticated user has access to
  Future<List<Location>> listLocations(Organization organization) async {
    final listLocationsRequest = ListLocationsRequest()..organizationId = organization.id;
    final ListLocationsResponse response = await _client.listLocations(listLocationsRequest);
    return response.locations;
  }

  /// Get a specific [Location] by ID
  Future<Location> getLocation(String locationId) async {
    final getLocationRequest = GetLocationRequest()..locationId = locationId;
    final GetLocationResponse response = await _client.getLocation(getLocationRequest);
    return response.location;
  }

  /// List the [Robot] of a specific [Location] that the currently authenticated user has access to
  Future<List<Robot>> listRobots(Location location) async {
    final listRobotsRequest = ListRobotsRequest()..locationId = location.id;
    final ListRobotsResponse response = await _client.listRobots(listRobotsRequest);
    return response.robots;
  }

  /// Get a specific [Robot] by ID
  Future<Robot> getRobot(String robotId) async {
    final getRobotRequest = GetRobotRequest()..id = robotId;
    final GetRobotResponse response = await _client.getRobot(getRobotRequest);
    return response.robot;
  }

  /// List the [RobotPart] of a specific [Robot] that the currently authenticated user has access to
  Future<List<RobotPart>> listRobotParts(Robot robot) async {
    final getRobotPartsRequest = GetRobotPartsRequest()..robotId = robot.id;
    final response = await _client.getRobotParts(getRobotPartsRequest);
    return response.parts;
  }

  /// Get a specific [RobotPart] by ID
  Future<RobotPart> getRobotPart(String partId) async {
    final getRobotPartRequest = GetRobotPartRequest()..id = partId;
    final response = await _client.getRobotPart(getRobotPartRequest);
    return response.part;
  }

  /// Update a specific [RobotPart] by ID
  Future<RobotPart> updateRobotPart(String partId, String name, Struct robotConfig) async {
    final updateRobotPartRequest = UpdateRobotPartRequest()
      ..id = partId
      ..name = name
      ..robotConfig = robotConfig;
    final response = await _client.updateRobotPart(updateRobotPartRequest);
    return response.part;
  }

  /// Get a page of [LogEntry] for a specific [RobotPart]. Logs are sorted by descending time (newest first)
  Future<RobotPartLogPage> getLogs(RobotPart part, {bool errorsOnly = false, String pageToken = ''}) async {
    final request = GetRobotPartLogsRequest()
      ..id = part.id
      ..errorsOnly = errorsOnly
      ..pageToken = pageToken;
    return await _client.getRobotPartLogs(request);
  }

  /// Get a stream of [LogEntry] for a specific [RobotPart]. Logs are sorted by descending time (newest first)
  Stream<List<LogEntry>> tailLogs(RobotPart part, {bool errorsOnly = false}) {
    final request = TailRobotPartLogsRequest()
      ..id = part.id
      ..errorsOnly = errorsOnly;
    final response = _client.tailRobotPartLogs(request);
    final stream = response.map((event) => event.logs);
    return stream.asBroadcastStream(onCancel: (_) => response.cancel());
  }

  /// List the [Authorization]s available for the currently authenticated user
  Future<List<Authorization>> listAuthorizations(String organizationId, {List<String> resourceIds = const []}) async {
    final request = ListAuthorizationsRequest()
      ..organizationId = organizationId
      ..resourceIds.addAll(resourceIds);
    final response = await _client.listAuthorizations(request);
    return response.authorizations;
  }

  Future<List<Permission>> checkPermissions(ResourceType resourceType, String resourceId, List<Permission> permissions) async {
    final request = CheckPermissionsRequest()
      ..permissions.add((AuthorizedPermissions()
        ..resourceType = resourceType.name
        ..resourceId = resourceId
        ..permissions.addAll(permissions.map((e) => e.value))));
    final response = await _client.checkPermissions(request);
    if (response.authorizedPermissions.isEmpty) return [];
    return response.authorizedPermissions.first.permissions
        .map((e) => Permission.values.firstWhere((element) => element.value == e))
        .toList();
  }

  /// List the members and pending invites for an [Organization].
  Future<ListOrganizationMembersResponse> listOrganizationMembers(Organization org) async {
    final request = ListOrganizationMembersRequest()..organizationId = org.id;
    final response = await _client.listOrganizationMembers(request);
    return response;
  }

  /// Send an invitation to to join an [Organization] to the specified email. Grant the level of permission defined in the [ViamAuthorization] object attached.
  Future<OrganizationInvite> createOrganizationInvite(Organization org, String email, List<ViamAuthorization> authorizations) async {
    final List<Authorization> protoAuthorizations = [];
    for (final authorization in authorizations) {
      protoAuthorizations.add(authorization.toProto);
    }

    final request = CreateOrganizationInviteRequest(authorizations: protoAuthorizations)
      ..organizationId = org.id
      ..email = email;
    final response = await _client.createOrganizationInvite(request);
    return response.invite;
  }

  Future<OrganizationInvite> resendOrganizationInvite(Organization org, String email) async {
    final request = ResendOrganizationInviteRequest()
      ..organizationId = org.id
      ..email = email;
    final response = await _client.resendOrganizationInvite(request);
    return response.invite;
  }

  Future<void> deleteOrganizationInvite(Organization org, String email) async {
    final request = DeleteOrganizationInviteRequest()
      ..organizationId = org.id
      ..email = email;
    await _client.deleteOrganizationInvite(request);
  }

  Future<void> deleteOrganizationMember(Organization org, String userId) async {
    final request = DeleteOrganizationMemberRequest()
      ..organizationId = org.id
      ..userId = userId;
    await _client.deleteOrganizationMember(request);
  }

  /// Create a new smart machine with the included [name] in the passed in [locationId]
  Future<String> newMachine(String name, String locationId) async {
    final request = NewRobotRequest()
      ..name = name
      ..location = locationId;
    final response = await _client.newRobot(request);
    return response.id;
  }

  /// Get a specific [Fragment] by id.
  Future<Fragment> getFragment(String id) async {
    final request = GetFragmentRequest()..id = id;
    final response = await _client.getFragment(request);
    return response.fragment;
  }
}
