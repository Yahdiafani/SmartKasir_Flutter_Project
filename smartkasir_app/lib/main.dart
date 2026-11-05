import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const SmartKasirApp());
}

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.icon,
    this.discount = 0,
  });

  final int id;
  String name;
  String category;
  int price;
  int stock;
  IconData icon;
  int discount;

  int get finalPrice => (price * (100 - discount) / 100).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'iconCode': icon.codePoint,
        'discount': discount,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String,
        price: json['price'] as int,
        stock: json['stock'] as int,
        icon: IconData(
          json['iconCode'] as int,
          fontFamily: 'MaterialIcons',
        ),
        discount: json['discount'] as int? ?? 0,
      );
}

class SaleRecord {
  SaleRecord({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
  });

  final int id;
  final int items;
  final int total;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items,
        'total': total,
        'date': date.toIso8601String(),
      };

  factory SaleRecord.fromJson(Map<String, dynamic> json) => SaleRecord(
        id: json['id'] as int,
        items: json['items'] as int,
        total: json['total'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

class SmartKasirApp extends StatefulWidget {
  const SmartKasirApp({super.key});

  @override
  State<SmartKasirApp> createState() => _SmartKasirAppState();
}

class _SmartKasirAppState extends State<SmartKasirApp> {
  bool _showSplash = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartKasir',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F6A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F7),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F6A),
          brightness: Brightness.dark,
        ),
      ),
      home: _showSplash
          ? const SplashPage()
          : MainShell(
              onThemeChanged: (value) => setState(() => _darkMode = value),
              darkMode: _darkMode,
            ),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF075E54), Color(0xFF0B9B7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              child: Icon(Icons.point_of_sale_rounded,
                  size: 52, color: Color(0xFF087F6A)),
            ),
            SizedBox(height: 22),
            Text(
              'SmartKasir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kelola toko lebih mudah',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.onThemeChanged,
    required this.darkMode,
  });

  final ValueChanged<bool> onThemeChanged;
  final bool darkMode;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _loading = true;
  String _storeName = 'Toko SmartKasir';
  List<Product> _products = [];
  List<SaleRecord> _sales = [];
  final Map<int, int> _cart = {};

  static const _categories = ['Semua', 'Makanan', 'Minuman', 'Snack'];
  String _category = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<Product> _seedProducts() => [
        Product(id: 1, name: 'Kopi Susu Gula Aren', category: 'Minuman',
            price: 18000, stock: 12, icon: Icons.coffee_rounded, discount: 20),
        Product(id: 2, name: 'Roti Cokelat', category: 'Makanan',
            price: 12000, stock: 8, icon: Icons.bakery_dining_rounded),
        Product(id: 3, name: 'Keripik Pisang', category: 'Snack',
            price: 10000, stock: 4, icon: Icons.cookie_rounded),
        Product(id: 4, name: 'Es Teh Lemon', category: 'Minuman',
            price: 10000, stock: 0, icon: Icons.local_cafe_rounded),
        Product(id: 5, name: 'Nasi Ayam', category: 'Makanan',
            price: 22000, stock: 15, icon: Icons.lunch_dining_rounded),
        Product(id: 6, name: 'Kentang Goreng', category: 'Snack',
            price: 15000, stock: 6, icon: Icons.fastfood_rounded),
      ];

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final productString = prefs.getString('products');
    final saleString = prefs.getString('sales');
    if (productString == null) {
      _products = _seedProducts();
    } else {
      _products = (jsonDecode(productString) as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (saleString != null) {
      _sales = (jsonDecode(saleString) as List)
          .map((item) => SaleRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    _storeName = prefs.getString('storeName') ?? 'Toko SmartKasir';
    await _saveProducts();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'products',
      jsonEncode(_products.map((product) => product.toJson()).toList()),
    );
  }

  Future<void> _saveSales() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sales',
      jsonEncode(_sales.map((sale) => sale.toJson()).toList()),
    );
  }

  Future<void> _saveStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeName', _storeName);
  }

  int get _cartCount => _cart.values.fold(0, (sum, value) => sum + value);
  int get _cartTotal => _cart.entries.fold(0, (sum, entry) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        return sum + product.finalPrice * entry.value;
      });

  Future<void> _addToCart(Product product) async {
    if (product.stock <= (_cart[product.id] ?? 0)) {
      _message('Stok produk tidak mencukupi.');
      return;
    }
    setState(() => _cart[product.id] = (_cart[product.id] ?? 0) + 1);
  }

  void _changeCartQuantity(Product product, int change) {
    final next = (_cart[product.id] ?? 0) + change;
    setState(() {
      if (next <= 0) {
        _cart.remove(product.id);
      } else if (next <= product.stock) {
        _cart[product.id] = next;
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final itemCount = _cartCount;
    final total = _cartTotal;
    setState(() {
      for (final entry in _cart.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        product.stock -= entry.value;
      }
      _sales.insert(
        0,
        SaleRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          items: itemCount,
          total: total,
          date: DateTime.now(),
        ),
      );
      _cart.clear();
    });
    await _saveProducts();
    await _saveSales();
    if (mounted) {
      Navigator.pop(context);
      _message('Transaksi berhasil disimpan.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  void _openCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keranjang', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 14),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('Keranjang masih kosong.'))
                      : ListView(
                          children: _cart.entries.map((entry) {
                            final product = _products.firstWhere((p) => p.id == entry.key);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE0F2ED),
                                child: Icon(product.icon, color: const Color(0xFF087F6A)),
                              ),
                              title: Text(product.name),
                              subtitle: Text('${_rupiah.format(product.finalPrice)} × ${entry.value}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _changeCartQuantity(product, -1);
                                      setSheetState(() {});
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('${entry.value}'),
                                  IconButton(
                                    onPressed: () {
                                      _changeCartQuantity(product, 1);
                                      setSheetState(() {});
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total pembayaran'),
                    Text(_rupiah.format(_cartTotal),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _cart.isEmpty ? null : _checkout,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Selesaikan transaksi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      _dashboard(),
      _transactionPage(),
      _historyPage(),
      _profilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.point_of_sale_rounded, color: Color(0xFF087F6A)),
            const SizedBox(width: 9),
            Text(_storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keranjang',
            onPressed: _openCart,
            icon: Badge(
              isLabelVisible: _cartCount > 0,
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Transaksi'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final visible = _products.where((p) => _category == 'Semua' || p.category == _category).toList();
    final width = MediaQuery.of(context).size.width;
    final columns = width > 950 ? 4 : width > 650 ? 3 : 2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF075E54), Color(0xFF0B9B7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Halo, selamat datang!', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 7),
                    const Text('Kelola penjualan\nlebih praktis.', style: TextStyle(
                      color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 14),
                    Text('${_products.length} produk tersedia',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 76),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _statCard('Total transaksi', '${_sales.length}', Icons.receipt_long)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Produk', '${_products.length}', Icons.inventory_2_outlined)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Katalog produk', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _openCart, icon: const Icon(Icons.shopping_bag_outlined), label: const Text('Keranjang')),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width < 400 ? 0.70 : 0.78,
          ),
          itemBuilder: (context, index) => _productCard(visible[index]),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE0F2ED),
              child: Icon(icon, color: const Color(0xFF087F6A)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Product product) {
    final stockLabel = product.stock == 0
        ? 'Stok habis'
        : product.stock <= 5
            ? 'Stok menipis: ${product.stock}'
            : 'Stok: ${product.stock}';
    final stockColor = product.stock == 0
        ? Colors.red
        : product.stock <= 5
            ? Colors.orange.shade800
            : Colors.green.shade700;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(product.icon, size: 54, color: const Color(0xFF087F6A))),
                    if (product.discount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                          child: Text('PROMO ${product.discount}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(product.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            const SizedBox(height: 5),
            if (product.discount > 0)
              Text(_rupiah.format(product.price),
                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11)),
            Text(_rupiah.format(product.finalPrice),
                style: const TextStyle(color: Color(0xFF087F6A), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(stockLabel, style: TextStyle(color: stockColor, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: product.stock == 0 ? null : () => _addToCart(product),
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Tambah', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Transaksi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Pilih produk dari katalog Beranda, lalu selesaikan pembayaran melalui keranjang.'),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.shopping_bag_outlined)),
            title: const Text('Produk di keranjang'),
            subtitle: Text('$_cartCount item'),
            trailing: Text(_rupiah.format(_cartTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _openCart, icon: const Icon(Icons.shopping_cart_checkout), label: const Text('Buka keranjang')),
        const SizedBox(height: 24),
        Text('Cara menggunakan', style: Theme.of(context).textTheme.titleMedium),
        const ListTile(leading: Icon(Icons.looks_one_outlined), title: Text('Pilih Beranda dan tentukan produk.')),
        const ListTile(leading: Icon(Icons.looks_two_outlined), title: Text('Tekan tombol Tambah pada produk.')),
        const ListTile(leading: Icon(Icons.looks_3_outlined), title: Text('Periksa jumlah dan total di keranjang.')),
        const ListTile(leading: Icon(Icons.looks_4_outlined), title: Text('Tekan Selesaikan transaksi.')),
      ],
    );
  }

  Widget _historyPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Riwayat transaksi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        if (_sales.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 70),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada transaksi', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Transaksi yang selesai akan muncul di sini.'),
              ],
            ),
          )
        else
          ..._sales.map((sale) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
              title: Text('Transaksi #${sale.id.toString().substring(sale.id.toString().length - 6)}'),
              subtitle: Text('${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(sale.date)} • ${sale.items} item'),
              trailing: Text(_rupiah.format(sale.total),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF087F6A))),
            ),
          )),
      ],
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Profil toko', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFFE0F2ED),
            child: const Icon(Icons.storefront, size: 42, color: Color(0xFF087F6A)),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(_storeName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Nama toko'),
                subtitle: Text(_storeName),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editStoreName,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Mode gelap'),
                value: widget.darkMode,
                onChanged: widget.onThemeChanged,
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Tentang aplikasi'),
                subtitle: Text('SmartKasir • Praktikum Mobile Programming'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('products');
            await prefs.remove('sales');
            await prefs.remove('storeName');
            if (!mounted) return;
            setState(() {
              _products = _seedProducts();
              _sales = [];
              _storeName = 'Toko SmartKasir';
              _cart.clear();
            });
            _saveProducts();
            _message('Data demo berhasil direset.');
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset data demo'),
        ),
      ],
    );
  }

  Future<void> _editStoreName() async {
    final controller = TextEditingController(text: _storeName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah nama toko'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama toko'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      setState(() => _storeName = value);
      await _saveStoreName();
    }
  }
}
