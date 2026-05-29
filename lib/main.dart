import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyAUfxtBXLobTo0oMevN6dvA3eyvfO1_6XI",
  authDomain: "hallaqdz.firebaseapp.com",
  projectId: "hallaqdz",
  storageBucket: "hallaqdz.firebasestorage.app",
  messagingSenderId: "668361410723",
  appId: "1:668361410723:web:6acb6e937af397bb19d716",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const HallaqDZApp());
}

class HallaqDZApp extends StatefulWidget {
  const HallaqDZApp({super.key});

  @override
  State<HallaqDZApp> createState() => _HallaqDZAppState();
}

class _HallaqDZAppState extends State<HallaqDZApp> {
  bool isArabic = true;

  void toggleLanguage() {
    setState(() {
      isArabic = !isArabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hallaq DZ',
      debugShowCheckedModeBanner: false,
      locale: Locale(isArabic ? 'ar' : 'fr'),
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFC5A028),
          surface: Color(0xFF121212),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage),
    );
  }
}

// ==========================================
// 1. شاشة تسجيل الدخول
// ==========================================
class AuthScreen extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;

  const AuthScreen(
      {super.key, required this.isArabic, required this.onLanguageToggle});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool isLogin = true;
  String role = 'Customer';
  String barberType = 'Fixed';

  void _submitAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isArabic
                ? "كمّل كل الخانات"
                : "Remplissez tous les champs")),
      );
      return;
    }
    if (!isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isArabic
                ? "كلمة السر ما تطابقتش ❌"
                : "Mots de passe différents ❌")),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isArabic
                ? "كلمة السر قصيرة، 6 أحرف على الأقل ❌"
                : "Minimum 6 caractères ❌")),
      );
      return;
    }

    try {
      if (isLogin) {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _navigateBasedOnRole(userCredential.user!.uid);
      } else {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': role,
          'barberType': role == 'Barber' ? barberType : null,
          'rating': 5.0,
          'earnings': 0,
          'totalBookings': 0,
          'available': true,
          'services': role == 'Barber'
              ? [
                  {'name': 'haircut', 'price': 300},
                  {'name': 'beard', 'price': 200},
                  {'name': 'haircutBeard', 'price': 450},
                ]
              : [],
        });

        _navigateBasedOnRole(userCredential.user!.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _navigateBasedOnRole(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      String userRole = userDoc.get('role');
      if (userRole == 'Barber') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BarberDashboard(isArabic: widget.isArabic),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDashboard(isArabic: widget.isArabic),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var txt = widget.isArabic ? _arStrings : _frStrings;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hallaq DZ 💈',
          style:
              TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: widget.onLanguageToggle,
            child: Text(
              widget.isArabic ? "Français" : "العربية",
              style: const TextStyle(color: Color(0xFFD4AF37)),
            ),
          )
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.content_cut, size: 80, color: Color(0xFFD4AF37)),
              const SizedBox(height: 20),
              Text(
                isLogin ? txt['login']! : txt['register']!,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // اختيار نوع الحساب
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => role = 'Customer'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: role == 'Customer'
                              ? const Color(0xFFD4AF37)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '👤 ${txt['role_customer']!}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: role == 'Customer'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => role = 'Barber'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: role == 'Barber'
                              ? const Color(0xFFD4AF37)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '✂️ ${txt['role_barber']!}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                role == 'Barber' ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // نوع الحلاق
              if (role == 'Barber') ...[
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => barberType = 'Fixed'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: barberType == 'Fixed'
                                ? const Color(0xFFD4AF37)
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '🏪 ${txt['type_fixed']!}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: barberType == 'Fixed'
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => barberType = 'Mobile'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: barberType == 'Mobile'
                                ? const Color(0xFFD4AF37)
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '🚗 ${txt['type_mobile']!}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: barberType == 'Mobile'
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],

              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: txt['name'],
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: txt['email'],
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: txt['password'],
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              if (!isLogin) ...[
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: txt['confirm_password'],
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _submitAuth,
                child: Text(
                  isLogin ? txt['login']! : txt['register']!,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? txt['switch_register']! : txt['switch_login']!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. واجهة الزبون
// ==========================================
class CustomerDashboard extends StatefulWidget {
  final bool isArabic;
  const CustomerDashboard({super.key, required this.isArabic});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    var txt = widget.isArabic ? _arStrings : _frStrings;
    return Scaffold(
      appBar: AppBar(
        title: Text(txt['customer_title']!),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HallaqDZApp()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // فيلتر
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Fixed', 'Mobile'].map((filter) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFilter == filter
                        ? const Color(0xFFD4AF37)
                        : Colors.grey[800],
                  ),
                  onPressed: () => setState(() => selectedFilter = filter),
                  child: Text(
                    filter == 'All'
                        ? txt['filter_all']!
                        : filter == 'Fixed'
                            ? txt['type_fixed']!
                            : txt['type_mobile']!,
                    style: TextStyle(
                      color: selectedFilter == filter
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // قائمة الحلاقين
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Barber')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var barbers = snapshot.data!.docs.where((doc) {
                  if (selectedFilter == 'All') return true;
                  return doc['barberType'] == selectedFilter;
                }).toList();

                if (barbers.isEmpty) {
                  return Center(
                    child: Text(
                      widget.isArabic
                          ? "💈 ما كاش حلاق مسجل بعد"
                          : "💈 Aucun coiffeur inscrit",
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: barbers.length,
                  itemBuilder: (context, index) {
                    var barber = barbers[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD4AF37),
                          child: Icon(
                            barber['barberType'] == 'Fixed'
                                ? Icons.store
                                : Icons.electric_car,
                            color: Colors.black,
                          ),
                        ),
                        title: Text(
                          barber['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("⭐ ${barber['rating']}"),
                            Text(
                              barber['barberType'] == 'Fixed'
                                  ? '🏪 ${txt['type_fixed']!}'
                                  : '🚗 ${txt['type_mobile']!}',
                              style: const TextStyle(color: Color(0xFFD4AF37)),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                          ),
                          onPressed: () => _bookAppointment(barber),
                          child: Text(
                            txt['book']!,
                            style: const TextStyle(color: Colors.black),
                          ),
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
    );
  }

  void _bookAppointment(DocumentSnapshot barber) {
    String selectedTime = '14:00';
    String selectedService = 'haircut';
    var txt = widget.isArabic ? _arStrings : _frStrings;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.isArabic ? 'حجز عند' : 'Réserver chez'}: ${barber['name']}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // اختيار الخدمة
                  Text(widget.isArabic ? "الخدمة:" : "Service:",
                      style: const TextStyle(color: Color(0xFFD4AF37))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['haircut', 'beard', 'haircutBeard'].map((svc) {
                      Map<String, String> svcNames = {
                        'haircut': widget.isArabic ? 'قصة شعر' : 'Coupe',
                        'beard': widget.isArabic ? 'لحية' : 'Barbe',
                        'haircutBeard':
                            widget.isArabic ? 'قصة + لحية' : 'Coupe + Barbe',
                      };
                      return ChoiceChip(
                        label: Text(svcNames[svc]!),
                        selected: selectedService == svc,
                        selectedColor: const Color(0xFFD4AF37),
                        onSelected: (_) =>
                            setModalState(() => selectedService = svc),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // اختيار الوقت
                  Text(widget.isArabic ? "الوقت:" : "Heure:",
                      style: const TextStyle(color: Color(0xFFD4AF37))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      '09:00',
                      '10:00',
                      '11:00',
                      '14:00',
                      '15:00',
                      '16:00',
                      '17:00',
                      '18:00'
                    ].map((time) {
                      return ChoiceChip(
                        label: Text(time),
                        selected: selectedTime == time,
                        selectedColor: const Color(0xFFD4AF37),
                        onSelected: (_) =>
                            setModalState(() => selectedTime = time),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .add({
                        'barberId': barber.id,
                        'barberName': barber['name'],
                        'customerId': FirebaseAuth.instance.currentUser!.uid,
                        'service': selectedService,
                        'timeSlot': selectedTime,
                        'status': 'pending',
                        'date': DateTime.now().toString().split(' ')[0],
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.isArabic
                              ? "✅ تم إرسال طلب الحجز!"
                              : "✅ Demande envoyée!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text(
                      widget.isArabic ? "تأكيد الحجز" : "Confirmer",
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 3. واجهة الحلاق
// ==========================================
class BarberDashboard extends StatelessWidget {
  final bool isArabic;
  const BarberDashboard({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    var txt = isArabic ? _arStrings : _frStrings;
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(txt['barber_title']!),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HallaqDZApp()),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var data = snapshot.data!;
          return Column(
            children: [
              // إحصائيات
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(txt['rating']!, "⭐ ${data['rating']}"),
                    _statItem(txt['earnings']!, "${data['earnings']} DA"),
                    _statItem(
                        txt['total_bookings']!, "${data['totalBookings']}"),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment:
                      isArabic ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    txt['requests']!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // طلبات الحجز
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('barberId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, bSnapshot) {
                    if (!bSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var bookings = bSnapshot.data!.docs;
                    if (bookings.isEmpty) {
                      return Center(
                        child: Text(
                          isArabic
                              ? "📭 ما كاش طلبات بعد"
                              : "📭 Aucune demande",
                          style: const TextStyle(color: Colors.white60),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, bIndex) {
                        var booking = bookings[bIndex];
                        Map<String, String> svcNames = {
                          'haircut': isArabic ? 'قصة شعر' : 'Coupe',
                          'beard': isArabic ? 'لحية' : 'Barbe',
                          'haircutBeard':
                              isArabic ? 'قصة + لحية' : 'Coupe + Barbe',
                        };
                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(
                              "${svcNames[booking['service']] ?? booking['service']} - ${booking['timeSlot']}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${isArabic ? 'الحالة' : 'Statut'}: ${booking['status']}",
                              style: TextStyle(
                                color: booking['status'] == 'pending'
                                    ? Colors.orange
                                    : booking['status'] == 'accepted'
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                            trailing: booking['status'] == 'pending'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        onPressed: () {
                                          booking.reference
                                              .update({'status': 'accepted'});
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel,
                                            color: Colors.red),
                                        onPressed: () {
                                          booking.reference
                                              .update({'status': 'rejected'});
                                        },
                                      ),
                                    ],
                                  )
                                : Icon(
                                    booking['status'] == 'accepted'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: booking['status'] == 'accepted'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 4. الترجمة
// ==========================================
const Map<String, String> _arStrings = {
  'login': 'تسجيل الدخول',
  'register': 'إنشاء حساب جديد',
  'name': 'الاسم الكامل',
  'email': 'البريد الإلكتروني',
  'password': 'كلمة المرور',
  'confirm_password': 'تأكيد كلمة المرور',
  'role_customer': 'زبون',
  'role_barber': 'حلاق',
  'type_fixed': 'محل ثابت',
  'type_mobile': 'حلاق متنقل',
  'switch_register': 'ما عندكش حساب؟ سجل هنا',
  'switch_login': 'عندك حساب؟ دخل',
  'customer_title': 'ابحث على حلاق',
  'barber_title': 'لوحة تحكم الحلاق',
  'filter_all': 'الكل',
  'rating': 'التقييم',
  'book': 'احجز',
  'earnings': 'المداخيل',
  'total_bookings': 'الحجوزات',
  'requests': 'طلبات الحجز',
};

const Map<String, String> _frStrings = {
  'login': 'Se Connecter',
  'register': 'Créer un compte',
  'name': 'Nom Complet',
  'email': 'E-mail',
  'password': 'Mot de passe',
  'confirm_password': 'Confirmer mot de passe',
  'role_customer': 'Client',
  'role_barber': 'Coiffeur',
  'type_fixed': 'Salon Fixe',
  'type_mobile': 'Coiffeur Mobile',
  'switch_register': 'Pas de compte? Inscrivez-vous',
  'switch_login': 'Déjà inscrit? Connectez-vous',
  'customer_title': 'Trouver un Coiffeur',
  'barber_title': 'Tableau de Bord',
  'filter_all': 'Tout',
  'rating': 'Note',
  'book': 'Réserver',
  'earnings': 'Gains',
  'total_bookings': 'Réservations',
  'requests': 'Demandes',
};
