import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  void toggleLanguage() => setState(() => isArabic = !isArabic);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hallaq DZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFC5A028),
          surface: Color(0xFF121212),
        ),
      ),
      home: AuthScreen(isArabic: isArabic, onLanguageToggle: toggleLanguage),
    );
  }
}

// ==========================================
// AUTH SCREEN
// ==========================================
class AuthScreen extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onLanguageToggle;
  const AuthScreen({super.key, required this.isArabic, required this.onLanguageToggle});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool isLogin = true;
  String role = 'Customer';
  String barberType = 'Fixed';
  bool isLoading = false;
  double? barberLat;
  double? barberLng;
  bool locating = false;

  Future<void> _getLocation() async {
    setState(() => locating = true);
    try {
      LocationPermission perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) { setState(() => locating = false); return; }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { barberLat = pos.latitude; barberLng = pos.longitude; locating = false; });
    } catch (e) { setState(() => locating = false); }
  }

  void _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) { _snack(widget.isArabic ? "ÙƒÙ…Ù‘Ù„ ÙƒÙ„ Ø§Ù„Ø®Ø§Ù†Ø§Øª âŒ" : "Remplissez tous les champs âŒ"); return; }
    if (!isLogin && _passCtrl.text != _confirmCtrl.text) { _snack(widget.isArabic ? "ÙƒÙ„Ù…Ø© Ø§Ù„Ø³Ø± Ù…Ø§ ØªØ·Ø§Ø¨Ù‚ØªØ´ âŒ" : "Mots de passe diffÃ©rents âŒ"); return; }
    if (_passCtrl.text.length < 6) { _snack(widget.isArabic ? "ÙƒÙ„Ù…Ø© Ø§Ù„Ø³Ø± Ù‚ØµÙŠØ±Ø© âŒ" : "Minimum 6 caractÃ¨res âŒ"); return; }

    setState(() => isLoading = true);
    try {
      if (isLogin) {
        UserCredential c = await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        _navigate(c.user!.uid);
      } else {
        UserCredential c = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        Map<String, dynamic> data = {
          'uid': c.user!.uid, 'name': _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(), 'role': role,
          'barberType': role == 'Barber' ? barberType : null,
          'rating': 0.0, 'totalRatings': 0, 'earnings': 0, 'totalBookings': 0,
          'available': true, 'createdAt': FieldValue.serverTimestamp(),
        };
        if (role == 'Barber') {
          data['address'] = _addressCtrl.text.trim();
          data['latitude'] = barberLat;
          data['longitude'] = barberLng;
          data['openTime'] = '08:00';
          data['closeTime'] = '20:00';
          data['services'] = [
            {'name': 'Ù‚ØµØ© Ø´Ø¹Ø±', 'nameF': 'Coupe', 'price': 300},
            {'name': 'Ù„Ø­ÙŠØ©', 'nameF': 'Barbe', 'price': 200},
            {'name': 'Ù‚ØµØ© + Ù„Ø­ÙŠØ©', 'nameF': 'Coupe + Barbe', 'price': 450},
          ];
        }
        await FirebaseFirestore.instance.collection('users').doc(c.user!.uid).set(data);
        _navigate(c.user!.uid);
      }
    } catch (e) { _snack(e.toString()); }
    setState(() => isLoading = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _navigate(String uid) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      String r = doc.get('role');
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => r == 'Barber' ? BarberDashboard(isArabic: widget.isArabic, uid: uid) : CustomerDashboard(isArabic: widget.isArabic),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ðŸ’ˆ Hallaq DZ', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [TextButton(onPressed: widget.onLanguageToggle, child: Text(widget.isArabic ? "FR" : "Ø¹Ø±Ø¨ÙŠ", style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Icon(Icons.content_cut, size: 70, color: Color(0xFFD4AF37)),
          const SizedBox(height: 16),
          // ØªØ¨ÙˆÙŠØ¨
          Container(
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
            child: Row(children: ['login', 'register'].map((m) {
              bool a = (m == 'login') == isLogin;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => isLogin = m == 'login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: a ? const Color(0xFFD4AF37) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Text(m == 'login' ? (widget.isArabic ? 'Ø¯Ø®ÙˆÙ„' : 'Connexion') : (widget.isArabic ? 'ØªØ³Ø¬ÙŠÙ„' : 'Inscription'),
                    textAlign: TextAlign.center, style: TextStyle(color: a ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
              ));
            }).toList()),
          ),
          const SizedBox(height: 16),
          // Ù†ÙˆØ¹ Ø§Ù„Ø­Ø³Ø§Ø¨
          Row(children: ['Customer', 'Barber'].map((t) {
            bool a = role == t;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => role = t),
              child: Container(
                margin: EdgeInsets.only(right: t == 'Customer' ? 6 : 0, left: t == 'Barber' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: a ? const Color(0xFFD4AF37) : Colors.grey[800], borderRadius: BorderRadius.circular(10)),
                child: Text(t == 'Customer' ? 'ðŸ‘¤ ${widget.isArabic ? "Ø²Ø¨ÙˆÙ†" : "Client"}' : 'âœ‚ï¸ ${widget.isArabic ? "Ø­Ù„Ø§Ù‚" : "Coiffeur"}',
                  textAlign: TextAlign.center, style: TextStyle(color: a ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
            ));
          }).toList()),
          const SizedBox(height: 10),
          if (role == 'Barber') ...[
            Row(children: ['Fixed', 'Mobile'].map((t) {
              bool a = barberType == t;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => barberType = t),
                child: Container(
                  margin: EdgeInsets.only(right: t == 'Fixed' ? 6 : 0, left: t == 'Mobile' ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: a ? const Color(0xFFD4AF37) : Colors.grey[800], borderRadius: BorderRadius.circular(10)),
                  child: Text(t == 'Fixed' ? 'ðŸª ${widget.isArabic ? "Ù…Ø­Ù„ Ø«Ø§Ø¨Øª" : "Salon fixe"}' : 'ðŸš— ${widget.isArabic ? "Ù…ØªÙ†Ù‚Ù„" : "Mobile"}',
                    textAlign: TextAlign.center, style: TextStyle(color: a ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
              ));
            }).toList()),
            const SizedBox(height: 10),
          ],
          if (!isLogin) ...[
            _field(_nameCtrl, widget.isArabic ? 'Ø§Ù„Ø§Ø³Ù… Ø§Ù„ÙƒØ§Ù…Ù„' : 'Nom complet'),
            const SizedBox(height: 10),
            _field(_phoneCtrl, widget.isArabic ? 'Ø±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ' : 'TÃ©lÃ©phone', type: TextInputType.phone),
            const SizedBox(height: 10),
            if (role == 'Barber') ...[
              _field(_addressCtrl, widget.isArabic ? 'Ø§Ù„Ø¹Ù†ÙˆØ§Ù† (ÙˆÙ„Ø§ÙŠØ© + Ù…Ø¯ÙŠÙ†Ø©)' : 'Adresse (Wilaya + Ville)'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: barberLat != null ? Colors.green[800] : Colors.grey[800], minimumSize: const Size(double.infinity, 48)),
                onPressed: locating ? null : _getLocation,
                icon: Icon(barberLat != null ? Icons.check_circle : Icons.location_on, color: Colors.white),
                label: Text(locating ? (widget.isArabic ? 'Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ­Ø¯ÙŠØ¯...' : 'Localisation...') : barberLat != null ? 'âœ… ${widget.isArabic ? "ØªÙ… ØªØ­Ø¯ÙŠØ¯ Ù…ÙˆÙ‚Ø¹Ùƒ" : "Position dÃ©tectÃ©e"}' : 'ðŸ“ ${widget.isArabic ? "Ø­Ø¯Ø¯ Ù…ÙˆÙ‚Ø¹ Ù…Ø­Ù„Ùƒ" : "Localiser mon salon"}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
            ],
          ],
          _field(_emailCtrl, widget.isArabic ? 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ' : 'Email', type: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _field(_passCtrl, widget.isArabic ? 'ÙƒÙ„Ù…Ø© Ø§Ù„Ø³Ø±' : 'Mot de passe', obscure: true),
          const SizedBox(height: 10),
          if (!isLogin) ...[
            _field(_confirmCtrl, widget.isArabic ? 'ØªØ£ÙƒÙŠØ¯ ÙƒÙ„Ù…Ø© Ø§Ù„Ø³Ø±' : 'Confirmer mot de passe', obscure: true),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: isLoading ? null : _submit,
            child: isLoading ? const CircularProgressIndicator(color: Colors.black) : Text(isLogin ? (widget.isArabic ? 'Ø¯Ø®ÙˆÙ„' : 'Connexion') : (widget.isArabic ? 'Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨' : 'CrÃ©er compte'),
              style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool obscure = false, TextInputType? type}) {
    return TextField(controller: c, obscureText: obscure, keyboardType: type,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[900]));
  }
}

// ==========================================
// CUSTOMER DASHBOARD
// ==========================================
class CustomerDashboard extends StatefulWidget {
  final bool isArabic;
  const CustomerDashboard({super.key, required this.isArabic});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  String filter = 'All';

  Future<void> _openMaps(double? lat, double? lng, String addr) async {
    Uri url = lat != null && lng != null
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr)}');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? 'ðŸ” Ø§Ø¨Ø­Ø« Ø¹Ù„Ù‰ Ø­Ù„Ø§Ù‚' : 'ðŸ” Trouver un coiffeur'),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () { FirebaseAuth.instance.signOut(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HallaqDZApp())); })],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _fBtn('All', widget.isArabic ? 'Ø§Ù„ÙƒÙ„' : 'Tous'),
            _fBtn('Fixed', 'ðŸª ${widget.isArabic ? "Ø«Ø§Ø¨Øª" : "Fixe"}'),
            _fBtn('Mobile', 'ðŸš— ${widget.isArabic ? "Ù…ØªÙ†Ù‚Ù„" : "Mobile"}'),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Barber').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
              var barbers = snap.data!.docs.where((d) => filter == 'All' || d['barberType'] == filter).toList();
              if (barbers.isEmpty) return Center(child: Text(widget.isArabic ? 'ðŸ’ˆ Ù…Ø§ ÙƒØ§Ø´ Ø­Ù„Ø§Ù‚ Ù…Ø³Ø¬Ù„ Ø¨Ø¹Ø¯' : 'ðŸ’ˆ Aucun coiffeur inscrit', style: const TextStyle(color: Colors.white60)));
              return ListView.builder(
                itemCount: barbers.length,
                itemBuilder: (context, i) {
                  var b = barbers[i];
                  var bd = b.data() as Map;
                  double rating = bd.containsKey('rating') ? (b['rating'] ?? 0).toDouble() : 0;
                  bool available = bd.containsKey('available') ? b['available'] : true;
                  double? lat = bd.containsKey('latitude') ? b['latitude']?.toDouble() : null;
                  double? lng = bd.containsKey('longitude') ? b['longitude']?.toDouble() : null;
                  String addr = bd.containsKey('address') ? (b['address'] ?? '') : '';
                  String open = bd.containsKey('openTime') ? b['openTime'] : '08:00';
                  String close = bd.containsKey('closeTime') ? b['closeTime'] : '20:00';
                  List services = bd.containsKey('services') ? (b['services'] ?? []) : [];

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFD4AF3733))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(backgroundColor: const Color(0xFFD4AF37), radius: 24, child: Icon(b['barberType'] == 'Fixed' ? Icons.store : Icons.electric_car, color: Colors.black)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(b['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(b['barberType'] == 'Fixed' ? 'ðŸª ${widget.isArabic ? "Ù…Ø­Ù„ Ø«Ø§Ø¨Øª" : "Salon fixe"}' : 'ðŸš— ${widget.isArabic ? "Ø­Ù„Ø§Ù‚ Ù…ØªÙ†Ù‚Ù„" : "Coiffeur mobile"}',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
                          ])),
                          Column(children: [
                            Text('â­ ${rating.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: available ? Colors.green[900] : Colors.red[900], borderRadius: BorderRadius.circular(10)),
                              child: Text(available ? (widget.isArabic ? 'Ù…ØªØ§Ø­' : 'Dispo') : (widget.isArabic ? 'Ù…Ø´ØºÙˆÙ„' : 'OccupÃ©'),
                                style: TextStyle(color: available ? Colors.green[300] : Colors.red[300], fontSize: 11)),
                            ),
                          ]),
                        ]),
                        const SizedBox(height: 8),
                        if (addr.isNotEmpty) Row(children: [const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 15), const SizedBox(width: 4), Expanded(child: Text(addr, style: const TextStyle(color: Colors.white70, fontSize: 13)))]),
                        Row(children: [const Icon(Icons.access_time, color: Color(0xFFD4AF37), size: 15), const SizedBox(width: 4), Text('$open - $close', style: const TextStyle(color: Colors.white70, fontSize: 13))]),
                        if (services.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: services.map<Widget>((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10)),
                            child: Text('${s['name']} - ${s['price']} DA', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          )).toList()),
                        ],
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => _openMaps(lat, lng, addr),
                            icon: const Icon(Icons.map, color: Colors.white, size: 18),
                            label: Text(widget.isArabic ? 'Ø§Ù„Ù…ÙˆÙ‚Ø¹' : 'Localiser', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: available ? const Color(0xFFD4AF37) : Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: available ? () => _book(b, services) : null,
                            icon: const Icon(Icons.calendar_today, color: Colors.black, size: 18),
                            label: Text(widget.isArabic ? 'Ø§Ø­Ø¬Ø²' : 'RÃ©server', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                          )),
                        ]),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _fBtn(String val, String label) {
    bool a = filter == val;
    return GestureDetector(
      onTap: () => setState(() => filter = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: a ? const Color(0xFFD4AF37) : Colors.grey[800], borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: a ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  void _book(DocumentSnapshot barber, List services) {
    String selTime = '10:00';
    String selSvc = services.isNotEmpty ? services[0]['name'] : '';
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, set) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ðŸ“… ${widget.isArabic ? "Ø­Ø¬Ø² Ø¹Ù†Ø¯" : "RÃ©server chez"} ${barber['name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (services.isNotEmpty) ...[
            Text(widget.isArabic ? 'Ø§Ù„Ø®Ø¯Ù…Ø©:' : 'Service:', style: const TextStyle(color: Color(0xFFD4AF37))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: services.map<Widget>((s) {
              bool a = selSvc == s['name'];
              return GestureDetector(
                onTap: () => set(() => selSvc = s['name']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(color: a ? const Color(0xFFD4AF37) : Colors.grey[800], borderRadius: BorderRadius.circular(20)),
                  child: Text('${s['name']} - ${s['price']} DA', style: TextStyle(color: a ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }).toList()),
            const SizedBox(height: 12),
          ],
          Text(widget.isArabic ? 'Ø§Ù„ÙˆÙ‚Øª:' : 'Heure:', style: const TextStyle(color: Color(0xFFD4AF37))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['09:00','10:00','11:00','14:00','15:00','16:00','17:00','18:00'].map((t) {
            bool a = selTime == t;
            return GestureDetector(
              onTap: () => set(() => selTime = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(color: a ? const Color(0xFFD4AF37) : Colors.grey[800], borderRadius: BorderRadius.circular(20)),
                child: Text(t, style: TextStyle(color: a ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList()),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('bookings').add({
                'barberId': barber.id, 'barberName': barber['name'],
                'customerId': FirebaseAuth.instance.currentUser!.uid,
                'service': selSvc, 'timeSlot': selTime, 'status': 'pending',
                'date': DateTime.now().toString().split(' ')[0],
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isArabic ? 'âœ… ØªÙ… Ø¥Ø±Ø³Ø§Ù„ Ø·Ù„Ø¨ Ø§Ù„Ø­Ø¬Ø²!' : 'âœ… Demande envoyÃ©e!'), backgroundColor: Colors.green));
            },
            child: Text(widget.isArabic ? 'ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø­Ø¬Ø²' : 'Confirmer', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
      )),
    );
  }
}

// ==========================================
// BARBER DASHBOARD
// ==========================================
class BarberDashboard extends StatefulWidget {
  final bool isArabic;
  final String uid;
  const BarberDashboard({super.key, required this.isArabic, required this.uid});
  @override
  State<BarberDashboard> createState() => _BarberDashboardState();
}

class _BarberDashboardState extends State<BarberDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? 'âœ‚ï¸ Ù„ÙˆØ­Ø© Ø§Ù„Ø­Ù„Ø§Ù‚' : 'âœ‚ï¸ Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () { FirebaseAuth.instance.signOut(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HallaqDZApp())); })],
      ),
      body: _tab == 0 ? _requests() : _settings(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFD4AF37), unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.list_alt), label: widget.isArabic ? 'Ø§Ù„Ø·Ù„Ø¨Ø§Øª' : 'Demandes'),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: widget.isArabic ? 'Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª' : 'ParamÃ¨tres'),
        ],
      ),
    );
  }

  Widget _requests() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.uid).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        var d = snap.data!;
        return Column(children: [
          Container(
            margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD4AF37))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('â­', '${(d['rating'] ?? 0).toStringAsFixed(1)}', widget.isArabic ? 'Ø§Ù„ØªÙ‚ÙŠÙŠÙ…' : 'Note'),
              _stat('ðŸ’°', '${d['earnings'] ?? 0} DA', widget.isArabic ? 'Ø§Ù„Ù…Ø¯Ø§Ø®ÙŠÙ„' : 'Gains'),
              _stat('ðŸ“‹', '${d['totalBookings'] ?? 0}', widget.isArabic ? 'Ø§Ù„Ø­Ø¬ÙˆØ²Ø§Øª' : 'RÃ©servations'),
            ]),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').where('barberId', isEqualTo: widget.uid).snapshots(),
              builder: (context, bs) {
                if (!bs.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                var bks = bs.data!.docs;
                if (bks.isEmpty) return Center(child: Text(widget.isArabic ? 'ðŸ“­ Ù…Ø§ ÙƒØ§Ø´ Ø·Ù„Ø¨Ø§Øª Ø¨Ø¹Ø¯' : 'ðŸ“­ Aucune demande', style: const TextStyle(color: Colors.white60)));
                return ListView.builder(
                  itemCount: bks.length,
                  itemBuilder: (context, i) {
                    var bk = bks[i];
                    String st = bk['status'];
                    return Card(
                      color: Colors.grey[900], margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('âœ‚ï¸ ${bk['service']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: st == 'pending' ? Colors.orange[900] : st == 'accepted' ? Colors.green[900] : Colors.red[900], borderRadius: BorderRadius.circular(10)),
                            child: Text(st == 'pending' ? (widget.isArabic ? 'Ø§Ù†ØªØ¸Ø§Ø±' : 'Attente') : st == 'accepted' ? (widget.isArabic ? 'Ù…Ù‚Ø¨ÙˆÙ„' : 'AcceptÃ©') : (widget.isArabic ? 'Ù…Ø±ÙÙˆØ¶' : 'RefusÃ©'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text('ðŸ• ${bk['timeSlot']} - ðŸ“… ${bk['date']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        if (st == 'pending') ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => bk.reference.update({'status': 'accepted'}),
                              icon: const Icon(Icons.check, color: Colors.white, size: 18),
                              label: Text(widget.isArabic ? 'Ù‚Ø¨ÙˆÙ„' : 'Accepter', style: const TextStyle(color: Colors.white)),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => bk.reference.update({'status': 'rejected'}),
                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                              label: Text(widget.isArabic ? 'Ø±ÙØ¶' : 'Refuser', style: const TextStyle(color: Colors.white)),
                            )),
                          ]),
                        ],
                      ])),
                    );
                  },
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _settings() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        var d = snap.data!;
        var dd = d.data() as Map;
        List services = dd.containsKey('services') ? (d['services'] ?? []) : [];
        bool available = dd.containsKey('available') ? d['available'] : true;
        String openTime = dd.containsKey('openTime') ? d['openTime'] : '08:00';
        String closeTime = dd.containsKey('closeTime') ? d['closeTime'] : '20:00';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _secTitle(widget.isArabic ? 'ðŸŸ¢ Ø§Ù„Ø­Ø§Ù„Ø©' : 'ðŸŸ¢ Statut'),
            Card(color: Colors.grey[900], child: SwitchListTile(
              value: available,
              activeColor: const Color(0xFFD4AF37),
              title: Text(available ? (widget.isArabic ? 'âœ… Ù…ØªØ§Ø­ Ù„Ù„Ø­Ø¬Ø²' : 'âœ… Disponible') : (widget.isArabic ? 'âŒ Ù…Ø´ØºÙˆÙ„' : 'âŒ OccupÃ©'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
              onChanged: (val) => FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'available': val}),
            )),
            const SizedBox(height: 16),
            _secTitle(widget.isArabic ? 'ðŸ• Ø£ÙˆÙ‚Ø§Øª Ø§Ù„Ø¹Ù…Ù„' : 'ðŸ• Horaires de travail'),
            Card(color: Colors.grey[900], child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              Expanded(child: _timeEdit(widget.isArabic ? 'ðŸŒ… Ø§Ù„ÙØªØ­' : 'ðŸŒ… Ouverture', openTime, 'openTime')),
              const SizedBox(width: 10),
              Expanded(child: _timeEdit(widget.isArabic ? 'ðŸŒ™ Ø§Ù„ØºÙ„Ù‚' : 'ðŸŒ™ Fermeture', closeTime, 'closeTime')),
            ]))),
            const SizedBox(height: 16),
            _secTitle(widget.isArabic ? 'âœ‚ï¸ Ø§Ù„Ø®Ø¯Ù…Ø§Øª ÙˆØ§Ù„Ø£Ø³Ø¹Ø§Ø±' : 'âœ‚ï¸ Services et prix'),
            ...services.asMap().entries.map((e) {
              int idx = e.key;
              var s = e.value;
              TextEditingController nc = TextEditingController(text: s['name']);
              TextEditingController pc = TextEditingController(text: s['price'].toString());
              return Card(color: Colors.grey[900], margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                Expanded(flex: 2, child: TextField(controller: nc,
                  decoration: InputDecoration(labelText: widget.isArabic ? 'Ø§Ø³Ù… Ø§Ù„Ø®Ø¯Ù…Ø©' : 'Service', border: const OutlineInputBorder(), isDense: true),
                  onSubmitted: (val) { services[idx]['name'] = val; FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'services': services}); })),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: pc, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'DA', border: OutlineInputBorder(), isDense: true),
                  onSubmitted: (val) { services[idx]['price'] = int.tryParse(val) ?? 0; FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'services': services}); })),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                  services.removeAt(idx);
                  FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'services': services});
                }),
              ])));
            }),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], minimumSize: const Size(double.infinity, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                services.add({'name': widget.isArabic ? 'Ø®Ø¯Ù…Ø© Ø¬Ø¯ÙŠØ¯Ø©' : 'Nouveau service', 'nameF': '', 'price': 0});
                FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'services': services});
              },
              icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
              label: Text(widget.isArabic ? '+ Ø²ÙŠØ¯ Ø®Ø¯Ù…Ø© Ø¬Ø¯ÙŠØ¯Ø©' : '+ Ajouter un service', style: const TextStyle(color: Color(0xFFD4AF37))),
            ),
          ]),
        );
      },
    );
  }

  Widget _timeEdit(String label, String value, String field) {
    TextEditingController c = TextEditingController(text: value);
    return TextField(controller: c,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
      onSubmitted: (val) => FirebaseFirestore.instance.collection('users').doc(widget.uid).update({field: val}));
  }

  Widget _secTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))));

  Widget _stat(String icon, String val, String label) => Column(children: [
    Text(icon, style: const TextStyle(fontSize: 20)),
    Text(val, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
  ]);
}
