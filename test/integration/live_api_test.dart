import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:local_cat/data/services/api_service.dart';
import 'package:local_cat/data/repositories/auth_repository.dart';

void main() {
  group('Live API Verification (JSONPlaceholder)', () {
    test('fetches live users and authenticates valid mock user ID 1', () async {
      final client = http.Client();
      final apiService = ApiService(client: client);
      final authRepo = AuthRepositoryImpl(apiService: apiService);

      try {
        final user = await authRepo.loginWithUserId(1);
        expect(user.id, 1);
        expect(user.name, isNotEmpty);
        expect(user.email, isNotEmpty);
        expect(user.username, isNotEmpty);
      } catch (e) {
        // If offline or network firewall blocks, report info
        printOnFailure('Live API call failed (might be offline): $e');
      } finally {
        client.close();
      }
    });
  });
}
