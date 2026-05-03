import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_endpoints.dart';

class CompanyQuotaSnapshot {
  final String? companyId;
  final String? planName;
  final int? receiptsThisMonth;
  final int? maxReceiptsPerMonth;
  final String? subscriptionStatus;
  final DateTime fetchedAt;

  const CompanyQuotaSnapshot({
    required this.fetchedAt,
    this.companyId,
    this.planName,
    this.receiptsThisMonth,
    this.maxReceiptsPerMonth,
    this.subscriptionStatus,
  });

  bool get hasKnownLimit => maxReceiptsPerMonth != null && maxReceiptsPerMonth! >= 0;
  bool get isLimitReached => hasKnownLimit && receiptsThisMonth != null && receiptsThisMonth! >= maxReceiptsPerMonth!;

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'planName': planName,
      'receiptsThisMonth': receiptsThisMonth,
      'maxReceiptsPerMonth': maxReceiptsPerMonth,
      'subscriptionStatus': subscriptionStatus,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  factory CompanyQuotaSnapshot.fromMap(Map<String, dynamic> map) {
    return CompanyQuotaSnapshot(
      companyId: map['companyId']?.toString(),
      planName: map['planName']?.toString(),
      receiptsThisMonth: map['receiptsThisMonth'] == null ? null : int.tryParse(map['receiptsThisMonth'].toString()),
      maxReceiptsPerMonth: map['maxReceiptsPerMonth'] == null ? null : int.tryParse(map['maxReceiptsPerMonth'].toString()),
      subscriptionStatus: map['subscriptionStatus']?.toString(),
      fetchedAt: DateTime.tryParse(map['fetchedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class CompanyQuotaService {
  static const String _cacheKey = 'company_quota_cache';

  Future<CompanyQuotaSnapshot?> getCachedQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null || cached.isEmpty) {
      return null;
    }

    try {
      return CompanyQuotaSnapshot.fromMap(jsonDecode(cached) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheQuota(CompanyQuotaSnapshot quota) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(quota.toMap()));
  }

  Future<CompanyQuotaSnapshot?> refreshQuota({String? token}) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = token ?? prefs.getString('auth_token');
    if (authToken == null || authToken.isEmpty) {
      return await getCachedQuota();
    }

    try {
      final response = await http.get(
        Uri.parse(AppEndpoints.apiPath('/api/company/settings')),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return await getCachedQuota();
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final usage = payload['usage'] as Map<String, dynamic>?;
      final company = payload['company'] as Map<String, dynamic>?;
      final plan = payload['subscriptionPlan'] as Map<String, dynamic>?;

      final quota = CompanyQuotaSnapshot(
        companyId: company?['id']?.toString(),
        planName: plan?['name']?.toString(),
        receiptsThisMonth: usage?['receiptsThisMonth'] == null ? null : int.tryParse(usage!['receiptsThisMonth'].toString()),
        maxReceiptsPerMonth: usage?['maxReceipts'] == null ? null : int.tryParse(usage!['maxReceipts'].toString()),
        subscriptionStatus: company?['subscriptionStatus']?.toString(),
        fetchedAt: DateTime.now(),
      );

      await _cacheQuota(quota);
      return quota;
    } catch (_) {
      return await getCachedQuota();
    }
  }

  Future<CompanyQuotaSnapshot?> getCurrentQuota({String? token}) async {
    return await refreshQuota(token: token);
  }
}