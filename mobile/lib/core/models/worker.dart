class PayoutAccount {
  final String id;
  final String method;
  final String? telebirrPhone;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final bool isDefault;
  final DateTime createdAt;

  PayoutAccount({
    required this.id,
    required this.method,
    this.telebirrPhone,
    this.bankName,
    this.accountNumber,
    this.accountName,
    required this.isDefault,
    required this.createdAt,
  });

  factory PayoutAccount.fromJson(Map<String, dynamic> json) {
    return PayoutAccount(
      id: json['id'],
      method: json['method'],
      telebirrPhone: json['telebirr_phone'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      accountName: json['account_name'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get displayName {
    if (method == 'telebirr') {
      return 'Telebirr · $telebirrPhone';
    }
    return '$bankName · $accountNumber';
  }
}

class Worker {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? profession;
  final String? avatarUrl;
  final String? qrCodeUrl;
  final bool nfcEnabled;
  final bool isActive;
  final DateTime createdAt;
  final PayoutAccount? payoutAccount;

  Worker({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.profession,
    this.avatarUrl,
    this.qrCodeUrl,
    required this.nfcEnabled,
    required this.isActive,
    required this.createdAt,
    this.payoutAccount,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      profession: json['profession'],
      avatarUrl: json['avatar_url'],
      qrCodeUrl: json['qr_code_url'],
      nfcEnabled: json['nfc_enabled'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      payoutAccount: json['payout_account'] != null
          ? PayoutAccount.fromJson(json['payout_account'])
          : null,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
