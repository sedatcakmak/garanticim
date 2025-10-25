import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String phone;
  final DateTime createdAt;
  final bool isAdmin;
  final bool isPremium;
  final DateTime? premiumExpiryDate;
  final String? subscriptionId;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.isAdmin = false,
    this.isPremium = false,
    this.premiumExpiryDate,
    this.subscriptionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
      'isPremium': isPremium,
      'premiumExpiryDate': premiumExpiryDate != null
          ? Timestamp.fromDate(premiumExpiryDate!)
          : null,
      'subscriptionId': subscriptionId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] ?? false,
      isPremium: map['isPremium'] ?? false,
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? (map['premiumExpiryDate'] as Timestamp).toDate()
          : null,
      subscriptionId: map['subscriptionId'],
    );
  }

  /// Check if premium subscription is still active
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return false;
    return premiumExpiryDate!.isAfter(DateTime.now());
  }

  /// Copy with updated fields
  UserModel copyWith({
    String? userId,
    String? name,
    String? phone,
    DateTime? createdAt,
    bool? isAdmin,
    bool? isPremium,
    DateTime? premiumExpiryDate,
    String? subscriptionId,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }
}
