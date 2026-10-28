
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'firebase_options.dart';

// Replace this placeholder with your Supabase publishable key.
// Never put the Xendit Secret API Key in Flutter code.
const String supabasePublishableKey = 'sb_publishable_NRB3AvB6pOXfN3xclfTSDg_L8Hf-CRg';
const String xenditCheckoutEndpoint =
    'https://buskevifxjycrvtzxvtr.supabase.co/functions/v1/create-xendit-checkout';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FoodHubApp());
}

class FoodHubApp extends StatelessWidget {
  const FoodHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'D.C FOODHUB',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFBF5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE86B35),
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class FoodItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final String image;
  final double price;
  final String serving;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.image,
    required this.price,
    required this.serving,
  });

  factory FoodItem.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final fallback = sampleFoods.cast<FoodItem?>().firstWhere(
      (food) => food!.id == id,
      orElse: () => null,
    );

    String getText(String key, String defaultValue) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
      return defaultValue;
    }

    return FoodItem(
      id: id,
      name: getText(
        'name',
        fallback?.name ?? 'Lechon Kawali',
      ),
      category: getText(
        'category',
        fallback?.category ?? 'Dinner',
      ),
      description: getText(
        'description',
        fallback?.description ?? 'Masarap na pagkaing Pinoy.',
      ),
      image: getText(
        'image',
        fallback?.image ?? '',
      ),
      price: (data['price'] as num?)?.toDouble() ??
          fallback?.price ??
          0,
      serving: getText(
        'serving',
        fallback?.serving ?? '1 serving',
      ),
    );
  }
}

const List<FoodItem> sampleFoods = [
  FoodItem(
    id: '1',
    name: 'Sinigang na Baboy',
    category: 'Dinner',
    description: 'Sinigang na baboy na may sariwang gulay.',
    image: 'assets/images/sinigang na baboy.jpg',
    price: 349,
    serving: 'Good for 2',
  ),
  FoodItem(
    id: '2',
    name: 'Laing',
    category: 'Dinner',
    description: 'Laing na gawa sa dahon ng gabi at gata.',
    image: 'assets/images/laing.jpg',
    price: 249,
    serving: 'Good for 2',
  ),
  FoodItem(
    id: '3',
    name: 'Bicol Express',
    category: 'Dinner',
    description: 'Maanghang at creamy na Bicol Express.',
    image: 'assets/images/bicol_express.jpg',
    price: 349,
    serving: 'Good for 2',
  ),
  FoodItem(
    id: '4',
    name: 'Adobong Manok',
    category: 'Lunch',
    description: 'Classic chicken adobo na may toyo at suka.',
    image: 'assets/images/adobong_manok.jpg',
    price: 299,
    serving: 'Good for 2',
  ),
  FoodItem(
    id: '5',
    name: 'Fried Tilapia w/ Salted Egg',
    category: 'Lunch',
    description: 'Crispy fried tilapia na may salted egg.',
    image: 'assets/images/fried_tilapia.jpg',
    price: 279,
    serving: 'Good for 2',
  ),
  FoodItem(
    id: '6',
    name: 'Lechon Kawali',
    category: 'Dinner',
    description: 'Crispy pork belly na may sawsawan.',
    image: 'assets/images/lechon_kawali.jpg',
    price: 499,
    serving: 'Good for 4',
  ),
  FoodItem(
    id: '7',
    name: 'Kare-Kare',
    category: 'Dinner',
    description: 'Filipino peanut stew na may bagoong.',
    image: 'assets/images/kare_kare.jpg',
    price: 499,
    serving: 'Good for 2',
  ),
  FoodItem(
    id: '8',
    name: 'Halo-Halo',
    category: 'Dessert',
    description: 'Refreshing Filipino dessert na may yelo at gatas.',
    image: 'assets/images/halo_halo.jpg',
    price: 149,
    serving: '1 serving',
  ),
  FoodItem(
    id: '9',
    name: 'Sago with Gulaman',
    category: 'Drinks',
    description: 'Matamis at malamig na sago gulaman.',
    image: 'assets/images/sago_gulaman.jpg',
    price: 49,
    serving: '1 cup',
  ),
  FoodItem(
    id: '10',
    name: 'Leche Flan',
    category: 'Dessert',
    description: 'Creamy Filipino leche flan.',
    image: 'assets/images/leche_flan.jpg',
    price: 99,
    serving: '1 serving',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';
  String searchText = '';

  final Map<String, int> cart = {};
  final Map<String, FoodItem> cartFoods = {};
  bool checkoutLoading = false;

  final List<String> categories = [
    'All',
    'Healthy',
    'Salad',
    'Breakfast',
    'Snack',
    'Lunch',
    'Dinner',
    'Dessert',
    'Drinks',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void addToCart(FoodItem food) {
    setState(() {
      cart[food.id] = (cart[food.id] ?? 0) + 1;
      cartFoods[food.id] = food;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} added to cart!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE86B35),
      ),
    );
  }

  void increaseQuantity(FoodItem food) {
    setState(() {
      cart[food.id] = (cart[food.id] ?? 0) + 1;
      cartFoods[food.id] = food;
    });
  }

  void decreaseQuantity(FoodItem food) {
    setState(() {
      final quantity = cart[food.id] ?? 0;

      if (quantity <= 1) {
        cart.remove(food.id);
        cartFoods.remove(food.id);
      } else {
        cart[food.id] = quantity - 1;
      }
    });
  }

  List<FoodItem> filterFoods(List<FoodItem> foods) {
    return foods.where((food) {
      final matchesCategory = selectedCategory == 'All' ||
          food.category.toLowerCase() ==
              selectedCategory.toLowerCase();

      final matchesSearch = food.name
          .toLowerCase()
          .contains(searchText.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get cartCount =>
      cart.values.fold(0, (total, quantity) => total + quantity);

  String peso(double amount) => '₱${amount.toStringAsFixed(2)}';

  Future<void> startXenditCheckout(
    double amount, {
    required VoidCallback refreshCartSheet,
  }) async {
    if (checkoutLoading || !mounted) return;
    setState(() => checkoutLoading = true);
    refreshCartSheet();

    try {
     if (supabasePublishableKey.trim().isEmpty ||
    supabasePublishableKey == 'YOUR_SUPABASE_PUBLISHABLE_KEY') {
  throw Exception(
    'Ilagay muna ang Supabase publishable key sa main.dart.',
  );
}
      if (!amount.isFinite || amount < 1 || amount > 100000) {
        throw Exception('Invalid checkout amount.');
      }

      final response = await http.post(
        Uri.parse(xenditCheckoutEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'apikey': supabasePublishableKey,
          'Authorization': 'Bearer $supabasePublishableKey',
        },
        body: jsonEncode({'amount': amount}),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic> responseData;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Unexpected response format');
        }
        responseData = decoded;
      } on FormatException {
        throw Exception('Hindi maintindihan ang response ng checkout server (HTTP ${response.statusCode}).');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final serverMessage = responseData['error']?.toString();
        throw Exception(serverMessage != null && serverMessage.isNotEmpty
            ? serverMessage
            : 'Checkout request failed (HTTP ${response.statusCode}).');
      }

      final invoiceUrl = responseData['invoice_url'];
      if (invoiceUrl is! String || invoiceUrl.trim().isEmpty) {
        throw Exception('Walang valid invoice_url sa server response.');
      }
      final invoiceUri = Uri.tryParse(invoiceUrl);
      if (invoiceUri == null || invoiceUri.scheme != 'https' || invoiceUri.host.isEmpty) {
        throw Exception('Invalid invoice URL mula sa checkout server.');
      }

      final launched = await launchUrl(invoiceUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Nagawa ang invoice pero hindi nabuksan ang payment page. Payagan ang pop-ups o buksan ang invoice link sa browser.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nabuksan ang Xendit payment page. Hindi pa kumpirmadong bayad ang order.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: ${error.toString().replaceFirst('Exception: ', '')}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('May hindi inaasahang error sa checkout. Subukan muli.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => checkoutLoading = false);
        refreshCartSheet();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF5),
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'D.C FOODHUB',
              style: TextStyle(
                color: Color(0xFFE86B35),
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            Text(
              'EVERY BITE TELLS A STORY.',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Shopping cart',
              onPressed: showCart,
              icon: Badge(
                label: Text('$cartCount'),
                isLabelVisible: cartCount > 0,
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Hindi ma-load ang Firestore menu.\n'
                    'Check ang internet at Firebase setup.\n\n'
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final List<FoodItem> foods =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty
                    ? snapshot.data!.docs
                        .where((doc) =>
                            doc.data()['available'] != false)
                        .map((doc) =>
                            FoodItem.fromMap(doc.id, doc.data()))
                        .toList()
                    : sampleFoods;

            final filteredFoods = filterFoods(foods);
            final picks = filteredFoods.take(6).toList();

            // Use the real food names and keep the original menu order.
            final newMenu = filteredFoods.reversed.take(4).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE7D6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Masarap na pagkain,',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'para sa bawat kwentuhan.',
                              style: TextStyle(
                                fontSize: 19,
                                color: Color(0xFFE86B35),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your favorite Filipino meals in one place.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() => searchText = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search food...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchText.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() => searchText = '');
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Explore Categories',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 43,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected =
                                category == selectedCategory;

                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                              selectedColor: const Color(0xFFFFD7BD),
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: selected
                                    ? const Color(0xFFB84C20)
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 27),
                      sectionTitle("Today's Pick", () {
                        setState(() {
                          selectedCategory = 'All';
                          searchText = '';
                          searchController.clear();
                        });
                      }),
                      const SizedBox(height: 14),
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE86B35),
                          ),
                        )
                      else if (picks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Walang food na nakita.'),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns =
                                constraints.maxWidth >= 750 ? 3 : 2;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: picks.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 13,
                                mainAxisSpacing: 13,
                                mainAxisExtent: 290,
                              ),
                              itemBuilder: (context, index) =>
                                  foodCard(picks[index]),
                            );
                          },
                        ),
                      const SizedBox(height: 30),
                      sectionTitle('New Menu', () {
                        setState(() {
                          selectedCategory = 'All';
                          searchText = '';
                          searchController.clear();
                        });
                      }),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 245,
                        child: newMenu.isEmpty
                            ? const Center(
                                child: Text('Walang available na pagkain.'),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: newMenu.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 13),
                                itemBuilder: (context, index) {
                                  return SizedBox(
                                    width: 175,
                                    child: foodCard(newMenu[index]),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'D.C FOODHUB • Made with love',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget sectionTitle(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(color: Color(0xFFE86B35)),
          ),
        ),
      ],
    );
  }

  Widget foodImage(FoodItem food) {
    if (food.image.isEmpty) {
      return Container(
        color: const Color(0xFFFFE7D6),
        alignment: Alignment.center,
        child: const Icon(
          Icons.restaurant,
          size: 45,
          color: Color(0xFFE86B35),
        ),
      );
    }

    if (food.image.startsWith('assets/')) {
      return Image.asset(
        food.image,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => imageError(),
      );
    }

    return Image.network(
      food.image,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE86B35),
          ),
        );
      },
      errorBuilder: (_, __, ___) => imageError(),
    );
  }

  Widget imageError() {
    return Container(
      color: const Color(0xFFFFE7D6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant,
        color: Color(0xFFE86B35),
        size: 42,
      ),
    );
  }

  Widget foodCard(FoodItem food) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E8E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: foodImage(food),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Food description',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => showFoodDescription(food),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Color(0xFFE86B35),
                        size: 21,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  food.serving,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        peso(food.price),
                        style: const TextStyle(
                          color: Color(0xFFE86B35),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => addToCart(food),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE86B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(9),
                        minimumSize: Size.zero,
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showFoodDescription(FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBF5),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Food Description',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 210,
                      child: foodImage(food),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF29231F),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7D6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      food.category,
                      style: const TextStyle(
                        color: Color(0xFFB84C20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'About this food',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    food.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFFE86B35),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          food.serving,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      Text(
                        peso(food.price),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE86B35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        addToCart(food);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE86B35),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            final items = cartFoods.values
                .where((food) => (cart[food.id] ?? 0) > 0)
                .toList();

            final total = items.fold<double>(
              0,
              (sum, food) =>
                  sum + food.price * (cart[food.id] ?? 0),
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFFE86B35),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'My Cart',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 58,
                                      color: Colors.black26,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Your cart is empty.',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Add your favorite food first!',
                                      style: TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final food = items[index];
                                  final quantity = cart[food.id] ?? 0;

                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    leading: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 55,
                                        height: 55,
                                        child: foodImage(food),
                                      ),
                                    ),
                                    title: Text(
                                      food.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${peso(food.price)} each',
                                      style: const TextStyle(
                                        color: Color(0xFFE86B35),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Remove one',
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () {
                                            decreaseQuantity(food);
                                            updateSheet(() {});
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        ),
                                        Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Add one',
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () {
                                            increaseQuantity(food);
                                            updateSheet(() {});
                                          },
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFFE86B35),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            peso(total),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE86B35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: items.isEmpty || checkoutLoading
                              ? null
                              : () async {
                                  await startXenditCheckout(
                                    total,
                                    refreshCartSheet: () => updateSheet(() {}),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE86B35),
                            foregroundColor: Colors.white,
                          ),
                          child: checkoutLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Proceed to Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
