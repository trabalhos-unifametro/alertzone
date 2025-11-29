import 'dart:io' show Platform, File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({
          'login_hint': 'user@example.com',
        });
        UserCredential userCredential = await _auth.signInWithPopup(googleProvider);

        if (userCredential.user != null) {
          await createOrUpdateUserProfile(userCredential.user!);
        }

        return userCredential.user;
      } else {
        final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
        if (gUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await gUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await createOrUpdateUserProfile(userCredential.user!);
        }

        return userCredential.user;
      }
    } catch (e) {
      print('Erro Google Login: $e');
      return null;
    }
  }

  Future<User?> signInWithApple() async {
    try {
      // TODO: Para mobile (iOS) pode precisar de nonce etc..
      // final appleCredential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [
      //     AppleIDAuthorizationScopes.email,
      //     AppleIDAuthorizationScopes.fullName,
      //   ],
      // );

      // final oauthCredential = OAuthProvider("apple.com").credential(
      //   idToken: appleCredential.identityToken,
      //   accessToken: appleCredential.authorizationCode,
      // );

      // final userCredential = await _auth.signInWithCredential(oauthCredential);

      // if (userCredential.user != null) {
      //   await createOrUpdateUserProfile(userCredential.user!);
      // }
      //
      // return userCredential.user;
      return null;
    } catch (e) {
      print("Erro Apple Login: $e");
      return null;
    }
  }

  Future<User?> signInAnonymously() async {
    final userCred = await _auth.signInAnonymously();
    return userCred.user;
  }

  Future<void> createOrUpdateUserProfile(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final doc = await userDocRef.get();

    if (!doc.exists) {
      await userDocRef.set({
        'uid': user.uid,
        'name': user.displayName ?? 'Novo Usuário',
        'email': user.email,
        'phone': '',
        'contact': '',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDocRef.update({'lastSignIn': FieldValue.serverTimestamp()});
    }
  }

  Future<void> saveMarkerToFirestore({
    required LatLng coordinates,
    required String title,
    required String address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newMarkerId = 'marker_${DateTime.now().millisecondsSinceEpoch}';

    await _firestore.collection('map_markers').doc(newMarkerId).set({
      'markerId': newMarkerId,
      'type': 'point',
      'coordinates': GeoPoint(coordinates.latitude, coordinates.longitude),
      'title': title,
      'address': address,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfileData({
    required String uid,
    required String name,
    required String phone,
    required String contact,
  }) async {
    final userDocRef = _firestore.collection('users').doc(uid);
    await userDocRef.update({
      'name': name,
      'phone': phone,
      'contact': contact,
      'isProfileComplete': true,
    });

    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<String?> uploadProfileImage(XFile imageFile, String uid) async {
    try {
      final file = File(imageFile.path);
      final storageRef = _storage.ref().child('user_photos/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      await _firestore.collection('users').doc(uid).update({
        'photoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print('Erro no upload da foto: $e');
      return null;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
    }
    await _auth.signOut();
  }
}