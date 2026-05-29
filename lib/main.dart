import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "YOUR_API_KEY",
  authDomain: "hallaqdz.firebaseapp.com",
  projectId: "hallaqdz",
  storageBucket: "hallaqdz.appspot.com",
  messagingSenderId: "668361410723",
  appId: "1:668361410723:web:6acb6e937af397bb19d716",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  runApp(const HallaqDZApp());
}

class HallaqDZApp extends StatelessWidget {
  const HallaqDZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Hallaq DZ",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  bool login = true;
  bool loading = false;

  String role = "Customer";

  double lat = 36.7538;
  double lng = 3.0588;

  Future<void> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
      });

      snack("✅ تم تحديد الموقع");
    } catch (e) {
      snack(e.toString());
    }
  }

  Future<void> submit() async {
    if (email.text.isEmpty || pass.text.isEmpty) {
      snack("❌ أكمل جميع الخانات");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (login) {
        UserCredential cred =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );

        navigate(cred.user!.uid);
      } else {
        UserCredential cred =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection("users")
            .doc(cred.user!.uid)
            .set({
          "uid": cred.user!.uid,
          "name": name.text.trim(),
          "email": email.text.trim(),
          "phone": phone.text.trim(),
          "address": address.text.trim(),
          "role": role,
          "latitude": lat,
          "longitude": lng,
          "available": true,
          "rating": 5.0,
          "createdAt": FieldValue.serverTimestamp(),
          "services": [
            {
              "name": "قصة شعر",
              "price": 300,
            },
            {
              "name": "لحية",
              "price": 200,
            }
          ],
          "shopImages": [],
          "ripCode": "00799999000000000000"
        });

        navigate(cred.user!.uid);
      }
    } catch (e) {
      snack(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> navigate(String uid) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    String role = doc["role"];

    if (role == "Barber") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BarberDashboard(
            uid: uid,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerDashboard(),
        ),
      );
    }
  }

  void snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget field(
    TextEditingController c,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("💈 Hallaq DZ"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.content_cut,
              size: 80,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        login = true;
                      });
                    },
                    child: const Text("دخول"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        login = false;
                      });
                    },
                    child: const Text("تسجيل"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!login) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          role = "Customer";
                        });
                      },
                      child: const Text("زبون"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          role = "Barber";
                        });
                      },
                      child: const Text("حلاق"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              field(name, "الاسم"),
              const SizedBox(height: 10),
              field(phone, "الهاتف"),
              const SizedBox(height: 10),
              field(address, "العنوان"),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: getLocation,
                icon: const Icon(Icons.location_on),
                label: const Text("GPS"),
              ),
              const SizedBox(height: 15),
            ],
            field(email, "Email"),
            const SizedBox(height: 10),
            field(pass, "Password", obscure: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const CircularProgressIndicator()
                  : Text(
                      login ? "تسجيل الدخول" : "إنشاء حساب",
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarberDashboard extends StatefulWidget {
  final String uid;

  const BarberDashboard({
    super.key,
    required this.uid,
  });

  @override
  State<BarberDashboard> createState() => _BarberDashboardState();
}

class _BarberDashboardState extends State<BarberDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة الحلاق"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where(
              "barberId",
              isEqualTo: widget.uid,
            )
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("لا توجد حجوزات"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var b = docs[i];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(b["service"]),
                  subtitle: Text(
                    "${b["date"]} - ${b["timeSlot"]}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          b.reference.update({"status": "accepted"});
                        },
                        icon: const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          b.reference.update({"status": "rejected"});
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
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

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  Future<void> openMap(
    double lat,
    double lng,
  ) async {
    final Uri url = Uri.parse("geo:$lat,$lng?q=$lat,$lng");

    await launchUrl(url);
  }

  Future<void> bookNow(
    DocumentSnapshot barber,
    String service,
    String time,
  ) async {
    final today = DateTime.now().toString().split(" ")[0];

    final existing = await FirebaseFirestore.instance
        .collection("bookings")
        .where(
          "barberId",
          isEqualTo: barber.id,
        )
        .where(
          "date",
          isEqualTo: today,
        )
        .where(
          "timeSlot",
          isEqualTo: time,
        )
        .where(
      "status",
      whereIn: ["pending", "accepted"],
    ).get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "❌ الوقت محجوز اختر وقت آخر",
          ),
        ),
      );

      return;
    }

    await FirebaseFirestore.instance.collection("bookings").add({
      "barberId": barber.id,
      "barberName": barber["name"],
      "customerId": FirebaseAuth.instance.currentUser!.uid,
      "service": service,
      "timeSlot": time,
      "date": today,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "✅ تم الحجز بنجاح",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "صالونات الحلاقة",
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where(
              "role",
              isEqualTo: "Barber",
            )
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var barber = docs[i];

              double lat = barber["latitude"] ?? 0;

              double lng = barber["longitude"] ?? 0;

              List services = barber["services"] ?? [];

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber["name"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        barber["address"] ?? "",
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: services.map<Widget>(
                          (s) {
                            return Chip(
                              label: Text(
                                "${s["name"]} - ${s["price"]} DA",
                              ),
                            );
                          },
                        ).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                openMap(
                                  lat,
                                  lng,
                                );
                              },
                              child: const Text(
                                "GPS",
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                bookNow(
                                  barber,
                                  "قصة شعر",
                                  "10:00",
                                );
                              },
                              child: const Text(
                                "احجز",
                              ),
                            ),
                          ),
                        ],
                      )
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
