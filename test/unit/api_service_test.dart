import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:local_cat/core/errors/app_exception.dart';
import 'package:local_cat/data/services/api_service.dart';

void main() {
  group('ApiService', () {
    test('getUsers successfully parses user list on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''
          [
            {
              "id": 1,
              "name": "Leanne Graham",
              "username": "Bret",
              "email": "Sincere@april.biz",
              "phone": "1-770-736-8031 x56442",
              "website": "hildegard.org",
              "company": {
                "name": "Romaguera-Crona"
              }
            }
          ]
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiService(client: mockClient);
      final users = await service.getUsers();

      expect(users.length, 1);
      expect(users.first.id, 1);
      expect(users.first.name, 'Leanne Graham');
    });

    test('getUserById parses single user successfully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''
          {
            "id": 2,
            "name": "Ervin Howell",
            "username": "Antonette",
            "email": "Shanna@melissa.tv",
            "phone": "010-692-6593 x09125",
            "website": "anastasia.net",
            "company": {
              "name": "Deckow-Crist"
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ApiService(client: mockClient);
      final user = await service.getUserById(2);

      expect(user.id, 2);
      expect(user.name, 'Ervin Howell');
      expect(user.username, 'Antonette');
    });

    test('throws ServerException on 404 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = ApiService(client: mockClient);

      expect(
        () => service.getUserById(99),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('throws ServerException on 500 server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ApiService(client: mockClient);

      expect(
        () => service.getUsers(),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws NetworkException on SocketException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('No Internet');
      });

      final service = ApiService(client: mockClient);

      expect(() => service.getUsers(), throwsA(isA<NetworkException>()));
    });

    test('throws DataParsingException on invalid JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not a JSON string', 200);
      });

      final service = ApiService(client: mockClient);

      expect(() => service.getUsers(), throwsA(isA<DataParsingException>()));
    });
  });
}
