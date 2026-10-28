import 'package:cloud_firestore/cloud_firestore.dart';

class PetRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> feedPet(String uid, int foodAmount) async {
    await _db.collection('users').doc(uid).update({
      'pet_hunger': FieldValue.increment(foodAmount),
      'pet_last_interaction': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> playWithPet(String uid, int playAmount) async {
    await _db.collection('users').doc(uid).update({
      'pet_happiness': FieldValue.increment(playAmount),
      'pet_last_interaction': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> walkPet(String uid, double distance) async {
    await _db.collection('users').doc(uid).update({
      'pet_total_distance_walked': FieldValue.increment(distance),
      'pet_energy': FieldValue.increment(-10),
      'pet_last_interaction': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unlockAllAdmin(String uid) async {
    const collars = [
      'collar_red',
      'collar_orange',
      'collar_yellow',
      'collar_green',
      'collar_blue',
      'collar_indigo',
      'collar_violet',
      'collar_gold',
      'collar_diamond',
    ];
    const tricks = ['Spin', 'Jump', 'Roll Over', 'Backflip', 'Moonwalk'];
    const balls = [
      'white',
      'red',
      'orange',
      'yellow',
      'green',
      'blue',
      'indigo',
      'violet',
    ];
    final userRef = _db.collection('users').doc(uid);
    final payload = {
      'pet_owned_accessories': collars,
      'pet_owned_tricks': tricks,
      'pet_owned_balls': balls,
    };
    await userRef.set(payload, SetOptions(merge: true));
    await userRef
        .collection('pet')
        .doc('status')
        .set(payload, SetOptions(merge: true));
  }
}
