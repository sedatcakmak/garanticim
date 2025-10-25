import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Initialize Firebase with offline persistence
  Future<void> initialize() async {
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Create a new warranty item
  Future<String> createWarranty(WarrantyItem item) async {
    final docRef = await _firestore
        .collection(_collectionName)
        .add(item.toMap());
    return docRef.id;
  }

  /// Update an existing warranty item
  Future<void> updateWarranty(WarrantyItem item) async {
    await _firestore
        .collection(_collectionName)
        .doc(item.id)
        .update(item.toMap());
  }

  /// Delete a warranty item (permanently delete from Firestore and Storage)
  Future<void> deleteWarranty(String id) async {
    // First, get the warranty to retrieve image URLs
    final warranty = await getWarrantyById(id);

    if (warranty != null) {
      // Delete images from Storage if they exist
      if (warranty.productPhotoUrl != null) {
        await _imageService.deleteImage(warranty.productPhotoUrl!);
      }
      if (warranty.invoicePhotoUrl != null) {
        await _imageService.deleteImage(warranty.invoicePhotoUrl!);
      }
    }

    await _socialService.deleteSocialPost(id);

    // Delete the warranty document from Firestore
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  /// Get all warranties for a user
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

  /// Get a single warranty item by ID
  Future<WarrantyItem?> getWarrantyById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return WarrantyItem.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Search warranties by product name or supplier
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

  /// Get warranties sorted by expiry date (expiring soon first)
  Stream<List<WarrantyItem>> getWarrantiesSortedByExpiry(String userId) {
    return getActiveWarranties(userId).map((warranties) {
      // Separate active and expired warranties
      final active = warranties.where((w) => !w.isExpired).toList();
      final expired = warranties.where((w) => w.isExpired).toList();

      // Sort active by remaining days (ascending)
      active.sort((a, b) => a.remainingDays.compareTo(b.remainingDays));

      // Sort expired by remaining days (descending, most recently expired first)
      expired.sort((a, b) => b.remainingDays.compareTo(a.remainingDays));

      return [...active, ...expired];
    });
  }

  /// Get warranties expiring soon (within 30 days)
  Stream<List<WarrantyItem>> getExpiringSoonWarranties(String userId) {
    return getActiveWarranties(userId).map((warranties) {
      return warranties.where((w) => w.isExpiringSoon).toList()
        ..sort((a, b) => a.remainingDays.compareTo(b.remainingDays));
    });
  }

  /// Get count of active warranties for a user
  Future<int> getActiveWarrantyCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting warranty count: $e');
      return 0;
    }
  }

  /// Check if user can create a new warranty (for non-premium users)
  /// Premium users have unlimited warranties, free users limited to 3 active warranties
  Future<bool> canCreateWarranty(String userId, bool isPremium) async {
    if (isPremium) return true;

    final count = await getActiveWarrantyCount(userId);
    return count < 3; // Free users can have maximum 3 active warranties
  }

  /// Delete all warranties for a user (used when deleting account)
  Future<void> deleteAllUserWarranties(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      // Delete each warranty with its images
      for (final doc in snapshot.docs) {
        await deleteWarranty(doc.id);
      }
    } catch (e) {
      print('Error deleting all user warranties: $e');
    }
  }
}
