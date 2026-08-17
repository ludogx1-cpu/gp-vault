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
      'pet_energy': FieldValue.increment(-10), // Assuming walking costs energy
      'pet_last_interaction': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unlockAllAdmin(String uid) async {
    await _db.collection('users').doc(uid).update({
      'pet_owned_accessories': [
        'top_hat', 'sunglasses', 'gold_chain', 'diamond_watch', 'crown',
        'coat_basic', 'coat_rain', 'coat_winter', 'coat_luxury'
      ],
      'active_trick_buffs': ['Spin', 'Jump', 'Roll Over', 'Backflip', 'Moonwalk'],
      'pet_owned_tricks': ['Spin', 'Jump', 'Roll Over', 'Backflip', 'Moonwalk'],
    });
  }
}
