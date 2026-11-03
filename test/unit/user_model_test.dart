import 'package:flutter_test/flutter_test.dart';
import 'package:local_cat/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    final validJson = {
      'id': 1,
      'name': 'Leanne Graham',
      'username': 'Bret',
      'email': 'Sincere@april.biz',
      'phone': '1-770-736-8031 x56442',
      'website': 'hildegard.org',
      'company': {
        'name': 'Romaguera-Crona',
        'catchPhrase': 'Multi-layered client-server neural-net',
        'bs': 'harness real-time e-markets',
      },
    };

    test('parses full JSON safely', () {
      final user = UserModel.fromJson(validJson);

      expect(user.id, 1);
      expect(user.name, 'Leanne Graham');
      expect(user.username, 'Bret');
      expect(user.email, 'Sincere@april.biz');
      expect(user.phone, '1-770-736-8031 x56442');
      expect(user.website, 'hildegard.org');
      expect(user.companyName, 'Romaguera-Crona');
      expect(
        user.company.catchPhrase,
        'Multi-layered client-server neural-net',
      );
    });

    test('handles missing or malformed fields safely without crashing', () {
      final partialJson = <String, dynamic>{
        'id': '2', // String id
        'name': 'Ervin Howell',
        'company': 'Independent Contractor', // String company instead of Map
      };

      final user = UserModel.fromJson(partialJson);

      expect(user.id, 2);
      expect(user.name, 'Ervin Howell');
      expect(user.username, '');
      expect(user.email, '');
      expect(user.website, '');
      expect(user.companyName, 'Independent Contractor');
    });

    test('serializes to JSON correctly', () {
      final user = UserModel.fromJson(validJson);
      final jsonOutput = user.toJson();

      expect(jsonOutput['id'], 1);
      expect(jsonOutput['name'], 'Leanne Graham');
      expect(jsonOutput['company']['name'], 'Romaguera-Crona');
    });

    test('equality and hashCode work as expected', () {
      final user1 = UserModel.fromJson(validJson);
      final user2 = UserModel.fromJson(validJson);

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });
  });
}
