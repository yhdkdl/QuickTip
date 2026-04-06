import 'package:dio/dio.dart';
import 'api_client.dart';

class WorkerApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get('/api/v1/workers/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> generateQr() async {
    final response = await _client.post('/api/v1/workers/generate-qr');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? profession,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (profession != null) data['profession'] = profession;
    if (email != null) data['email'] = email;

    final response = await _client.put(
      '/api/v1/workers/profile',
      data: data,
    );
    return response.data;
  }

  Future<List<dynamic>> getPayoutAccounts() async {
    final response = await _client.get(
      '/api/v1/workers/payout-accounts',
    );
    return response.data['accounts'];
  }

  Future<Map<String, dynamic>> addPayoutAccount(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      '/api/v1/workers/payout-accounts',
      data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> setDefaultPayoutAccount(
    String accountId,
  ) async {
    final response = await _client.put(
      '/api/v1/workers/payout-accounts/$accountId/default',
    );
    return response.data;
  }

  Future<void> deletePayoutAccount(String accountId) async {
    await _client.delete(
      '/api/v1/workers/payout-accounts/$accountId',
    );
  }
}
