import 'api_client.dart';

class DashboardApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getEarnings() async {
    final response = await _client.get(
      '/api/v1/dashboard/earnings',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getTipHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/v1/dashboard/tips?page=$page&page_size=$pageSize',
    );
    return response.data;
  }
}
