import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/user_model.dart';

class ApiService {
  ApiService({http.Client? client, this.baseUrl = ApiConstants.baseUrl})
    : _client = client ?? http.Client(),
      _isClientOwned = client == null;

  final http.Client _client;
  final bool _isClientOwned;
  final String baseUrl;

  /// Fetches the full list of users from the API.
  Future<List<UserModel>> getUsers() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.usersEndpoint}');
    final responseBody = await _executeRequest(uri);

    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! List) {
        throw const DataParsingException('Expected JSON array of users.');
      }

      return decoded
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      throw DataParsingException('Invalid JSON received from server.', e);
    }
  }

  /// Fetches a single user by ID from the API.
  Future<UserModel> getUserById(int id) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.usersEndpoint}/$id');
    final responseBody = await _executeRequest(uri);

    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const DataParsingException('Expected JSON object for user.');
      }

      return UserModel.fromJson(decoded);
    } on FormatException catch (e) {
      throw DataParsingException('Invalid JSON received from server.', e);
    }
  }

  /// Executes an HTTP GET request with timeout and comprehensive error mapping.
  Future<String> _executeRequest(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw ServerException(
          statusCode: 404,
          message: 'The requested resource was not found.',
        );
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Server error with status code ${response.statusCode}.',
        );
      }
    } on SocketException catch (e) {
      throw NetworkException(
        'Unable to connect to the server. Please check your internet connection.',
        e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException('Network communication error occurred.', e);
    } on TimeoutException catch (e) {
      throw TimeoutAppException(
        'Connection timed out while contacting server.',
        e,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('An unexpected network error occurred.', e);
    }
  }

  /// Closes the HTTP client if this service instance created and owns it.
  void dispose() {
    if (_isClientOwned) {
      _client.close();
    }
  }
}
