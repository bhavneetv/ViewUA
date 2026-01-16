
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
// import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;

void main() {
  runApp(const ViewUABrowser());
}

class ViewUABrowser extends StatelessWidget {
  const ViewUABrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'View UA',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D9FF),
          brightness: Brightness.dark,
        ),

        scaffoldBackgroundColor: const Color(0xFF0F0F1E),

        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const LandingPage(),
    );
  }
}

Future<void> testHttp() async {
  try {
    final res = await http.get(Uri.parse('https://api.ipify.org'));
    debugPrint('TEST RESPONSE: ${res.body}');
  } catch (e) {
    debugPrint('TEST ERROR: $e');
  }
}

Future<void> _openGithub() async {
  final uri = Uri.parse('https://github.com/bhavneetv/ViewUA');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// Model for saved user agents
class SavedUserAgent {
  final String deviceName;
  final String userAgent;
  final DateTime savedAt;

  SavedUserAgent({
    required this.deviceName,
    required this.userAgent,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'deviceName': deviceName,
    'userAgent': userAgent,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedUserAgent.fromJson(Map<String, dynamic> json) => SavedUserAgent(
    deviceName: json['deviceName'],
    userAgent: json['userAgent'],
    savedAt: DateTime.parse(json['savedAt']),
  );
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _userAgentController = TextEditingController();

  String _publicIp = 'Loading...';
  String _location = 'Loading...';
  String _isp = 'Loading...';
  String _vpnStatus = 'Checking...';
  List<String> _history = [];
  List<SavedUserAgent> _savedUserAgents = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, String> _commonUserAgents = {
    'Chrome Windows':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Chrome macOS':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Safari macOS':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
    'Firefox Windows':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Edge Windows':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
    'iPhone 15 Pro':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'iPad Pro':
        'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Samsung Galaxy S24':
        'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Google Pixel 8':
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Googlebot':
        'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
  };

  @override
  void initState() {
    super.initState();
    testHttp();
    _loadIpInfo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadIpInfo();
    _loadHistory();
    _loadSavedUserAgents();
  }

  Future<void> _loadIpInfo() async {
    try {

      final ipRes = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));

      final ipData = jsonDecode(ipRes.body);
      final String ip = ipData['ip'];


      final bool vpnOn = await _isVpnConnected();

      if (!mounted) return;

      setState(() {
        _publicIp = ip;
        _location = vpnOn ? 'Outside India (via VPN)' : 'India';
        _isp = 'Not checked';
        _vpnStatus = vpnOn ? '🟢 VPN Connected' : '⚪ VPN Not Connected';
      });
    } catch (e) {
      debugPrint('FINAL IP ERROR: $e');

      if (!mounted) return;

      setState(() {
        _publicIp = 'Unavailable';
        _location = 'Unavailable';
        _isp = 'Unavailable';
        _vpnStatus = 'Unknown';
      });
    }
  }

  Future<bool> _isVpnConnected() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: true,
      );

      for (final i in interfaces) {
        final name = i.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('utun') ||
            name.contains('ppp') ||
            name.contains('tap')) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('browsing_history') ?? [];
    });
  }

  Future<void> _loadSavedUserAgents() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_user_agents_v2') ?? [];
    setState(() {
      _savedUserAgents = saved
          .map((e) => SavedUserAgent.fromJson(json.decode(e)))
          .toList();
    });
  }

  Future<void> _saveUserAgent(String deviceName, String userAgent) async {
    final newAgent = SavedUserAgent(
      deviceName: deviceName,
      userAgent: userAgent,
      savedAt: DateTime.now(),
    );

    _savedUserAgents.removeWhere((e) => e.userAgent == userAgent);
    _savedUserAgents.insert(0, newAgent);

    if (_savedUserAgents.length > 30) {
      _savedUserAgents = _savedUserAgents.sublist(0, 30);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'saved_user_agents_v2',
      _savedUserAgents.map((e) => json.encode(e.toJson())).toList(),
    );
    setState(() {});
  }

  Future<void> _deleteUserAgent(SavedUserAgent agent) async {
    _savedUserAgents.remove(agent);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'saved_user_agents_v2',
      _savedUserAgents.map((e) => json.encode(e.toJson())).toList(),
    );
    setState(() {});
  }

  Future<void> _saveHistory(String url) async {
    if (!_history.contains(url)) {
      _history.insert(0, url);
      if (_history.length > 100) _history = _history.sublist(0, 100);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('browsing_history', _history);
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('browsing_history');
    setState(() {
      _history = [];
    });
  }

  String _normalizeUrl(String url) {
    url = url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  void _navigateToBrowser() {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final normalizedUrl = _normalizeUrl(_urlController.text);
    _saveHistory(normalizedUrl);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowserPage(
          initialUrl: normalizedUrl,
          userAgent: _userAgentController.text,
        ),
      ),
    );
  }

  void _showSaveUserAgentDialog() {
    if (_userAgentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a User Agent first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final deviceNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save User Agent'),
        content: TextField(
          controller: deviceNameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'e.g., My iPhone 15',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (deviceNameController.text.isNotEmpty) {
                _saveUserAgent(
                  deviceNameController.text,
                  _userAgentController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User Agent saved!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D9FF), Color(0xFF7C4DFF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.devices, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ViewUA',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Browser Emulation & Testing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00D9FF),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 🔥 GitHub icon (right aligned, no indent issues)
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: _openGithub,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D1117),
                            shape: BoxShape.circle,
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.github,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // IP Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF00D9FF),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Network Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow(Icons.public, 'Public IP', _publicIp),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.location_on,
                            'Location',
                            _location,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.dns, 'ISP', _isp),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.vpn_lock,
                            'VPN Status',
                            _vpnStatus,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Agent Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android,
                                color: Color(0xFF7C4DFF),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'User Agent Configuration',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _userAgentController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Custom User-Agent (Optional)',
                              hintText:
                                  'Leave empty for default browser behavior',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F0F1E),
                              suffixIcon: _userAgentController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.save),
                                      onPressed: _showSaveUserAgentDialog,
                                      tooltip: 'Save User Agent',
                                    )
                                  : null,
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showCommonUserAgents,
                                  icon: const Icon(
                                    Icons.devices_other,
                                    size: 18,
                                  ),
                                  label: const Text('Presets'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showSavedUserAgents,
                                  icon: const Icon(Icons.bookmark, size: 18),
                                  label: Text(
                                    'Saved (${_savedUserAgents.length})',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // URL Input Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.language,
                                color: Color(0xFF00D9FF),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Website URL',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              hintText: 'example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF0F0F1E),
                              prefixIcon: const Icon(Icons.link),
                            ),
                            onSubmitted: (_) => _navigateToBrowser(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToBrowser,
                              icon: const Icon(Icons.open_in_browser, size: 24),
                              label: const Text(
                                'Open Website',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showHistory,
                              icon: const Icon(Icons.history),
                              label: Text(
                                'Browsing History (${_history.length})',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Features Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00D9FF).withOpacity(0.1),
                          const Color(0xFF7C4DFF).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00D9FF).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✨ Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeature(
                          '🔐 Persistent login sessions (cookies, local/session storage)',
                        ),
                        _buildFeature(
                          '📱 Device emulation with custom User-Agents',
                        ),
                        _buildFeature('🌐 IP & VPN detection'),
                        _buildFeature('📚 Browsing history tracking'),
                        _buildFeature('💾 Save & manage User-Agent presets'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Browsing History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearHistory();
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(child: Text('No history yet'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(
                                Icons.public,
                                color: Color(0xFF00D9FF),
                              ),
                              title: Text(
                                _history[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _urlController.text = _history[index];
                                _navigateToBrowser();
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSavedUserAgents() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saved User Agents',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_savedUserAgents.length}/30',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _savedUserAgents.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No saved User Agents yet\n\nEnter a custom User Agent and click the save icon to store it with a device name',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _savedUserAgents.length,
                              itemBuilder: (context, index) {
                                final agent = _savedUserAgents[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.smartphone,
                                      color: Color(0xFF7C4DFF),
                                    ),
                                    title: Text(
                                      agent.deviceName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      agent.userAgent,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () {
                                        _deleteUserAgent(agent);
                                        setModalState(() {});
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _userAgentController.text =
                                          agent.userAgent;
                                      setState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCommonUserAgents() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Common Device User Agents',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _commonUserAgents.length,
                    itemBuilder: (context, index) {
                      final entry = _commonUserAgents.entries.toList()[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _getDeviceIcon(entry.key),
                            color: const Color(0xFF00D9FF),
                          ),
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            entry.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _userAgentController.text = entry.value;
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getDeviceIcon(String deviceName) {
    if (deviceName.contains('iPhone') || deviceName.contains('iPad')) {
      return Icons.apple;
    } else if (deviceName.contains('Samsung') || deviceName.contains('Pixel')) {
      return Icons.android;
    } else if (deviceName.contains('bot')) {
      return Icons.smart_toy;
    } else if (deviceName.contains('Windows') || deviceName.contains('macOS')) {
      return Icons.computer;
    }
    return Icons.devices;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userAgentController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// Browser Page
class BrowserPage extends StatefulWidget {
  final String initialUrl;
  final String userAgent;

  const BrowserPage({super.key, required this.initialUrl, this.userAgent = ''});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  InAppWebViewController? _webViewController;
  String _currentUrl = '';
  String _pageTitle = '';
  double _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pageTitle.isEmpty ? 'Loading...' : _pageTitle,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_currentUrl.isNotEmpty)
              Text(
                _currentUrl,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'forward':
                  _webViewController?.goForward();
                  break;
                case 'desktop':
                  await _webViewController?.evaluateJavascript(
                    source:
                        "document.querySelector('meta[name=\"viewport\"]')?.remove();",
                  );
                  _webViewController?.reload();
                  break;
                case 'clear_cookies':
                  await _clearCookies();
                  break;
                case 'clear_storage':
                  await _clearStorage();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'forward',
                enabled: _canGoForward,
                child: const Row(
                  children: [
                    Icon(Icons.arrow_forward),
                    SizedBox(width: 8),
                    Text('Forward'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'desktop',
                child: Row(
                  children: [
                    Icon(Icons.desktop_windows),
                    SizedBox(width: 8),
                    Text('Request Desktop Site'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_cookies',
                child: Row(
                  children: [
                    Icon(Icons.cookie),
                    SizedBox(width: 8),
                    Text('Clear Cookies'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_storage',
                child: Row(
                  children: [
                    Icon(Icons.storage),
                    SizedBox(width: 8),
                    Text('Clear Storage'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00D9FF),
              ),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              initialSettings: InAppWebViewSettings(
                userAgent: widget.userAgent.isNotEmpty
                    ? widget.userAgent
                    : null,
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheEnabled: true,
                thirdPartyCookiesEnabled: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                supportMultipleWindows: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _currentUrl = url.toString();
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _currentUrl = url.toString();
                });
                final title = await controller.getTitle();
                final canGoBack = await controller.canGoBack();
                final canGoForward = await controller.canGoForward();
                setState(() {
                  _pageTitle = title ?? '';
                  _canGoBack = canGoBack;
                  _canGoForward = canGoForward;
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onCreateWindow: (controller, createWindowAction) async {
                final url = createWindowAction.request.url;
                if (url != null) {
                  await controller.loadUrl(urlRequest: URLRequest(url: url));
                }
                return true;
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _canGoBack
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF00D9FF),
              onPressed: () => _webViewController?.goBack(),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            )
          : null,
    );
  }

  Future<void> _clearCookies() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();
    _webViewController?.reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cookies cleared'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearStorage() async {
    await _webViewController?.evaluateJavascript(
      source: """
      localStorage.clear();
      sessionStorage.clear();
    """,
    );
    _webViewController?.reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local storage cleared'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
