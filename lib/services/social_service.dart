import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:garanticim/models/warranty_item.dart';

class SocialService {
  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;
  SocialService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'warranties';

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

          list.sort((a, b) {
            final aDate = a.sharedAt;
            final bDate = b.sharedAt;
            return bDate.compareTo(aDate);
          });

          return list;
        });
  }

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

          list.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));

          return list;
        });
  }

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

  Future<void> deleteSocialPost(String warrantyId) async {
    await _firestore.collection(_collectionName).doc(warrantyId).update({
      'isSharedSocial': false,
    });
  }

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
      debugPrint("✅ Updated successfully!");
    } catch (e) {
      debugPrint("🔥 Update failed: $e");
    }
  }

  Future<void> approvePost(String warrantyId, String adminId) async {
    try {
      await _firestore.collection(_collectionName).doc(warrantyId).update({
        'moderationStatus': 'approved',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': adminId,
      });
    } catch (e) {
      debugPrint('Error approving post: $e');
      rethrow;
    }
  }

  Future<void> rejectPost(String warrantyId, String adminId) async {
    try {
      await _firestore.collection(_collectionName).doc(warrantyId).update({
        'moderationStatus': 'rejected',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': adminId,
        'isSharedSocial': false,
      });
    } catch (e) {
      debugPrint('Error rejecting post: $e');
      rethrow;
    }
  }
}
