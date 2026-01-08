import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUserById(String uid);
  Future<void> updateUser(UserModel user);
}

class UserRepositoryImpl implements UserRepository {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  @override
  Future<void> createUser(UserModel user) async {
    await usersCollection.doc(user.uid).set(user.toJson());
  }

  @override
  Future<UserModel?> getUserById(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await usersCollection.doc(user.uid).update(user.toJson());
  }
}
