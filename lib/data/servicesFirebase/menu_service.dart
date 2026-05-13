import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear un menu nuevo
  Future<void> createMenu(String restaurantId, MenuModel menu) async {
    if (restaurantId.isEmpty) {
      throw ArgumentError('restaurantId must not be empty');
    }
    final docRef = _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menus')
        .doc();

    // Aseguramos que el ID del menu se genere correctamente y se incluya en los datos
    final data = menu.toMap();
    data['id'] = docRef.id;
    data['createdAt'] = Timestamp.fromDate(menu.createdAt);

    await docRef.set(data);
  }

  // Obtener todos los menus
  Stream<List<MenuModel>> getMenus(String restaurantId) {
    if (restaurantId.isEmpty) {
      // Retorna un stream con lista vacía para que la UI no falle
      return Stream.value(<MenuModel>[]);
    }
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menus')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Obtener un menu por su categoría
  Stream<List<MenuModel>> getMenusByCategory(
    String restaurantId,
    String category,
  ) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menus')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Actualizar un menu existente
  Future<void> updateMenu(String restaurantId, MenuModel menu) async {
    if (restaurantId.isEmpty) {
      throw ArgumentError('restaurantId must not be empty');
    }
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menus')
        .doc(menu.id)
        .update(menu.toMap());
  }

  // Eliminar un menu
  Future<void> deleteMenu(String restaurantId, String menuId) async {
    if (restaurantId.isEmpty) {
      throw ArgumentError('restaurantId must not be empty');
    }
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menus')
        .doc(menuId)
        .delete();
  }
}
