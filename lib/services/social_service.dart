import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:garanticim/models/warranty_item.dart';

class SocialService {
  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;
  SocialService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'warranties';

  /// Sosyal akışta gösterilecek paylaşımlar (sadece onaylanmış)
  Stream<List<WarrantyItem>> getAllPosts() {
    return _firestore
        .collection(_collectionName)
        .where('isSharedSocial', isEqualTo: true)
        .where('moderationStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => WarrantyItem.fromMap(doc.id, doc.data()))
              .toList();

          // client tarafında sıralama (en yeni en üstte)
          list.sort((a, b) {
            final aDate = a.sharedAt;
            final bDate = b.sharedAt;
            return bDate.compareTo(aDate);
          });

          return list;
        });
  }

  /// Beklemedeki paylaşımları getir (sadece yöneticiler için)
  Stream<List<WarrantyItem>> getPendingPosts() {
    return _firestore
        .collection(_collectionName)
        .where('isSharedSocial', isEqualTo: true)
        .where('moderationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => WarrantyItem.fromMap(doc.id, doc.data()))
              .toList();

          // En yeni paylaşımlar en üstte
          list.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));

          return list;
        });
  }

  /// Kullanıcının kendi beklemedeki postlarını getir
  Stream<List<WarrantyItem>> getUserPendingPosts(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('isSharedSocial', isEqualTo: true)
        .where('moderationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WarrantyItem.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Sosyal paylaşımı kaldır (isSharedSocial = false yap)
  Future<void> deleteSocialPost(String warrantyId) async {
    await _firestore.collection(_collectionName).doc(warrantyId).update({
      'isSharedSocial': false,
    });
  }

  /// Sosyal paylaşımı güncelle veya ekle (moderasyon için pending olarak başlar)
  Future<void> updateSocialPost(String warrantyId, bool isLiked) async {
    try {
      await _firestore.collection(_collectionName).doc(warrantyId).update({
        'isSharedSocial': true,
        'isLiked': isLiked,
        'sharedAt': FieldValue.serverTimestamp(),
        'moderationStatus': 'pending',
        'moderatedAt': null,
        'moderatedBy': null,
      });
      print("✅ Updated successfully!");
    } catch (e) {
      print("🔥 Update failed: $e");
    }
  }

  /// Paylaşımı onayla (yönetici işlemi)
  Future<void> approvePost(String warrantyId, String adminId) async {
    try {
      await _firestore.collection(_collectionName).doc(warrantyId).update({
        'moderationStatus': 'approved',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': adminId,
      });
    } catch (e) {
      print('Error approving post: $e');
      rethrow;
    }
  }

  /// Paylaşımı reddet ve sil (yönetici işlemi)
  Future<void> rejectPost(String warrantyId, String adminId) async {
    try {
      // Önce moderasyon bilgilerini güncelle
      await _firestore.collection(_collectionName).doc(warrantyId).update({
        'moderationStatus': 'rejected',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': adminId,
        'isSharedSocial': false,
      });
    } catch (e) {
      print('Error rejecting post: $e');
      rethrow;
    }
  }
}
