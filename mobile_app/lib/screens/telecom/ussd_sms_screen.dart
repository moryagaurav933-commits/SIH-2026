import 'package:flutter/material.dart';
import '../../utils/design_tokens.dart';

/// Interactive 2G Rural Telecom Simulator (USSD & SMS Gateway)
/// Runs 100% on-device with zero backend server dependencies.
/// Allows farmers and testing officers to dial *123# and send SMS queries.
class UssdSmsScreen extends StatefulWidget {
  const UssdSmsScreen({super.key});

  @override
  State<UssdSmsScreen> createState() => _UssdSmsScreenState();
}

class _UssdSmsScreenState extends State<UssdSmsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // USSD State
  String _dialedNumber = '*123#';
  bool _isInUssdSession = false;
  String _currentUssdScreenText = '';
  final TextEditingController _ussdInputController = TextEditingController();
  bool _isUssdLoading = false;
  int _ussdMenuStep = 0; // 0: Main, 1: Disease, 2: Mandi, 3: Weather, 4: Scheme

  // SMS State
  final TextEditingController _smsRecipientController = TextEditingController(text: '56161');
  final TextEditingController _smsBodyController = TextEditingController(text: 'CROP WHEAT RUST');
  final List<Map<String, dynamic>> _smsChatHistory = [];
  bool _isSmsSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial simulated carrier welcome SMS
    _smsChatHistory.add({
      'isUser': false,
      'text': 'कृषि-सारथी सेवा केंद्र (56161): फसल सलाह हेतु CROP [फसल], मंडी भाव हेतु MANDI [फसल] लिखकर भेजें।',
      'time': '10:00 AM',
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ussdInputController.dispose();
    _smsRecipientController.dispose();
    _smsBodyController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    if (_isInUssdSession) return;
    setState(() {
      _dialedNumber += key;
    });
  }

  void _onBackspace() {
    if (_isInUssdSession || _dialedNumber.isEmpty) return;
    setState(() {
      _dialedNumber = _dialedNumber.substring(0, _dialedNumber.length - 1);
    });
  }

  Future<void> _startUssdSession() async {
    if (_dialedNumber.isEmpty) return;
    setState(() {
      _isUssdLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (_dialedNumber == '*123#' || _dialedNumber.startsWith('*123')) {
      setState(() {
        _isInUssdSession = true;
        _isUssdLoading = false;
        _ussdMenuStep = 0;
        _currentUssdScreenText =
            '🌱 कृषि-सारथी टेलीकॉम सेवा (*123#)\n'
            '1. फसल रोग व उपचार\n'
            '2. लाइव मंडी भाव\n'
            '3. मौसम अलर्ट (लखनऊ)\n'
            '4. पीएम किसान योजना\n'
            '0. बाहर निकलें';
      });
    } else {
      setState(() {
        _isUssdLoading = false;
        _isInUssdSession = true;
        _currentUssdScreenText = 'गलत USSD कोड।\nकृपया *123# डायल करें।\n\n0. बाहर निकलें';
      });
    }
  }

  Future<void> _sendUssdResponse() async {
    final input = _ussdInputController.text.trim();
    if (input.isEmpty) return;
    _ussdInputController.clear();

    setState(() {
      _isUssdLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isUssdLoading = false;

      if (_ussdMenuStep == 0) {
        switch (input) {
          case '1':
            _ussdMenuStep = 1;
            _currentUssdScreenText =
                '🌾 फसल रोग चयन:\n'
                '1. गेहूं पीला रतुआ (Yellow Rust)\n'
                '2. धान का झुलसा (Paddy Blast)\n'
                '3. आलू अगेती/पछेती झुलसा\n'
                '0. मुख्य मेन्यू';
            break;
          case '2':
            _currentUssdScreenText =
                '💰 मंडी भाव (लखनऊ मंडी):\n'
                '• गेहूं: ₹2,550/क्विंटल (📈 +2.4%)\n'
                '• धान: ₹4,100/क्विंटल\n'
                '• सरसों: ₹5,450/क्विंटल\n'
                '• आलू: ₹1,300/क्विंटल\n'
                'कृषि-सारथी सेवा समाप्त।';
            _showUssdEndDialog(_currentUssdScreenText);
            break;
          case '3':
            _currentUssdScreenText =
                '🌤️ मौसम अलर्ट (लखनऊ):\n'
                'तापमान: 31°C • नमी: 72%\n'
                'अगले 48 घंटे: हल्की वर्षा की संभावना।\n'
                'सलाह: जल निकासी नाली साफ रखें।\n'
                'कृषि-सारथी सेवा समाप्त।';
            _showUssdEndDialog(_currentUssdScreenText);
            break;
          case '4':
            _currentUssdScreenText =
                '🏛️ पीएम किसान सम्मान निधि:\n'
                'पात्र किसानों को ₹6,000/वर्ष (3 किस्तें)।\n'
                'ई-केवाईसी अनिवार्य है।\n'
                'हेल्पलाइन: 155261\n'
                'कृषि-सारथी सेवा समाप्त।';
            _showUssdEndDialog(_currentUssdScreenText);
            break;
          case '0':
            _currentUssdScreenText = 'सेवा समाप्त। कृषि-सारथी सदैव आपके साथ है।';
            _showUssdEndDialog(_currentUssdScreenText);
            break;
          default:
            _currentUssdScreenText = 'अमान्य विकल्प। कृपया 1 से 4 या 0 दर्ज करें।';
            break;
        }
      } else if (_ussdMenuStep == 1) {
        switch (input) {
          case '1':
            _currentUssdScreenText =
                '🌾 गेहूं पीला रतुआ उपचार:\n'
                'प्रोपिकोनाज़ोल 25% EC @ 1ml/L पानी (200ml/एकड़) छिड़कें। यूरिया रोकें।\n'
                'स्रोतः ICAR-IIWBR';
            _showUssdEndDialog(_currentUssdScreenText);
            break;
          case '2':
            _currentUssdScreenText =
                '🌾 धान झुलसा उपचार:\n'
                'ट्राइसाइक्लाज़ोल 75% WP @ 0.6g/L पानी छिड़कें। खेत से पानी निकालें।\n'
                'स्रोतः ICAR-NRRI';
            _showUssdEndDialog(_currentUssdScreenText);
            break;
          case '3':
            _currentUssdScreenText =
                '🥔 आलू अंगमारी उपचार:\n'
                'साइमोक्सानिल 8% + मैंकोजेब 64% WP @ 3g/L छिड़कें।\n'
                'स्रोतः ICAR-CPRI';
            _showUssdEndDialog(_currentUssdScreenText);
            break;
          case '0':
            _ussdMenuStep = 0;
            _currentUssdScreenText =
                '🌱 कृषि-सारथी टेलीकॉम सेवा (*123#)\n'
                '1. फसल रोग व उपचार\n'
                '2. लाइव मंडी भाव\n'
                '3. मौसम अलर्ट (लखनऊ)\n'
                '4. पीएम किसान योजना\n'
                '0. बाहर निकलें';
            break;
          default:
            _currentUssdScreenText = 'अमान्य विकल्प। 1, 2, 3 या 0 दर्ज करें।';
            break;
        }
      }
    });
  }

  void _showUssdEndDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cell_tower, color: colorPrimary),
            SizedBox(width: 8),
            Text(
              'टेलीकॉम USSD संदेश',
              style: TextStyle(color: colorStoneText, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: colorStoneText, height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isInUssdSession = false;
                _currentUssdScreenText = '';
                _ussdMenuStep = 0;
              });
            },
            child: const Text('ठीक है (OK)', style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSms() async {
    final text = _smsBodyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSmsSending = true;
      _smsChatHistory.add({
        'isUser': true,
        'text': text,
        'time': 'अभी',
      });
    });
    _smsBodyController.clear();

    await Future.delayed(const Duration(milliseconds: 500));

    final q = text.toUpperCase();
    String reply = 'कृषि-सारथी SMS सेवा: आपका संदेश प्राप्त हुआ। सहायता हेतु CROP [फसल] या MANDI [फसल] भेजें।';

    if (q.contains('WHEAT') || q.contains('RUST') || q.contains('गेहूं')) {
      reply = 'कृषि-सारथी सलाह: गेहूं में पीला रतुआ हेतु प्रोपिकोनाज़ोल 25% EC (टिल्ट) @ 1ml/L पानी में मिलाकर तुरंत छिड़कें। यूरिया कम करें। (ICAR)';
    } else if (q.contains('MANDI') || q.contains('भाव') || q.contains('PRICE')) {
      reply = 'कृषि-सारथी मंडी भाव: गेहूं ₹2,550/क्विं, धान ₹4,100/क्विं, सरसों ₹5,450/क्विं, आलू ₹1,300/क्विं (लखनऊ मंडी लाइव)';
    } else if (q.contains('WEATHER') || q.contains('मौसम')) {
      reply = 'मौसम चेतावनी (लखनऊ): तापमान 31C, 48 घंटों में हल्की से मध्यम वर्षा संभव। जल निकासी नाली साफ रखें।';
    } else if (q.contains('KISAN') || q.contains('SCHEME') || q.contains('योजना')) {
      reply = 'पीएम-किसान: ₹6,000 वार्षिक सहायता। स्थिति जांचने हेतु pmkisan.gov.in देखें या 155261 पर कॉल करें।';
    }

    if (mounted) {
      setState(() {
        _isSmsSending = false;
        _smsChatHistory.add({
          'isUser': false,
          'text': reply,
          'time': 'अभी',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      appBar: buildKrishiAppBar(
        context: context,
        title: '2G टेलीकॉम गेटवे',
        subtitle: 'RURAL 2G USSD (*123#) & SMS GATEWAY',
        emoji: '📡',
      ),
      body: Column(
        children: [
          Container(
            color: colorCard,
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorPrimary,
              labelColor: colorPrimary,
              unselectedLabelColor: colorStoneMuted,
              tabs: const [
                Tab(icon: Icon(Icons.dialpad), text: '2G USSD (*123#)'),
                Tab(icon: Icon(Icons.sms), text: 'SMS सहायता (56161)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUssdKeypadTab(),
                _buildSmsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUssdKeypadTab() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 330,
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E14), // Deep forest phone body
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colorPrimary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Screen container (Feature phone LCD display)
              Container(
                height: 150,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3820),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.6), width: 1.5),
                ),
                child: _isInUssdSession ? _buildActiveUssdScreen() : _buildIdleDialScreen(),
              ),
              const SizedBox(height: 16),

              // Keypad matrix
              _buildKeypadGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleDialScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BSNL 2G • भारत', style: TextStyle(color: Color(0xFF81C784), fontSize: 10, fontWeight: FontWeight.bold)),
            Icon(Icons.network_cell, size: 14, color: Color(0xFF81C784)),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _dialedNumber.isEmpty ? 'डायल करें' : _dialedNumber,
            style: TextStyle(
              color: const Color(0xFFA5D6A7),
              fontSize: _dialedNumber.length > 8 ? 20 : 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const Spacer(),
        const Text('*123# डायल कर ऑफलाइन कृषि सेवा शुरू करें', style: TextStyle(color: Color(0xFF81C784), fontSize: 9.5)),
      ],
    );
  }

  Widget _buildActiveUssdScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              _currentUssdScreenText,
              style: const TextStyle(color: Color(0xFFA5D6A7), fontSize: 11, height: 1.35, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _ussdInputController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'विकल्प (उदा. 1)...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _sendUssdResponse(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: _isUssdLoading ? null : _sendUssdResponse,
                child: const Text('Send', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadGrid() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Column(
      children: [
        // Call & End row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton.small(
              heroTag: 'ussd_call',
              backgroundColor: colorPrimary,
              onPressed: _startUssdSession,
              child: const Icon(Icons.call, color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.backspace, color: Colors.white70),
              onPressed: _onBackspace,
            ),
            FloatingActionButton.small(
              heroTag: 'ussd_end',
              backgroundColor: colorEarthAlert,
              onPressed: () {
                setState(() {
                  _isInUssdSession = false;
                  _dialedNumber = '';
                  _currentUssdScreenText = '';
                  _ussdMenuStep = 0;
                });
              },
              child: const Icon(Icons.call_end, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3x4 Matrix
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final k in row)
                  InkWell(
                    onTap: () => _onKeyPress(k),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 60,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3324),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        k,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSmsTab() {
    return Column(
      children: [
        // Top banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: colorPrimarySoft,
          child: const Row(
            children: [
              Icon(Icons.sms_rounded, color: colorPrimary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ऑफ़लाइन ग्रामीण SMS गेटवे • टोल-फ्री 56161 (No Internet Required)',
                  style: TextStyle(color: colorPrimaryDeep, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _smsChatHistory.length,
            itemBuilder: (ctx, i) {
              final msg = _smsChatHistory[i];
              final isUser = msg['isUser'] as bool;
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isUser ? colorPrimary : colorCard,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser ? null : Border.all(color: colorHairline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['text'] as String,
                        style: TextStyle(
                          color: isUser ? Colors.white : colorStoneText,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg['time'] as String,
                        style: TextStyle(
                          color: isUser ? Colors.white70 : colorStoneMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Message input row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: colorCard,
            border: Border(top: BorderSide(color: colorHairline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _smsBodyController,
                  style: const TextStyle(color: colorStoneText, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'उदा. CROP WHEAT, MANDI RICE...',
                    hintStyle: const TextStyle(color: colorStoneMuted, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: colorSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: colorHairline),
                    ),
                  ),
                  onSubmitted: (_) => _sendSms(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: colorPrimary),
                icon: _isSmsSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _isSmsSending ? null : _sendSms,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
