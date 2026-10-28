
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedProducts {
  static Future<void> uploadProducts() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Hindi naka-sign in. Mag-login muna para mag-upload.',
      );
    }

    final db = FirebaseFirestore.instance;

    final List<Map<String, dynamic>> products = [
      {
        'id': 'sinigang_na_baboy',
        'name': 'Sinigang na Baboy',
        'category': 'Dinner',
        'description': 'Sinigang na baboy na may sariwang gulay.',
        'price': 349,
        'serving': 'Good for 2-3 persons',
        'available': true,
        'image': 'assets/images/sinigang na baboy.jpg',
      },
      {
        'id': 'laing',
        'name': 'Laing',
        'category': 'Dinner',
        'description': 'Laing na may gata at dahon ng gabi.',
        'price': 249,
        'serving': 'Good for 2 persons',
        'available': true,
        'image': 'assets/images/laing.jpg',
      },
      {
        'id': 'bicol_express',
        'name': 'Bicol Express',
        'category': 'Dinner',
        'description': 'Maanghang na baboy na may gata.',
        'price': 349,
        'serving': 'Good for 2-3 persons',
        'available': true,
        'image': 'assets/images/bicol_express.jpg',
      },
      {
        'id': 'adobong_manok',
        'name': 'Adobong Manok',
        'category': 'Lunch',
        'description': 'Manok na niluto sa toyo at suka.',
        'price': 299,
        'serving': 'Good for 2-3 persons',
        'available': true,
        'image': 'assets/images/adobong_manok.jpg',
      },
      {
        'id': 'fried_tilapia',
        'name': 'Fried Tilapia with Salted Egg',
        'category': 'Lunch',
        'description': 'Pritong tilapia na may salted egg.',
        'price': 279,
        'serving': 'Good for 2 persons',
        'available': true,
        'image': 'assets/images/fried_tilapia.jpg',
      },
      {
        'id': 'lechon_kawali',
        'name': 'Lechon Kawali',
        'category': 'Dinner',
        'description': 'Malutong na lechon kawali.',
        'price': 499,
        'serving': 'Good for 2-3 persons',
        'available': true,
        'image': 'assets/images/lechon_kawali.jpg',
      },
      {
        'id': 'kare_kare',
        'name': 'Kare-Kare',
        'category': 'Dinner',
        'description': 'Kare-kare na may peanut sauce.',
        'price': 499,
        'serving': 'Good for 2-3 persons',
        'available': true,
        'image': 'assets/images/kare_kare.jpg',
      },
      {
        'id': 'halo_halo',
        'name': 'Halo-Halo',
        'category': 'Dessert',
        'description': 'Refreshing na Filipino halo-halo.',
        'price': 149,
        'serving': '1 cup',
        'available': true,
        'image': 'assets/images/halo_halo.jpg',
      },
      {
        'id': 'sago_gulaman',
        'name': 'Sago with Gulaman',
        'category': 'Drinks',
        'description': 'Matamis at malamig na sago gulaman.',
        'price': 49,
        'serving': '1 cup',
        'available': true,
        'image': 'assets/images/sago_gulaman.jpg',
      },
      {
        'id': 'leche_flan',
        'name': 'Leche Flan',
        'category': 'Dessert',
        'description': 'Creamy at matamis na leche flan.',
        'price': 99,
        'serving': '1 serving',
        'available': true,
        'image': 'assets/images/leche_flan.jpg',
      },
    ];

    final batch = db.batch();

    for (final product in products) {
      final id = product['id'] as String;
      final data = Map<String, dynamic>.from(product);
      data.remove('id');

      batch.set(
        db.collection('products').doc(id),
        data,
      );
    }

    await batch.commit();
  }
}
