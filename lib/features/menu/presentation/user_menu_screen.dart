import 'package:flutter/material.dart';

import '../../../../data/models/menu_model.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/servicesFirebase/menu_service.dart';
import '../../../../data/servicesFirebase/order_service.dart';
import '../../../../data/servicesFirebase/reservation_service.dart';
import '../../auth/auth_controller.dart';

class UserMenuScreen extends StatefulWidget {
  const UserMenuScreen({super.key});

  @override
  State<UserMenuScreen> createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen>
	with SingleTickerProviderStateMixin {
  final AuthController _authController = AuthController();
  final MenuService _menuService = MenuService();
  final OrderService _orderService = OrderService();
  final ReservationService _reservationService = ReservationService();
  late final TabController _tabController;
  late final Future<UserModel?> _currentUserFuture;

  final GlobalKey<FormState> _reservationFormKey = GlobalKey<FormState>();
  final TextEditingController _peopleController = TextEditingController(text: '2');

  String _selectedCategory = 'all';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isCreatingReservation = false;
  bool _isCreatingOrder = false;
  final Map<String, _CartItem> _cartItems = <String, _CartItem>{};

  @override
  void initState() {
	super.initState();
	_tabController = TabController(length: 5, vsync: this);
	_currentUserFuture = _authController.getCurrentUserData();
  }

  @override
  void dispose() {
	_tabController.dispose();
	_peopleController.dispose();
	super.dispose();
  }

  void _showSnackBar(String message) {
	if (!mounted) return;
	ScaffoldMessenger.of(context).showSnackBar(
	  SnackBar(content: Text(message)),
	);
  }

  Future<void> _confirmLogout() async {
	final confirm = await showDialog<bool>(
	  context: context,
	  builder: (dialogContext) => AlertDialog(
		title: const Text('Cerrar sesión'),
		content: const Text('¿Seguro que quieres cerrar sesión?'),
		actions: [
		  TextButton(
			onPressed: () => Navigator.of(dialogContext).pop(false),
			child: const Text('Cancelar'),
		  ),
		  TextButton(
			onPressed: () => Navigator.of(dialogContext).pop(true),
			child: const Text('Cerrar sesión'),
		  ),
		],
	  ),
	);

	if (confirm == true) {
	  await _authController.logout(clearRemember: true);
	}
  }

  String _normalizeCategory(String value) => value.trim().toLowerCase();

  Future<void> _pickDate() async {
	final picked = await showDatePicker(
	  context: context,
	  initialDate: _selectedDate,
	  firstDate: DateTime.now(),
	  lastDate: DateTime.now().add(const Duration(days: 365)),
	);

	if (picked != null) {
	  setState(() {
		_selectedDate = picked;
	  });
	}
  }

  Future<void> _pickTime() async {
	final picked = await showTimePicker(
	  context: context,
	  initialTime: _selectedTime,
	);

	if (picked != null) {
	  setState(() {
		_selectedTime = picked;
	  });
	}
  }

  Future<void> _createReservation(UserModel user) async {
	if (_isCreatingReservation) return;

	final isValid = _reservationFormKey.currentState?.validate() ?? false;
	if (!isValid) return;

	final people = int.tryParse(_peopleController.text.trim());
	if (people == null || people <= 0) {
	  _showSnackBar('Introduce un número de personas válido');
	  return;
	}

	final reservationDate = DateTime(
	  _selectedDate.year,
	  _selectedDate.month,
	  _selectedDate.day,
	  _selectedTime.hour,
	  _selectedTime.minute,
	);

	if (reservationDate.isBefore(DateTime.now())) {
	  _showSnackBar('La reserva debe ser para una fecha futura');
	  return;
	}

	setState(() {
	  _isCreatingReservation = true;
	});

	try {
	  final reservation = ReservationModel(
		id: '',
		restaurantId: user.restaurantId,
		userId: user.uid,
		date: reservationDate,
		people: people,
		status: ReservationModel.statusPending,
		createdAt: DateTime.now(),
	  );

	  await _reservationService.createReservation(reservation);

	  _showSnackBar('Reserva enviada correctamente');
	  _reservationFormKey.currentState?.reset();
	  _peopleController.text = '2';
	  setState(() {
		_selectedDate = DateTime.now().add(const Duration(days: 1));
		_selectedTime = const TimeOfDay(hour: 20, minute: 0);
	  });
	  _tabController.animateTo(2);
	} catch (e) {
	  _showSnackBar('Error al crear la reserva: $e');
	} finally {
	  if (mounted) {
		setState(() {
		  _isCreatingReservation = false;
		});
	  }
	}
  }

  Widget _buildFilterChip(String value, String label) {
	final selected = _selectedCategory == value;
	return ChoiceChip(
	  label: Text(label),
	  selected: selected,
	  onSelected: (_) {
		setState(() {
		  _selectedCategory = value;
		});
	  },
	  selectedColor: Colors.redAccent.withValues(alpha: 0.12),
	  labelStyle: TextStyle(
		color: selected ? Colors.redAccent : Colors.black87,
		fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
	  ),
	);
  }

  Widget _statusChip(String status) {
	Color background;
	Color foreground;

	switch (status) {
	  case ReservationModel.statusConfirmed:
		background = Colors.green.withValues(alpha: 0.12);
		foreground = Colors.green.shade700;
		break;
	  case ReservationModel.statusCanceled:
		background = Colors.red.withValues(alpha: 0.12);
		foreground = Colors.red.shade700;
		break;
	  case ReservationModel.statusPending:
	  default:
		background = Colors.orange.withValues(alpha: 0.12);
		foreground = Colors.orange.shade800;
		break;
	}

	return Chip(
	  backgroundColor: background,
	  label: Text(
		ReservationModel.labelForStatus(status),
		style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
	  ),
	);
  }

  String _formattedDate(BuildContext context, DateTime date) {
	return MaterialLocalizations.of(context).formatFullDate(date);
  }

  String _formattedTime(BuildContext context, TimeOfDay time) {
	return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  int _cartUnits() {
	return _cartItems.values.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double _cartTotal() {
	return _cartItems.values.fold<double>(
	  0,
	  (sum, item) => sum + (item.menu.price * item.quantity),
	);
  }

  void _addToCart(MenuModel menu) {
	if (!menu.available) {
	  _showSnackBar('Este plato no esta disponible ahora mismo');
	  return;
	}

	setState(() {
	  final existing = _cartItems[menu.id];
	  if (existing == null) {
		_cartItems[menu.id] = _CartItem(menu: menu, quantity: 1);
	  } else {
		_cartItems[menu.id] = existing.copyWith(quantity: existing.quantity + 1);
	  }
	});
  }

  void _decreaseCartItem(String menuId) {
	setState(() {
	  final existing = _cartItems[menuId];
	  if (existing == null) return;
	  if (existing.quantity <= 1) {
		_cartItems.remove(menuId);
		return;
	  }
	  _cartItems[menuId] = existing.copyWith(quantity: existing.quantity - 1);
	});
  }

  void _increaseCartItem(String menuId) {
	setState(() {
	  final existing = _cartItems[menuId];
	  if (existing == null) return;
	  _cartItems[menuId] = existing.copyWith(quantity: existing.quantity + 1);
	});
  }

  Future<void> _createOrder(UserModel user) async {
	if (_isCreatingOrder) return;
	if (_cartItems.isEmpty) {
	  _showSnackBar('Tu carrito esta vacio');
	  return;
	}

	setState(() {
	  _isCreatingOrder = true;
	});

	try {
	  final items = _cartItems.values
		  .map(
			(item) => OrderItemModel(
			  menuId: item.menu.id,
			  name: item.menu.name,
			  price: item.menu.price,
			  quantity: item.quantity,
			  imageUrl: item.menu.imageUrl,
			),
		  )
		  .toList();

	  final order = OrderModel(
		id: '',
		restaurantId: user.restaurantId,
		userId: user.uid,
		items: items,
		total: _cartTotal(),
		status: OrderModel.statusPending,
		createdAt: DateTime.now(),
	  );

	  await _orderService.createOrder(order);
	  setState(() {
		_cartItems.clear();
	  });
	  _showSnackBar('Pedido creado correctamente');
	  _tabController.animateTo(4);
	} catch (e) {
	  _showSnackBar('Error al crear el pedido: $e');
	} finally {
	  if (mounted) {
		setState(() {
		  _isCreatingOrder = false;
		});
	  }
	}
  }

  Widget _menuCard(MenuModel menu) {
	final available = menu.available;
	final quantityInCart = _cartItems[menu.id]?.quantity ?? 0;

	return Card(
	  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
	  elevation: 2,
	  child: Column(
		crossAxisAlignment: CrossAxisAlignment.stretch,
		children: [
		  Expanded(
			child: ClipRRect(
			  borderRadius: const BorderRadius.vertical(
				top: Radius.circular(16),
			  ),
				  child: menu.imageUrl.isNotEmpty
					  ? Image.network(
						  menu.imageUrl,
						  fit: BoxFit.cover,
						  errorBuilder: (_, error, stackTrace) {
						return Container(
						  color: Colors.grey.shade200,
						  child: const Icon(
							Icons.fastfood,
							size: 48,
							color: Colors.grey,
						  ),
						);
					  },
					)
				  : Container(
					  color: Colors.grey.shade200,
					  child: const Icon(
						Icons.fastfood,
						size: 48,
						color: Colors.grey,
					  ),
					),
			),
		  ),
		  Padding(
			padding: const EdgeInsets.all(10),
			child: Column(
			  crossAxisAlignment: CrossAxisAlignment.start,
			  children: [
				Row(
				  children: [
					Expanded(
					  child: Text(
						menu.name,
						style: const TextStyle(fontWeight: FontWeight.w600),
					  ),
					),
					if (quantityInCart > 0)
					  Container(
						padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
						decoration: BoxDecoration(
						  color: Colors.redAccent.withValues(alpha: 0.12),
						  borderRadius: BorderRadius.circular(999),
						),
						child: Text(
						  'x$quantityInCart',
						  style: const TextStyle(
							fontWeight: FontWeight.w700,
							color: Colors.redAccent,
						  ),
						),
					  )
					else if (!available)
					  const Icon(Icons.block_outlined, size: 18, color: Colors.redAccent),
				  ],
				),
				const SizedBox(height: 6),
				Text(
				  '${menu.price.toStringAsFixed(2)} €',
				  style: TextStyle(color: Colors.grey.shade700),
				),
				const SizedBox(height: 8),
				Row(
				  mainAxisAlignment: MainAxisAlignment.spaceBetween,
				  children: [
					Text(
					  menu.category,
					  style: TextStyle(
						color: Colors.grey.shade600,
						fontSize: 12,
					  ),
					),
					Container(
					  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
					  decoration: BoxDecoration(
						color: available
							? Colors.green.withValues(alpha: 0.12)
							: Colors.red.withValues(alpha: 0.12),
						borderRadius: BorderRadius.circular(999),
					  ),
					  child: Text(
						available ? 'Disponible' : 'No disponible',
						style: TextStyle(
						  color: available ? Colors.green.shade700 : Colors.red.shade700,
						  fontSize: 11,
						  fontWeight: FontWeight.w600,
						),
					  ),
					),
				  ],
				),
				const SizedBox(height: 10),
				SizedBox(
				  width: double.infinity,
				  child: ElevatedButton.icon(
					onPressed: available ? () => _addToCart(menu) : null,
					icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
					label: Text(available ? 'Anadir' : 'No disponible'),
					style: ElevatedButton.styleFrom(
					  backgroundColor: Colors.redAccent,
					  foregroundColor: Colors.white,
					  disabledBackgroundColor: Colors.grey.shade300,
					  disabledForegroundColor: Colors.grey.shade700,
					),
				  ),
				),
			  ],
			),
		  ),
		],
	  ),
	);
  }

  Widget _buildMenuTab(UserModel user) {
	final restaurantId = user.restaurantId;

	return Column(
	  children: [
		const SizedBox(height: 12),
		SingleChildScrollView(
		  scrollDirection: Axis.horizontal,
		  padding: const EdgeInsets.symmetric(horizontal: 12),
		  child: Row(
			children: [
				_buildFilterChip('all', 'Todas'),
			  const SizedBox(width: 8),
				_buildFilterChip('general', 'General'),
			  const SizedBox(width: 8),
				_buildFilterChip('entrantes', 'Entrantes'),
			  const SizedBox(width: 8),
				_buildFilterChip('principales', 'Principales'),
			  const SizedBox(width: 8),
				_buildFilterChip('postres', 'Postres'),
			  const SizedBox(width: 8),
				_buildFilterChip('bebidas', 'Bebidas'),
			],
		  ),
		),
		const SizedBox(height: 12),
		Expanded(
		  child: StreamBuilder<List<MenuModel>>(
			stream: _menuService.getMenus(restaurantId),
			builder: (context, snapshot) {
			  if (snapshot.hasError) {
				return Center(child: Text('Error cargando el menú: ${snapshot.error}'));
			  }

			  if (snapshot.connectionState == ConnectionState.waiting) {
				return const Center(child: CircularProgressIndicator());
			  }

			  final menus = snapshot.data ?? <MenuModel>[];
			  final filteredMenus = _selectedCategory == 'all'
				  ? menus
				  : menus
					  .where(
						(menu) => _normalizeCategory(menu.category) == _selectedCategory,
					  )
					  .toList();

			  if (filteredMenus.isEmpty) {
				return Center(
				  child: Column(
					mainAxisSize: MainAxisSize.min,
					children: const [
					  Icon(Icons.no_food_outlined, size: 56, color: Colors.grey),
					  SizedBox(height: 8),
					  Text('No hay platos en esta categoría'),
					],
				  ),
				);
			  }

			  final crossAxis = MediaQuery.of(context).size.width >= 600 ? 3 : 2;

			  return GridView.builder(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
				gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
				  crossAxisCount: crossAxis,
				  crossAxisSpacing: 12,
				  mainAxisSpacing: 12,
				  childAspectRatio: 0.78,
				),
				itemCount: filteredMenus.length,
				itemBuilder: (context, index) => _menuCard(filteredMenus[index]),
			  );
			},
		  ),
		),
	  ],
	);
  }

  Widget _buildReservationTab(UserModel user) {
	return SingleChildScrollView(
	  padding: const EdgeInsets.all(16),
	  child: Card(
		elevation: 2,
		shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
		child: Padding(
		  padding: const EdgeInsets.all(18),
		  child: Form(
			key: _reservationFormKey,
			child: Column(
			  crossAxisAlignment: CrossAxisAlignment.start,
			  children: [
				const Text(
				  'Nueva reserva',
				  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
				),
				const SizedBox(height: 8),
				Text(
				  'Reserva para el restaurante ${user.restaurantId}.',
				  style: TextStyle(color: Colors.grey.shade700),
				),
				const SizedBox(height: 18),
				_inputSectionLabel('Fecha'),
				const SizedBox(height: 8),
				_selectorButton(
				  icon: Icons.calendar_month_outlined,
				  text: _formattedDate(context, _selectedDate),
				  onPressed: _pickDate,
				),
				const SizedBox(height: 14),
				_inputSectionLabel('Hora'),
				const SizedBox(height: 8),
				_selectorButton(
				  icon: Icons.schedule_outlined,
				  text: _formattedTime(context, _selectedTime),
				  onPressed: _pickTime,
				),
				const SizedBox(height: 14),
				TextFormField(
				  controller: _peopleController,
				  keyboardType: TextInputType.number,
				  validator: (value) {
					final parsed = int.tryParse((value ?? '').trim());
					if (value == null || value.trim().isEmpty) {
					  return 'Introduce el número de personas';
					}
					if (parsed == null || parsed <= 0) {
					  return 'Introduce un número válido';
					}
					if (parsed > 20) {
					  return 'Máximo 20 personas por reserva';
					}
					return null;
				  },
				  decoration: InputDecoration(
					labelText: 'Personas',
					prefixIcon: const Icon(Icons.people_outline),
					border: OutlineInputBorder(
					  borderRadius: BorderRadius.circular(16),
					),
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
					onPressed: _isCreatingReservation
						? null
						: () => _createReservation(user),
					icon: _isCreatingReservation
						? const SizedBox(
							height: 18,
							width: 18,
							child: CircularProgressIndicator(
							  strokeWidth: 2,
							  color: Colors.white,
							),
						  )
						: const Icon(Icons.event_available_outlined),
					label: const Text('Reservar ahora'),
				  ),
				),
			  ],
			),
		  ),
		),
	  ),
	);
  }

  Widget _inputSectionLabel(String text) {
	return Text(
	  text,
	  style: const TextStyle(fontWeight: FontWeight.w600),
	);
  }

  Widget _selectorButton({
	required IconData icon,
	required String text,
	required VoidCallback onPressed,
  }) {
	return SizedBox(
	  width: double.infinity,
	  child: OutlinedButton.icon(
		onPressed: onPressed,
		icon: Icon(icon),
		label: Align(
		  alignment: Alignment.centerLeft,
		  child: Text(text),
		),
		style: OutlinedButton.styleFrom(
		  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
		  shape: RoundedRectangleBorder(
			borderRadius: BorderRadius.circular(16),
		  ),
		),
	  ),
	);
  }

  Widget _reservationCard(ReservationModel reservation) {
	return Card(
	  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
	  elevation: 2,
	  child: Padding(
		padding: const EdgeInsets.all(14),
		child: Column(
		  crossAxisAlignment: CrossAxisAlignment.start,
		  children: [
			Row(
			  children: [
				Expanded(
				  child: Text(
					_formattedDate(context, reservation.date),
					style: const TextStyle(
					  fontWeight: FontWeight.w600,
					  fontSize: 16,
					),
				  ),
				),
				_statusChip(reservation.status),
			  ],
			),
			const SizedBox(height: 8),
			Text('Hora: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(reservation.date))}'),
			const SizedBox(height: 4),
			Text('Personas: ${reservation.people}'),
		  ],
		),
	  ),
	);
  }

  Widget _buildReservationsTab(UserModel user) {
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
			  const Text(
				'Mis reservas',
				style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
			  ),
			  const SizedBox(height: 8),
			  Text(
				'Aquí puedes ver el estado de todas tus reservas.',
				style: TextStyle(color: Colors.grey.shade700),
			  ),
			  const SizedBox(height: 18),
			  Expanded(
				child: StreamBuilder<List<ReservationModel>>(
				  stream: _reservationService.getReservationsByUser(
					user.restaurantId,
					user.uid,
				  ),
				  builder: (context, snapshot) {
					if (snapshot.hasError) {
					  return Center(
						child: Text('Error cargando reservas: ${snapshot.error}'),
					  );
					}

					if (snapshot.connectionState == ConnectionState.waiting) {
					  return const Center(child: CircularProgressIndicator());
					}

					final filteredReservations =
						[...(snapshot.data ?? <ReservationModel>[])]
						  ..sort((a, b) => a.date.compareTo(b.date));

					if (filteredReservations.isEmpty) {
					  return Center(
						child: Column(
						  mainAxisSize: MainAxisSize.min,
						  children: const [
							Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey),
							SizedBox(height: 8),
							Text('Todavía no tienes reservas creadas'),
						  ],
						),
					  );
					}

					return ListView.separated(
					  itemCount: filteredReservations.length,
					  separatorBuilder: (_, index) => const SizedBox(height: 10),
					  itemBuilder: (context, index) {
						final reservation = filteredReservations[index];
						return _reservationCard(reservation);
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

  Widget _buildCartActionIcon() {
	final totalUnits = _cartUnits();
	return Stack(
	  clipBehavior: Clip.none,
	  children: [
		IconButton(
		  tooltip: 'Carrito',
		  onPressed: () => _tabController.animateTo(3),
		  icon: const Icon(Icons.shopping_cart_outlined),
		),
		if (totalUnits > 0)
		  Positioned(
			right: 4,
			top: 4,
			child: Container(
			  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
			  decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(999),
			  ),
			  child: Text(
				totalUnits > 99 ? '99+' : '$totalUnits',
				style: const TextStyle(
				  color: Colors.redAccent,
				  fontSize: 11,
				  fontWeight: FontWeight.w700,
				),
			  ),
			),
		  ),
	  ],
	);
  }

  Widget _buildCartTab(UserModel user) {
	if (_cartItems.isEmpty) {
	  return Center(
		child: Padding(
		  padding: const EdgeInsets.all(24),
		  child: Column(
			mainAxisSize: MainAxisSize.min,
			children: [
			  const Icon(Icons.remove_shopping_cart_outlined, size: 56, color: Colors.grey),
			  const SizedBox(height: 10),
			  const Text('Tu carrito esta vacio'),
			  const SizedBox(height: 14),
			  ElevatedButton.icon(
				onPressed: () => _tabController.animateTo(0),
				icon: const Icon(Icons.restaurant_menu_outlined),
				label: const Text('Ver menu'),
				style: ElevatedButton.styleFrom(
				  backgroundColor: Colors.redAccent,
				  foregroundColor: Colors.white,
				),
			  ),
			],
		  ),
		),
	  );
	}

	final items = _cartItems.values.toList();
	return Column(
	  children: [
		Padding(
		  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
		  child: Card(
			elevation: 2,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: Padding(
			  padding: const EdgeInsets.all(14),
			  child: Row(
				children: [
				  Expanded(
					child: Text(
					  '${_cartUnits()} platos en el carrito',
					  style: const TextStyle(fontWeight: FontWeight.w600),
					),
				  ),
				  Text(
					'${_cartTotal().toStringAsFixed(2)} EUR',
					style: const TextStyle(
					  fontWeight: FontWeight.bold,
					  color: Colors.redAccent,
					),
				  ),
				],
			  ),
			),
		  ),
		),
		Expanded(
		  child: ListView.separated(
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
			itemCount: items.length,
			separatorBuilder: (_, index) => const SizedBox(height: 10),
			itemBuilder: (context, index) {
			  final item = items[index];
			  return Card(
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
				elevation: 2,
				child: Padding(
				  padding: const EdgeInsets.all(12),
				  child: Row(
					children: [
					  ClipRRect(
						borderRadius: BorderRadius.circular(10),
						child: SizedBox(
						  width: 56,
						  height: 56,
						  child: item.menu.imageUrl.isNotEmpty
							  ? Image.network(
								  item.menu.imageUrl,
								  fit: BoxFit.cover,
								  errorBuilder: (_, error, stackTrace) => Container(
									color: Colors.grey.shade200,
									child: const Icon(Icons.fastfood, color: Colors.grey),
								  ),
								)
							  : Container(
								  color: Colors.grey.shade200,
								  child: const Icon(Icons.fastfood, color: Colors.grey),
								),
						),
					  ),
					  const SizedBox(width: 10),
					  Expanded(
						child: Column(
						  crossAxisAlignment: CrossAxisAlignment.start,
						  children: [
							Text(
							  item.menu.name,
							  style: const TextStyle(fontWeight: FontWeight.w600),
							),
							const SizedBox(height: 4),
							Text('${item.menu.price.toStringAsFixed(2)} EUR'),
						  ],
						),
					  ),
					  Row(
						mainAxisSize: MainAxisSize.min,
						children: [
						  IconButton(
							onPressed: () => _decreaseCartItem(item.menu.id),
							icon: const Icon(Icons.remove_circle_outline),
						  ),
						  Text('${item.quantity}'),
						  IconButton(
							onPressed: () => _increaseCartItem(item.menu.id),
							icon: const Icon(Icons.add_circle_outline),
						  ),
						],
					  ),
					],
				  ),
				),
			  );
			},
		  ),
		),
		Padding(
		  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
		  child: SizedBox(
			width: double.infinity,
			height: 52,
			child: ElevatedButton.icon(
			  onPressed: _isCreatingOrder ? null : () => _createOrder(user),
			  icon: _isCreatingOrder
				  ? const SizedBox(
					  height: 18,
					  width: 18,
					  child: CircularProgressIndicator(
						strokeWidth: 2,
						color: Colors.white,
					  ),
					)
				  : const Icon(Icons.shopping_bag_outlined),
			  label: const Text('Hacer pedido'),
			  style: ElevatedButton.styleFrom(
				backgroundColor: Colors.redAccent,
				foregroundColor: Colors.white,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			  ),
			),
		  ),
		),
	  ],
	);
  }

  String _orderStatusLabel(String status) {
	switch (status) {
	  case OrderModel.statusConfirmed:
		return 'Confirmado';
	  case OrderModel.statusPreparing:
		return 'En preparacion';
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
	Color background;
	Color foreground;

	switch (status) {
	  case OrderModel.statusConfirmed:
		background = Colors.blue.withValues(alpha: 0.12);
		foreground = Colors.blue.shade700;
		break;
	  case OrderModel.statusPreparing:
		background = Colors.deepPurple.withValues(alpha: 0.12);
		foreground = Colors.deepPurple.shade700;
		break;
	  case OrderModel.statusDelivered:
		background = Colors.green.withValues(alpha: 0.12);
		foreground = Colors.green.shade700;
		break;
	  case OrderModel.statusCanceled:
		background = Colors.red.withValues(alpha: 0.12);
		foreground = Colors.red.shade700;
		break;
	  case OrderModel.statusPending:
	  default:
		background = Colors.orange.withValues(alpha: 0.12);
		foreground = Colors.orange.shade800;
		break;
	}

	return Chip(
	  backgroundColor: background,
	  label: Text(
		_orderStatusLabel(status),
		style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
	  ),
	);
  }

  Widget _buildOrdersTab(UserModel user) {
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
			  const Text(
				'Mis pedidos',
				style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
			  ),
			  const SizedBox(height: 8),
			  Text(
				'Revisa el estado de tus pedidos en tiempo real.',
				style: TextStyle(color: Colors.grey.shade700),
			  ),
			  const SizedBox(height: 18),
			  Expanded(
				child: StreamBuilder<List<OrderModel>>(
				  stream: _orderService.getOrdersByUser(user.restaurantId, user.uid),
				  builder: (context, snapshot) {
					if (snapshot.hasError) {
					  return Center(
						child: Text('Error cargando pedidos: ${snapshot.error}'),
					  );
					}

					if (snapshot.connectionState == ConnectionState.waiting) {
					  return const Center(child: CircularProgressIndicator());
					}

					final orders = snapshot.data ?? <OrderModel>[];
					if (orders.isEmpty) {
					  return Center(
						child: Column(
						  mainAxisSize: MainAxisSize.min,
						  children: const [
							Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey),
							SizedBox(height: 8),
							Text('Todavia no tienes pedidos creados'),
						  ],
						),
					  );
					}

					return ListView.separated(
					  itemCount: orders.length,
					  separatorBuilder: (_, index) => const SizedBox(height: 10),
					  itemBuilder: (context, index) {
						final order = orders[index];
						final totalItems = order.items.fold<int>(
						  0,
						  (acc, item) => acc + item.quantity,
						);

						return Card(
						  shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(16),
						  ),
						  elevation: 2,
						  child: Padding(
							padding: const EdgeInsets.all(14),
							child: Column(
							  crossAxisAlignment: CrossAxisAlignment.start,
							  children: [
								Row(
								  children: [
									Expanded(
									  child: Text(
										'Pedido ${order.id.substring(0, 6).toUpperCase()}',
										style: const TextStyle(
										  fontWeight: FontWeight.w700,
										),
									  ),
									),
									_orderStatusChip(order.status),
								  ],
								),
								const SizedBox(height: 8),
								Text(
								  'Fecha: ${_formattedDate(context, order.createdAt)}',
								),
								const SizedBox(height: 2),
								Text(
								  'Platos: $totalItems',
								),
								const SizedBox(height: 2),
								Text(
								  'Total: ${order.total.toStringAsFixed(2)} EUR',
								  style: const TextStyle(fontWeight: FontWeight.w600),
								),
							  ],
							),
						  ),
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

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  backgroundColor: const Color(0xFFF5F6FA),
	  appBar: AppBar(
		title: const Text('Menú'),
		backgroundColor: Colors.redAccent,
		foregroundColor: Colors.white,
		elevation: 0,
		actions: [
		  _buildCartActionIcon(),
		  IconButton(
			tooltip: 'Cerrar sesión',
			onPressed: _confirmLogout,
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
			Tab(icon: Icon(Icons.restaurant_menu_outlined), text: 'Menú'),
			Tab(icon: Icon(Icons.event_available_outlined), text: 'Reservar'),
			Tab(icon: Icon(Icons.event_note_outlined), text: 'Mis reservas'),
			Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Carrito'),
			Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Mis pedidos'),
		  ],
		),
	  ),
	  body: FutureBuilder<UserModel?>(
		future: _currentUserFuture,
		builder: (context, userSnapshot) {
		  if (userSnapshot.hasError) {
			return Center(child: Text('Error cargando usuario: ${userSnapshot.error}'));
		  }

		  if (userSnapshot.connectionState == ConnectionState.waiting) {
			return const Center(child: CircularProgressIndicator());
		  }

		  final user = userSnapshot.data;
		  if (user == null) {
			return const Center(child: Text('Error cargando usuario'));
		  }

		  if (user.restaurantId.isEmpty) {
			return const Center(child: Text('No hay restaurante asignado.'));
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
					  _buildMenuTab(user),
					  _buildReservationTab(user),
					  _buildReservationsTab(user),
					  _buildCartTab(user),
					  _buildOrdersTab(user),
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

class _CartItem {
  final MenuModel menu;
  final int quantity;

  const _CartItem({
	required this.menu,
	required this.quantity,
  });

  _CartItem copyWith({
	MenuModel? menu,
	int? quantity,
  }) {
	return _CartItem(
	  menu: menu ?? this.menu,
	  quantity: quantity ?? this.quantity,
	);
  }
}



