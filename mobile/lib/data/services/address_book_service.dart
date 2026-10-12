import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseException, FirebaseFirestore, SetOptions;

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
import '../models/address.dart';

/// Saved delivery addresses, stored on the user's own document
/// (`users/{uid}.savedAddresses`), which only that user may read and write.
class AddressBookService {
  AddressBookService({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static const String _field = 'savedAddresses';

  Future<List<Address>> load(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .get();
      final saved = doc.data()?[_field] as List<dynamic>? ?? const [];
      return saved
          .map((json) => Address.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    } on FirebaseException catch (error) {
      throw mapFirebaseException(error);
    }
  }

  /// Replaces the saved list. Merging leaves the backend's fields (such as
  /// push tokens) on the same document untouched.
  Future<void> save(String uid, List<Address> addresses) async {
    try {
      await _firestore.collection(FirestorePaths.users).doc(uid).set({
        _field: [for (final address in addresses) address.toJson()],
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
