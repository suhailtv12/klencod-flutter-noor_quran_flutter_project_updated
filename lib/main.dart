import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const green = Color(0xFF126B50);
const gold = Color(0xFFD7B46A);
const api = 'https://api.alquran.cloud/v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.noorquran.audio',
    androidNotificationChannelName: 'تلاوات القرآن الكريم',
    androidNotificationChannelDescription: 'التحكم في تلاوة القرآن من شاشة القفل',
    androidNotificationOngoing: true,
  );
  runApp(const NoorApp());
}

class NoorApp extends StatefulWidget {
  const NoorApp({super.key});
  @override
  State<NoorApp> createState() => _NoorAppState();
}

class _NoorAppState extends State<NoorApp> {
  bool dark = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'نور القرآن',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: green),
      scaffoldBackgroundColor: const Color(0xFFF7F8F3),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    darkTheme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF101A18),
      cardTheme: CardThemeData(
        elevation: 0, color: const Color(0xFF1A2925),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: SplashPage(onReady: () => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => HomePage(
        onTheme: () => setState(() => dark = !dark),
        dark: dark,
      )),
    )),
  );
}

class SplashPage extends StatefulWidget {
  final VoidCallback onReady;
  const SplashPage({super.key, required this.onReady});
  @override
  State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) widget.onReady();
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF073D30), Color(0xFF168061)],
          begin: Alignment.topRight, end: Alignment.bottomLeft,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 76, color: gold),
          SizedBox(height: 20),
          Text('نور القرآن', style: TextStyle(
            color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('رفيقك اليومي لكتاب الله', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 35),
          SizedBox(width: 25, height: 25,
            child: CircularProgressIndicator(color: gold, strokeWidth: 2.5)),
        ],
      ),
    ),
  );
}

class QuranApi {
  static Future<List<dynamic>> surahs() async {
    final r = await http.get(Uri.parse('$api/surah')).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('تعذر تحميل فهرس السور');
    return jsonDecode(r.body)['data'] as List<dynamic>;
  }
  static Future<Map<String, dynamic>> readSurah(int n, String edition) async {
    final r = await http.get(Uri.parse('$api/surah/$n/$edition'))
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر تحميل السورة');
    return Map<String, dynamic>.from(jsonDecode(r.body)['data']);
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onTheme;
  final bool dark;
  const HomePage({super.key, required this.onTheme, required this.dark});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  List<dynamic> surahs = [];
  bool loading = true;
  String? error;
  final Set<int> favorites = {};
  int pageRead = 0;
  int tasbih = 0;
  int dhikrIndex = 0;
  final search = TextEditingController();

  final dhikr = const [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّد',
    'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = await QuranApi.surahs();
      if (!mounted) return;
      setState(() {
        surahs = data;
        favorites.addAll((prefs.getStringList('favorites') ?? []).map(int.parse));
        pageRead = prefs.getInt('pageRead') ?? 0;
        tasbih = prefs.getInt('tasbih') ?? 0;
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favorites', favorites.map((e) => '$e').toList());
    await p.setInt('pageRead', pageRead);
    await p.setInt('tasbih', tasbih);
  }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 50), const SizedBox(height: 12),
        Text('تعذر الاتصال بمصدر القرآن.\n$error', textAlign: TextAlign.center),
        const SizedBox(height: 12), FilledButton(onPressed: () { setState(() { loading = true; error = null; }); _load(); }, child: const Text('إعادة المحاولة')),
      ]),
    )));
    final pages = [_home(), _quran(), _favorites(), _more()];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'المصحف'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'المزيد'),
        ],
      ),
    ));
  }

  Widget _heading(String title, String sub) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(sub, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]),
  );
  Widget _home() => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
    _heading('نور القرآن', 'مساحة هادئة لقراءة القرآن والذكر'),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF073D30), Color(0xFF168061)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome, color: gold, size: 30),
        const SizedBox(height: 16),
        const Text('وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ', style: TextStyle(color: Colors.white, fontSize: 22, height: 1.8, fontWeight: FontWeight.bold)),
        const Text('فَهَلْ مِن مُّدَّكِرٍ', style: TextStyle(color: gold, fontSize: 20)),
        const SizedBox(height: 8), const Text('سورة القمر · 17', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 18), FilledButton(
          style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black87),
          onPressed: () => _openReader(surahs.first), child: const Text('افتح المصحف')),
      ]),
    )),
    const SizedBox(height: 20),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
      Expanded(child: _stat('تقدم الختمة', '$pageRead / 604', Icons.auto_stories)),
      const SizedBox(width: 10), Expanded(child: _stat('التسبيحات', '$tasbih', Icons.fingerprint)),
    ])),
    const SizedBox(height: 20),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
      const Expanded(child: Text('ذكر اليوم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
      TextButton(onPressed: () => setState(() => dhikrIndex = (dhikrIndex + 1) % dhikr.length), child: const Text('ذكر آخر')),
    ])),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Card(child: Padding(
      padding: const EdgeInsets.all(20), child: Column(children: [
        const Icon(Icons.spa_outlined, color: green, size: 30),
        const SizedBox(height: 12),
        Text(dhikr[dhikrIndex], textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 1.8)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () { setState(() => tasbih++); save(); },
          icon: const Icon(Icons.add), label: Text('تسبيح  $tasbih')),
      ]),
    ))),
    const SizedBox(height: 20),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: const Text('سور مقترحة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    ...surahs.where((s) => [1, 18, 36, 55, 67, 112].contains(s['number'])).map(_surahTile),
  ]);
  Widget _stat(String title, String value, IconData icon) => Card(child: Padding(
    padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: green), const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(title),
    ]),
  ));
  Widget _quran() {
    final q = search.text.trim();
    final list = surahs.where((s) => (s['name'] as String).contains(q) || '${s['number']}' == q).toList();
    return Column(children: [
      _heading('المصحف الشريف', 'جميع سور القرآن الكريم'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
        controller: search, onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: 'ابحث عن سورة بالاسم أو الرقم', prefixIcon: const Icon(Icons.search),
          filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
      )),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (_, i) => _surahTile(list[i]))),
    ]);
  }
  Widget _surahTile(dynamic s) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: green.withValues(alpha: .12), child: Text('${s['number']}', style: const TextStyle(color: green, fontWeight: FontWeight.bold))),
      title: Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      subtitle: Text('${s['revelationType'] == 'Meccan' ? 'مكية' : 'مدنية'} · ${s['numberOfAyahs']} آية'),
      trailing: IconButton(icon: Icon(favorites.contains(s['number']) ? Icons.favorite : Icons.favorite_border, color: favorites.contains(s['number']) ? Colors.red : null),
        onPressed: () { setState(() { favorites.contains(s['number']) ? favorites.remove(s['number']) : favorites.add(s['number'] as int); }); save(); }),
      onTap: () => _openReader(s),
    ),
  );
  Widget _favorites() {
    final list = surahs.where((s) => favorites.contains(s['number'])).toList();
    return Column(children: [
      _heading('السور المفضلة', 'سورك التي حفظتها للوصول السريع'),
      Expanded(child: list.isEmpty ? const Center(child: Text('لا توجد سور مفضلة بعد')) : ListView(children: list.map(_surahTile).toList())),
    ]);
  }
  Widget _more() => ListView(children: [
    _heading('المزيد', 'إعدادات وأدوات نور القرآن'),
    Card(child: ListTile(leading: const Icon(Icons.dark_mode_outlined, color: green), title: const Text('الوضع الليلي'), trailing: Switch(value: widget.dark, onChanged: (_) => widget.onTheme()))),
    Card(child: ListTile(leading: const Icon(Icons.notifications_active_outlined, color: green), title: const Text('تفعيل الإشعارات'), subtitle: const Text('للتنبيهات التي يتيحها النظام'), onTap: _askNotification)),
    Card(child: ListTile(leading: const Icon(Icons.fingerprint, color: green), title: const Text('المسبحة'), onTap: () => setState(() => tab = 0))),
    const Padding(padding: EdgeInsets.all(20), child: Text('مصدر النص والتلاوة: AlQuran Cloud API. يلزم اتصال بالإنترنت لتحميل النصوص والتلاوات لأول مرة.', textAlign: TextAlign.center)),
  ]);
  Future<void> _askNotification() async {
    final status = await Permission.notification.request();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status.isGranted ? 'تم السماح بالإشعارات' : 'لم يتم منح صلاحية الإشعارات')));
  }
  void _openReader(dynamic s) => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(surah: s)));
}

class ReaderPage extends StatefulWidget {
  final dynamic surah;
  const ReaderPage({super.key, required this.surah});
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}
class _ReaderPageState extends State<ReaderPage> {
  final AudioPlayer player = AudioPlayer();
  Map<String, dynamic>? textData;
  Map<String, dynamic>? audioData;
  bool loading = true;
  String? error;
  bool showTranslation = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final n = widget.surah['number'] as int;
      final results = await Future.wait([
        QuranApi.readSurah(n, 'quran-uthmani'),
        QuranApi.readSurah(n, 'ar.alafasy'),
      ]);
      if (!mounted) return;
      setState(() { textData = results[0]; audioData = results[1]; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }
  Future<void> _play() async {
    final ayahs = (audioData?['ayahs'] as List?) ?? [];
    final sources = <AudioSource>[];
    for (var i = 0; i < ayahs.length; i++) {
      final a = ayahs[i] as Map;
      final url = a['audio'];
      if (url is String && url.startsWith('http')) {
        sources.add(AudioSource.uri(Uri.parse(url), tag: MediaItem(
          id: '${widget.surah['number']}:$i',
          title: 'سورة ${widget.surah['name']} — الآية ${a['numberInSurah']}',
          album: 'نور القرآن · تلاوة مشاري العفاسي',
        )));
      }
    }
    if (sources.isEmpty) throw Exception('لم تتوفر روابط صوتية لهذه السورة');
    await player.setAudioSources(sources);
    await player.play();
  }
  @override
  void dispose() { player.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: Text('سورة ${widget.surah['name']}')),
    body: loading ? const Center(child: CircularProgressIndicator()) : error != null
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('تعذر تحميل السورة:\n$error', textAlign: TextAlign.center)))
      : Column(children: [
        Container(width: double.infinity, margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF073D30), Color(0xFF168061)])),
          child: Column(children: [
            const Icon(Icons.auto_awesome, color: gold, size: 28),
            const SizedBox(height: 8), Text('${textData!['name']}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text('${textData!['numberOfAyahs']} آية', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            StreamBuilder<PlayerState>(stream: player.playerStateStream, builder: (_, snap) {
              final playing = snap.data?.playing ?? false;
              return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: () async { if (player.hasPrevious) await player.seekToPrevious(); }, icon: const Icon(Icons.skip_previous, color: Colors.white)),
                IconButton.filled(onPressed: () async { try { if (player.playing) { await player.pause(); } else if (player.audioSource == null) { await _play(); } else { await player.play(); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تشغيل التلاوة: $e'))); } },
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow), style: IconButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black)),
                IconButton(onPressed: () async { if (player.hasNext) await player.seekToNext(); }, icon: const Icon(Icons.skip_next, color: Colors.white)),
              ]);
            }),
            const Text('يمكن التحكم بالتلاوة من إشعار الوسائط وشاشة القفل أثناء التشغيل.', style: TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
          ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: (textData!['ayahs'] as List).length,
          itemBuilder: (_, i) {
            final a = (textData!['ayahs'] as List)[i];
            return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: green.withValues(alpha: .10), shape: BoxShape.circle),
                  child: Text('${a['numberInSurah']}', style: const TextStyle(color: green)),
                )),
                const SizedBox(height: 8),
                Text('${a['text']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, height: 2.1)),
              ]),
            ));
          },
        )),
      ]),
  ));
}