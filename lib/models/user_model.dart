import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String deviceId;
  final DateTime createdAt;
  final bool isAdmin;
  final bool isPremium;
  final DateTime? premiumExpiryDate;
  final String? subscriptionId;
  final bool isRegistered;
  final String? phoneNumber;
  final String? name;
  final String? city;

  UserModel({
    required this.userId,
    required this.deviceId,
    required this.createdAt,
    this.isAdmin = false,
    this.isPremium = false,
    this.premiumExpiryDate,
    this.subscriptionId,
    this.isRegistered = false,
    this.phoneNumber,
    this.name,
    this.city,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
      'isPremium': isPremium,
      'premiumExpiryDate': premiumExpiryDate != null
          ? Timestamp.fromDate(premiumExpiryDate!)
          : null,
      'subscriptionId': subscriptionId,
      'isRegistered': isRegistered,
      'phoneNumber': phoneNumber,
      'name': name,
      'city': city,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] ?? false,
      isPremium: map['isPremium'] ?? false,
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? (map['premiumExpiryDate'] as Timestamp).toDate()
          : null,
      subscriptionId: map['subscriptionId'],
      isRegistered: map['isRegistered'] ?? false,
      phoneNumber: map['phoneNumber'],
      name: map['name'],
      city: map['city'],
    );
  }

  bool get isPremiumActive {
    if (!isPremium) return false;

    if (premiumExpiryDate == null) return false;

    return premiumExpiryDate!.isAfter(DateTime.now());
  }

  UserModel copyWith({
    String? userId,
    String? deviceId,
    DateTime? createdAt,
    bool? isAdmin,
    bool? isPremium,
    DateTime? premiumExpiryDate,
    String? subscriptionId,
    bool? isRegistered,
    String? phoneNumber,
    String? name,
    String? city,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      isRegistered: isRegistered ?? this.isRegistered,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      city: city ?? this.city,
    );
  }
}
