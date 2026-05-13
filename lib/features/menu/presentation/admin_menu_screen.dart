import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/menu_model.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../data/servicesFirebase/menu_service.dart';
import '../../../data/servicesFirebase/order_service.dart';
import '../../../data/servicesFirebase/reservation_service.dart';
import '../../../data/servicesFirebase/user_service.dart';
import '../../auth/auth_controller.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen>
    with SingleTickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  final ReservationService _reservationService = ReservationService();
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();
  final CloudinaryService _cloudinaryService = const CloudinaryService();
  final AuthController _authController = AuthController();
  late final TabController _tabController;
  final GlobalKey<FormState> _menuFormKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  MenuModel? _editingMenu;
  String _selectedCategory = 'general';
  String _selectedManageCategory = 'all';
  String _selectedReservationStatus = 'all';
  String _selectedOrderStatus = 'all';
  bool _available = true;
  bool _isSaving = false;
  final Set<String> _deletingMenuIds = <String>{};
  final Set<String> _updatingReservationIds = <String>{};
  final Set<String> _updatingOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _resetForm() {
    nameController.clear();
    descController.clear();
    priceController.clear();
    _menuFormKey.currentState?.reset();
    setState(() {
      _editingMenu = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedCategory = 'general';
      _available = true;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _normalizePrice(String value) {
    return value.trim().replaceAll(',', '.');
  }

  Future<void> _pickMenuImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowCompression: false,
      withData: false,
    );

    if (result == null) return;

    final file = result.files.single;
    final path = file.path;

    if (path == null || path.isEmpty) {
      _showSnackBar('No se pudo leer la imagen seleccionada');
      return;
    }

    final bytes = await File(path).readAsBytes();

    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
    });
  }

  Widget _imagePlaceholder(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuImagePicker() {
    final existingImageUrl = _editingMenu?.imageUrl ?? '';
    final hasSelectedImage = _selectedImageBytes != null;
    final hasExistingImage = existingImageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen del plato',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.grey.shade100,
              child: hasSelectedImage
                  ? Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : hasExistingImage
                      ? Image.network(
                          existingImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                           errorBuilder: (context, error, stackTrace) {
                            return _imagePlaceholder(
                              'No se pudo cargar la imagen actual',
                            );
                          },
                        )
                      : _imagePlaceholder('Sin imagen seleccionada'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickMenuImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              hasSelectedImage
                  ? 'Cambiar imagen'
                  : hasExistingImage
                      ? 'Reemplazar imagen'
                      : 'Elegir imagen',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authController.logout(clearRemember: true);
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    }
  }

  Widget _sectionTitle(String title, IconData icon, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.redAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final selected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedCategory = value;
        });
      },
      selectedColor: Colors.redAccent.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? Colors.redAccent : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedManageCategory == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedManageCategory = value;
        });
      },
      selectedColor: Colors.redAccent.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? Colors.redAccent : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildReservationFilterChip(String value, String label) {
    final selected = _selectedReservationStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedReservationStatus = value;
        });
      },
      selectedColor: Colors.redAccent.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? Colors.redAccent : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Color _reservationStatusColor(String status) {
    switch (status) {
      case ReservationModel.statusConfirmed:
        return Colors.green;
      case ReservationModel.statusCanceled:
        return Colors.redAccent;
      case ReservationModel.statusPending:
      default:
        return Colors.orange;
    }
  }

  IconData _reservationStatusIcon(String status) {
    switch (status) {
      case ReservationModel.statusConfirmed:
        return Icons.check_circle_outline;
      case ReservationModel.statusCanceled:
        return Icons.cancel_outlined;
      case ReservationModel.statusPending:
      default:
        return Icons.schedule_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _shortUserId(String userId) {
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 8)}…';
  }

  Widget _reservationStatusChip(String status) {
    final color = _reservationStatusColor(status);
    return Chip(
      avatar: Icon(_reservationStatusIcon(status), size: 18, color: Colors.white),
      label: Text(ReservationModel.labelForStatus(status)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }

  Future<void> _changeReservationStatus(
    String restaurantId,
    ReservationModel reservation,
    String status,
  ) async {
    if (reservation.status == status) {
      _showSnackBar(
        'La reserva ya está ${ReservationModel.labelForStatus(status).toLowerCase()}',
      );
      return;
    }

    setState(() {
      _updatingReservationIds.add(reservation.id);
    });

    try {
      await _reservationService.updateReservationStatus(
        restaurantId,
        reservation.id,
        status,
      );
      _showSnackBar(
        'Reserva marcada como ${ReservationModel.labelForStatus(status).toLowerCase()}',
      );
    } catch (e) {
      _showSnackBar('Error al actualizar reserva: $e');
    } finally {
      if (mounted) {
        setState(() {
          _updatingReservationIds.remove(reservation.id);
        });
      }
    }
  }

  Widget _reservationCard(
    BuildContext context,
    String restaurantId,
    ReservationModel reservation,
  ) {
    final isUpdating = _updatingReservationIds.contains(reservation.id);

    return FutureBuilder<UserModel?>(
      future: _userService.getUser(reservation.userId),
      builder: (context, userSnapshot) {
        final customerLabel = userSnapshot.data?.email.isNotEmpty == true
            ? userSnapshot.data!.email
            : 'Cliente ${_shortUserId(reservation.userId)}';

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor:
                  _reservationStatusColor(reservation.status).withValues(alpha: 0.14),
              child: Icon(
                _reservationStatusIcon(reservation.status),
                color: _reservationStatusColor(reservation.status),
              ),
            ),
            title: Text(
              customerLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fecha: ${_formatDate(reservation.date)} · ${_formatTime(reservation.date)}',
                  ),
                  const SizedBox(height: 4),
                  Text('Personas: ${reservation.people}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _reservationStatusChip(reservation.status),
                    ],
                  ),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: isUpdating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.more_vert),
              enabled: !isUpdating,
              onSelected: (status) => _changeReservationStatus(
                restaurantId,
                reservation,
                status,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: ReservationModel.statusPending,
                  child: Text('Marcar como pendiente'),
                ),
                const PopupMenuItem(
                  value: ReservationModel.statusConfirmed,
                  child: Text('Confirmar reserva'),
                ),
                const PopupMenuItem(
                  value: ReservationModel.statusCanceled,
                  child: Text('Cancelar reserva'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case OrderModel.statusConfirmed:
        return Colors.blue;
      case OrderModel.statusPreparing:
        return Colors.deepPurple;
      case OrderModel.statusDelivered:
        return Colors.green;
      case OrderModel.statusCanceled:
        return Colors.redAccent;
      case OrderModel.statusPending:
      default:
        return Colors.orange;
    }
  }

  IconData _orderStatusIcon(String status) {
    switch (status) {
      case OrderModel.statusConfirmed:
        return Icons.check_circle_outline;
      case OrderModel.statusPreparing:
        return Icons.kitchen_outlined;
      case OrderModel.statusDelivered:
        return Icons.local_shipping_outlined;
      case OrderModel.statusCanceled:
        return Icons.cancel_outlined;
      case OrderModel.statusPending:
      default:
        return Icons.schedule_outlined;
    }
  }

  String _orderStatusLabel(String status) {
    switch (status) {
      case OrderModel.statusConfirmed:
        return 'Confirmado';
      case OrderModel.statusPreparing:
        return 'En preparación';
      case OrderModel.statusDelivered:
        return 'Entregado';
      case OrderModel.statusCanceled:
        return 'Cancelado';
      case OrderModel.statusPending:
      default:
        return 'Pendiente';
    }
  }

  Widget _orderStatusChip(String status) {
    final color = _orderStatusColor(status);
    return Chip(
      avatar: Icon(_orderStatusIcon(status), size: 18, color: Colors.white),
      label: Text(_orderStatusLabel(status)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }

  Widget _buildOrderFilterChip(String value, String label) {
    final selected = _selectedOrderStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedOrderStatus = value;
        });
      },
      selectedColor: Colors.redAccent.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? Colors.redAccent : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _shortOrderId(String orderId) {
    if (orderId.length <= 8) return orderId;
    return '${orderId.substring(0, 8)}…';
  }

  Future<void> _changeOrderStatus(
    String restaurantId,
    OrderModel order,
    String status,
  ) async {
    if (order.status == status) {
      _showSnackBar('El pedido ya está ${_orderStatusLabel(status).toLowerCase()}');
      return;
    }

    setState(() {
      _updatingOrderIds.add(order.id);
    });

    try {
      await _orderService.updateOrderStatus(restaurantId, order.id, status);
      _showSnackBar('Pedido marcado como ${_orderStatusLabel(status).toLowerCase()}');
    } catch (e) {
      _showSnackBar('Error al actualizar pedido: $e');
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrderIds.remove(order.id);
        });
      }
    }
  }

  Widget _orderActionButtons(
    String restaurantId,
    OrderModel order,
    bool isUpdating,
  ) {
    final buttons = <Widget>[];

    void addAction(String label, IconData icon, String nextStatus, Color color) {
      buttons.add(
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: isUpdating
                ? null
                : () => _changeOrderStatus(restaurantId, order, nextStatus),
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }

    switch (order.status) {
      case OrderModel.statusPending:
        addAction('Confirmar', Icons.check_circle_outline, OrderModel.statusConfirmed, Colors.green);
        addAction('Cancelar', Icons.cancel_outlined, OrderModel.statusCanceled, Colors.redAccent);
        break;
      case OrderModel.statusConfirmed:
        addAction('Preparar', Icons.kitchen_outlined, OrderModel.statusPreparing, Colors.deepPurple);
        addAction('Entregar', Icons.local_shipping_outlined, OrderModel.statusDelivered, Colors.green);
        addAction('Cancelar', Icons.cancel_outlined, OrderModel.statusCanceled, Colors.redAccent);
        break;
      case OrderModel.statusPreparing:
        addAction('Entregar', Icons.local_shipping_outlined, OrderModel.statusDelivered, Colors.green);
        addAction('Cancelar', Icons.cancel_outlined, OrderModel.statusCanceled, Colors.redAccent);
        break;
      case OrderModel.statusDelivered:
      case OrderModel.statusCanceled:
        buttons.add(
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Sin acciones disponibles',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        );
        break;
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: buttons,
    );
  }

  Widget _orderCard(
    BuildContext context,
    String restaurantId,
    OrderModel order,
  ) {
    final isUpdating = _updatingOrderIds.contains(order.id);
    final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return FutureBuilder<UserModel?>(
      future: _userService.getUser(order.userId),
      builder: (context, userSnapshot) {
        final customerLabel = userSnapshot.data?.email.isNotEmpty == true
            ? userSnapshot.data!.email
            : 'Cliente ${_shortUserId(order.userId)}';

        final itemPreview = order.items
            .take(2)
            .map((item) => '${item.quantity}x ${item.name}')
            .join(' · ');

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _orderStatusColor(order.status).withValues(alpha: 0.14),
              child: Icon(
                _orderStatusIcon(order.status),
                color: _orderStatusColor(order.status),
              ),
            ),
            title: Text(
              '$customerLabel · Pedido ${_shortOrderId(order.id)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fecha: ${_formatDate(order.createdAt)} · ${_formatTime(order.createdAt)}'),
                  const SizedBox(height: 4),
                  Text('Platos: $totalItems · Total: ${order.total.toStringAsFixed(2)} €'),
                  if (itemPreview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      itemPreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _orderStatusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _orderActionButtons(restaurantId, order, isUpdating),
                ],
              ),
            ),
            trailing: isUpdating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _saveMenu(String restaurantId) async {
    if (_isSaving) return;

    final isValid = _menuFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = nameController.text.trim();
      final description = descController.text.trim();
      final price = double.parse(_normalizePrice(priceController.text));
      var imageUrl = _editingMenu?.imageUrl ?? '';

      if (_selectedImageBytes != null) {
        imageUrl = await _cloudinaryService.uploadImage(
          bytes: _selectedImageBytes!,
          fileName: _selectedImageName ?? 'menu_image.jpg',
          folder: 'gastro_delivery/menu_images',
        );
      }

      if (_editingMenu == null) {
        final menu = MenuModel(
          id: '',
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          category: _selectedCategory,
          available: _available,
          restaurantId: restaurantId,
          createdAt: DateTime.now(),
        );
        await _menuService.createMenu(restaurantId, menu);
        _showSnackBar('Plato creado correctamente');
      } else {
        final updated = MenuModel(
          id: _editingMenu!.id,
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          category: _selectedCategory,
          available: _available,
          restaurantId: restaurantId,
          createdAt: _editingMenu!.createdAt,
        );
        await _menuService.updateMenu(restaurantId, updated);
        _showSnackBar('Plato actualizado correctamente');
      }
      _resetForm();
    } catch (e) {
      _showSnackBar('Error al guardar plato: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSummaryTab(String restaurantId) {
    return StreamBuilder<List<MenuModel>>(
      stream: _menuService.getMenus(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error cargando el menú: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final menus = snapshot.data ?? const <MenuModel>[];
        final total = menus.length;
        final available = menus.where((menu) => menu.available).length;
        final unavailable = total - available;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Panel de gestión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Administra platos, precios y disponibilidad desde una interfaz más limpia y profesional.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Restaurant ID: $restaurantId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _summaryTile('Total platos', total.toString(), Icons.restaurant),
                _summaryTile('Disponibles', available.toString(), Icons.check_circle),
                _summaryTile('No disponibles', unavailable.toString(), Icons.pause_circle),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Atajos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _tabController.animateTo(1),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Crear un nuevo plato'),
                    ),
                    TextButton.icon(
                      onPressed: () => _tabController.animateTo(2),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('Gestionar platos existentes'),
                    ),
                    TextButton.icon(
                      onPressed: () => _tabController.animateTo(4),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Ver pedidos de clientes'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ReservationModel>>(
              stream: _reservationService.getReservationsByRestaurant(restaurantId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('Error cargando reservas: ${snapshot.error}'),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final reservations = snapshot.data ?? const <ReservationModel>[];
                final totalReservations = reservations.length;
                final pendingReservations = reservations
                    .where((reservation) =>
                        reservation.status == ReservationModel.statusPending)
                    .length;
                final confirmedReservations = reservations
                    .where((reservation) =>
                        reservation.status == ReservationModel.statusConfirmed)
                    .length;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reservas recientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width >= 600 ? 3 : 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 88,
                          ),
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return _summaryTile(
                                  'Total reservas',
                                  totalReservations.toString(),
                                  Icons.event_note,
                                );
                              case 1:
                                return _summaryTile(
                                  'Pendientes',
                                  pendingReservations.toString(),
                                  Icons.schedule,
                                );
                              default:
                                return _summaryTile(
                                  'Confirmadas',
                                  confirmedReservations.toString(),
                                  Icons.check_circle,
                                );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _tabController.animateTo(3),
                          icon: const Icon(Icons.manage_search_outlined),
                          label: const Text('Abrir gestión de reservas'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                Icon(icon, color: Colors.redAccent, size: 18),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab(String restaurantId) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _menuFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    _editingMenu == null ? 'Nuevo plato' : 'Editar plato',
                    _editingMenu == null
                        ? Icons.add_circle_outline
                        : Icons.edit_outlined,
                    subtitle: _editingMenu == null
                        ? 'Completa los datos para publicar un plato en el menú.'
                        : 'Modifica los campos y guarda los cambios.',
                  ),
                  if (_editingMenu != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Editando: ${_editingMenu!.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: nameController,
                    label: 'Nombre',
                    icon: Icons.badge_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduce un nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: descController,
                    label: 'Descripción',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduce una descripción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: priceController,
                    label: 'Precio',
                    icon: Icons.euro_symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final parsed = double.tryParse(_normalizePrice(value ?? ''));
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduce un precio';
                      }
                      if (parsed == null || parsed <= 0) {
                        return 'Introduce un precio válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuImagePicker(),
                  const SizedBox(height: 16),
                  const Text(
                    'Categoría',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildCategoryChip('general', 'General'),
                      _buildCategoryChip('entrantes', 'Entrantes'),
                      _buildCategoryChip('principales', 'Principales'),
                      _buildCategoryChip('postres', 'Postres'),
                      _buildCategoryChip('bebidas', 'Bebidas'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _available,
                    onChanged: (value) {
                      setState(() {
                        _available = value;
                      });
                    },
                    title: const Text('Disponible'),
                    subtitle: const Text(
                      'Actívalo para mostrar el plato al cliente.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : () => _saveMenu(restaurantId),
                      icon: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _editingMenu == null
                                  ? Icons.save_outlined
                                  : Icons.check_circle_outline,
                            ),
                      label: Text(
                        _editingMenu == null ? 'Crear plato' : 'Guardar cambios',
                      ),
                    ),
                  ),
                  if (_editingMenu != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar edición'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuCard(BuildContext context, String restaurantId, MenuModel menu) {
    final isDeleting = _deletingMenuIds.contains(menu.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                  child: const Icon(Icons.fastfood, color: Colors.redAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        menu.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${menu.price.toStringAsFixed(2)} € • ${menu.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: menu.available
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          menu.available ? 'Disponible' : 'No disponible',
                          style: TextStyle(
                            color: menu.available
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () {
                    setState(() {
                      _editingMenu = menu;
                      nameController.text = menu.name;
                      descController.text = menu.description;
                      priceController.text = menu.price.toStringAsFixed(2);
                      _selectedImageBytes = null;
                      _selectedImageName = null;
                      _selectedCategory = menu.category;
                      _available = menu.available;
                    });
                    _tabController.animateTo(1);
                  },
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, size: 18),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar plato'),
                              content: const Text(
                                '¿Seguro que quieres eliminar este plato?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;

                          setState(() {
                            _deletingMenuIds.add(menu.id);
                          });

                          try {
                            await _menuService.deleteMenu(restaurantId, menu.id);
                            if (_editingMenu?.id == menu.id) {
                              _resetForm();
                            }
                            _showSnackBar('Plato eliminado correctamente');
                          } catch (e) {
                            _showSnackBar('Error al eliminar plato: $e');
                          } finally {
                            if (mounted) {
                              setState(() {
                                _deletingMenuIds.remove(menu.id);
                              });
                            }
                          }
                        },
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageTab(String restaurantId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              _sectionTitle(
                'Platos publicados',
                Icons.restaurant_menu_outlined,
                subtitle: 'Revisa, edita o elimina platos del menú.',
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildFilterChip('all', 'Todas'),
                      _buildFilterChip('general', 'General'),
                      _buildFilterChip('entrantes', 'Entrantes'),
                      _buildFilterChip('principales', 'Principales'),
                      _buildFilterChip('postres', 'Postres'),
                      _buildFilterChip('bebidas', 'Bebidas'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<MenuModel>>(
                  stream: _menuService.getMenus(restaurantId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('Error cargando platos: ${snapshot.error}'),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.no_food_outlined,
                              size: 54,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Todavía no hay platos creados.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }

                    final menus = snapshot.data!;
                    final filteredMenus = _selectedManageCategory == 'all'
                        ? menus
                        : menus
                            .where(
                              (menu) => menu.category.trim().toLowerCase() ==
                                  _selectedManageCategory,
                            )
                            .toList();

                    if (filteredMenus.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt_off_outlined,
                              size: 54,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No hay platos en esta categoría.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: filteredMenus.length,
                      itemBuilder: (context, index) {
                        if (index > 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _menuCard(
                              context,
                              restaurantId,
                              filteredMenus[index],
                            ),
                          );
                        }

                        return _menuCard(
                          context,
                          restaurantId,
                          filteredMenus[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsTab(String restaurantId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                'Reservas',
                Icons.event_available_outlined,
                subtitle: 'Visualiza las reservas de clientes y cambia su estado.',
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildReservationFilterChip('all', 'Todas'),
                      _buildReservationFilterChip(
                        ReservationModel.statusPending,
                        'Pendientes',
                      ),
                      _buildReservationFilterChip(
                        ReservationModel.statusConfirmed,
                        'Confirmadas',
                      ),
                      _buildReservationFilterChip(
                        ReservationModel.statusCanceled,
                        'Canceladas',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<List<ReservationModel>>(
                stream: _reservationService.getReservationsByRestaurant(restaurantId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('Error cargando reservas: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 54,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Todavía no hay reservas creadas.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final reservations = snapshot.data!;
                  final filteredReservations = _selectedReservationStatus == 'all'
                      ? reservations
                      : reservations
                          .where(
                            (reservation) => reservation.status.trim().toLowerCase() ==
                                _selectedReservationStatus,
                          )
                          .toList();

                  if (filteredReservations.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.filter_alt_off_outlined,
                              size: 54,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No hay reservas en este estado.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredReservations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _reservationCard(
                      context,
                      restaurantId,
                      filteredReservations[index],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab(String restaurantId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                'Pedidos',
                Icons.receipt_long_outlined,
                subtitle:
                    'Revisa los pedidos de clientes y cambia su estado desde aquí.',
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildOrderFilterChip('all', 'Todos'),
                      _buildOrderFilterChip(OrderModel.statusPending, 'Pendientes'),
                      _buildOrderFilterChip(OrderModel.statusConfirmed, 'Confirmados'),
                      _buildOrderFilterChip(
                        OrderModel.statusPreparing,
                        'En preparación',
                      ),
                      _buildOrderFilterChip(OrderModel.statusDelivered, 'Entregados'),
                      _buildOrderFilterChip(OrderModel.statusCanceled, 'Cancelados'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<OrderModel>>(
                  stream: _orderService.getOrdersByRestaurant(restaurantId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('Error cargando pedidos: ${snapshot.error}'),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 54,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Todavía no hay pedidos creados.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }

                    final orders = snapshot.data!;
                    final filteredOrders = _selectedOrderStatus == 'all'
                        ? orders
                        : orders
                            .where(
                              (order) => order.status.trim().toLowerCase() ==
                                  _selectedOrderStatus,
                            )
                            .toList();

                    if (filteredOrders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt_off_outlined,
                              size: 54,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No hay pedidos en este estado.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _orderCard(
                        context,
                        restaurantId,
                        filteredOrders[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Panel de administrador',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gestiona tus platos y accesos desde un solo lugar.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Resumen'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: const Text('Crear plato'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: const Text('Editar platos'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Reservas'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Pedidos'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(4);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout(context);
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'GastroDeliveryPro',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Gestión de Menú'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumen'),
            Tab(icon: Icon(Icons.edit_note_outlined), text: 'Crear'),
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'Editar'),
            Tab(icon: Icon(Icons.event_available_outlined), text: 'Reservas'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Pedidos'),
          ],
        ),
      ),
      body: FutureBuilder(
        future: _authController.getCurrentUserData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error cargando el usuario: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No se pudo cargar la información del usuario.'),
            );
          }
          final user = snapshot.data!;
          final restaurantId = user.restaurantId;
          if (restaurantId.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 52,
                          color: Colors.redAccent,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No tienes un restaurante asignado. Contacta con el administrador para configurar tu restaurante.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth >= 1100
                  ? 1100.0
                  : constraints.maxWidth;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(restaurantId),
                      _buildCreateTab(restaurantId),
                      _buildManageTab(restaurantId),
                      _buildReservationsTab(restaurantId),
                      _buildOrdersTab(restaurantId),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
