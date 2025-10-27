import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/warranty_item.dart';
import 'image_service.dart';
import 'social_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  final SocialService _socialService = SocialService();
  final String _collectionName = 'warranties';

  Future<void> initialize() async {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<String> createWarranty(WarrantyItem item) async {
    final docRef = await _firestore
        .collection(_collectionName)
        .add(item.toMap());
    return docRef.id;
  }

  Future<void> updateWarranty(WarrantyItem item) async {
    await _firestore
        .collection(_collectionName)
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteWarranty(String id) async {
    final warranty = await getWarrantyById(id);

    if (warranty != null) {
      if (warranty.productPhotoUrl != null) {
        await _imageService.deleteImage(warranty.productPhotoUrl!);
      }
      if (warranty.invoicePhotoUrl != null) {
        await _imageService.deleteImage(warranty.invoicePhotoUrl!);
      }
    }

    await _socialService.deleteSocialPost(id);

    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Stream<List<WarrantyItem>> getActiveWarranties(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WarrantyItem.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<WarrantyItem?> getWarrantyById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return WarrantyItem.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Stream<List<WarrantyItem>> searchWarranties(String userId, String query) {
    final lowerQuery = query.toLowerCase();

    return getActiveWarranties(userId).map((warranties) {
      return warranties.where((warranty) {
        return warranty.productName.toLowerCase().contains(lowerQuery) ||
            warranty.supplier.toLowerCase().contains(lowerQuery) ||
            warranty.invoiceNumber.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  Stream<List<WarrantyItem>> getWarrantiesSortedByExpiry(String userId) {
    return getActiveWarranties(userId).map((warranties) {
      final active = warranties.where((w) => !w.isExpired).toList();
      final expired = warranties.where((w) => w.isExpired).toList();

      active.sort((a, b) => a.remainingDays.compareTo(b.remainingDays));

      expired.sort((a, b) => b.remainingDays.compareTo(a.remainingDays));

      return [...active, ...expired];
    });
  }

  Stream<List<WarrantyItem>> getExpiringSoonWarranties(String userId) {
    return getActiveWarranties(userId).map((warranties) {
      return warranties.where((w) => w.isExpiringSoon).toList()
        ..sort((a, b) => a.remainingDays.compareTo(b.remainingDays));
    });
  }

  Future<int> getActiveWarrantyCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting warranty count: $e');
      return 0;
    }
  }

  Future<bool> canCreateWarranty(String userId, bool isPremium) async {
    if (isPremium) return true;

    final count = await getActiveWarrantyCount(userId);
    return count < 3;
  }

  Future<void> deleteAllUserWarranties(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await deleteWarranty(doc.id);
      }
    } catch (e) {
      debugPrint('Error deleting all user warranties: $e');
    }
  }
}
