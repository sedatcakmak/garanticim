import 'package:cloud_firestore/cloud_firestore.dart';

class WarrantyItem {
  final String id;
  final String userId;
  final String productName;
  final DateTime purchaseDate;
  final String invoiceNumber;
  final String? invoicePhotoUrl;
  final int warrantyMonths;
  final String supplier;
  final String? productPhotoUrl;
  final double totalCost;
  final String categoryName;
  final String brandName;
  final DateTime createdAt;
  final bool isSharedSocial;
  final DateTime sharedAt;
  final bool isLiked;
  final String moderationStatus; // 'approved', 'pending', 'rejected'
  final DateTime? moderatedAt;
  final String? moderatedBy;

  WarrantyItem({
    required this.id,
    required this.userId,
    required this.productName,
    required this.purchaseDate,
    required this.invoiceNumber,
    this.invoicePhotoUrl,
    required this.warrantyMonths,
    required this.isLiked,
    required this.supplier,
    this.productPhotoUrl,
    required this.totalCost,
    required this.categoryName,
    required this.brandName,
    required this.createdAt,
    required this.sharedAt,
    this.isSharedSocial = false,
    this.moderationStatus = 'pending',
    this.moderatedAt,
    this.moderatedBy,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productName': productName,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'invoiceNumber': invoiceNumber,
      'invoicePhotoUrl': invoicePhotoUrl,
      'warrantyMonths': warrantyMonths,
      'supplier': supplier,
      'productPhotoUrl': productPhotoUrl,
      'totalCost': totalCost,
      'categoryName': categoryName,
      'brandName': brandName,
      'createdAt': Timestamp.fromDate(createdAt),
      'sharedAt': Timestamp.fromDate(sharedAt),
      'isLiked': isLiked,
      'isSharedSocial': isSharedSocial,
      'moderationStatus': moderationStatus,
      'moderatedAt': moderatedAt != null
          ? Timestamp.fromDate(moderatedAt!)
          : null,
      'moderatedBy': moderatedBy,
    };
  }

  factory WarrantyItem.fromMap(String id, Map<String, dynamic> map) {
    return WarrantyItem(
      id: id,
      userId: map['userId'] ?? '',
      productName: map['productName'] ?? '',
      purchaseDate: (map['purchaseDate'] is Timestamp)
          ? (map['purchaseDate'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      invoiceNumber: map['invoiceNumber'] ?? '',
      invoicePhotoUrl: map['invoicePhotoUrl'],
      warrantyMonths: map['warrantyMonths'] ?? 0,
      supplier: map['supplier'] ?? '',
      productPhotoUrl: map['productPhotoUrl'],
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      categoryName: map['categoryName'] ?? '',
      brandName: map['brandName'] ?? '',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      sharedAt: (map['sharedAt'] is Timestamp)
          ? (map['sharedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isLiked: map['isLiked'] ?? false,
      isSharedSocial: map['isSharedSocial'] ?? false,
      moderationStatus: map['moderationStatus'] ?? 'pending',
      moderatedAt: map['moderatedAt'] != null
          ? (map['moderatedAt'] as Timestamp).toDate()
          : null,
      moderatedBy: map['moderatedBy'],
    );
  }

  /// Create a copy with updated fields
  WarrantyItem copyWith({
    String? id,
    String? userId,
    String? productName,
    DateTime? purchaseDate,
    String? invoiceNumber,
    String? invoicePhotoUrl,
    int? warrantyMonths,
    String? supplier,
    String? productPhotoUrl,
    double? totalCost,
    String? categoryId,
    String? categoryName,
    bool? isLiked,
    String? brandId,
    String? brandName,
    DateTime? createdAt,
    DateTime? sharedAt,
    bool? isSharedSocial,
    String? moderationStatus,
    DateTime? moderatedAt,
    String? moderatedBy,
  }) {
    return WarrantyItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoicePhotoUrl: invoicePhotoUrl ?? this.invoicePhotoUrl,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      supplier: supplier ?? this.supplier,
      productPhotoUrl: productPhotoUrl ?? this.productPhotoUrl,
      totalCost: totalCost ?? this.totalCost,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      sharedAt: sharedAt ?? this.sharedAt,
      isSharedSocial: isSharedSocial ?? this.isSharedSocial,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderatedBy: moderatedBy ?? this.moderatedBy,
    );
  }

  /// Get warranty expiry date
  DateTime get expiryDate {
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + warrantyMonths,
      purchaseDate.day,
    );
  }

  /// Get remaining days until expiry
  int get remainingDays {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  /// Check if warranty is expired
  bool get isExpired => remainingDays < 0;

  /// Check if warranty is expiring soon (within 30 days)
  bool get isExpiringSoon => remainingDays >= 0 && remainingDays <= 30;
}
