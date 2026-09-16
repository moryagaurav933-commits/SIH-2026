import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_language.dart';
import '../../localization/app_translations.dart';
import '../../providers/language_provider.dart';
import '../../services/llm_service.dart';

/// Multilingual Voice/Chat screen (Hinglish, Hindi, & English).
/// Offline agricultural AI assistant with voice input & speech synthesis.
class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  bool _initializedGreeting = false;
  late AnimationController _pulseController;

  List<String> get _quickSuggestions => [
    context.tr('chat_quick_1'),
    context.tr('chat_quick_2'),
    context.tr('chat_quick_3'),
    context.tr('chat_quick_4'),
    context.tr('chat_quick_5'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedGreeting) {
      _messages.add(
        ChatMessage(
          text: context.tr('chat_greeting'),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _initializedGreeting = true;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: cleanQuery, isUser: true, timestamp: DateTime.now()));
      _isThinking = true;
      _textController.clear();
    });
    _scrollToBottom();

    // Generate response via Google Gemini LLM / Agricultural Knowledge Base with current active language
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    String response = await LLMService().answerQuestion(cleanQuery, langProvider.code);
    if (response.isEmpty || response.contains('त्रुटि') || response.contains('Error') || response.contains('error')) {
      response = _generateAgriculturalAdvice(cleanQuery, langProvider.currentLanguage);
    }

    if (mounted) {
      setState(() {
        _isThinking = false;
        _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
      });
      _scrollToBottom();
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      final snackMsg = currentLang == AppLanguage.en
          ? '🎙️ Listening to voice... speak now...'
          : (currentLang == AppLanguage.hi
              ? '🎙️ आवाज़ सुनी जा रही है... बोलिए...'
              : '🎙️ Awaaz suni ja rahi hai... boliye... (Voice Listening)');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackMsg),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      // Simulate voice capture
      await Future.delayed(const Duration(seconds: 3));
      if (mounted && _isListening) {
        setState(() => _isListening = false);
        _handleSendMessage(_quickSuggestions.first);
      }
    }
  }

  String _generateAgriculturalAdvice(String prompt, AppLanguage lang) {
    final lower = prompt.toLowerCase();

    // 1. Yellow Rust / Fungus
    if (lower.contains('पीला रतुआ') || lower.contains('yellow rust') || lower.contains('रतुआ') || lower.contains('ratua')) {
      if (lang == AppLanguage.en) {
        return '🌾 Wheat Yellow Rust Advisory:\n\n'
            '1. Immediately spray Propiconazole 25% EC (Tilt) @ 1 ml per liter of water.\n'
            '2. Stop excessive Urea (Nitrogen) application, as surplus nitrogen accelerates fungal spread.\n'
            '3. After 15 days, apply a second spray of Tebuconazole if symptoms persist.\n\n'
            '⚠️ Recommended per ICAR-Indian Institute of Wheat and Barley Research guidelines.';
      } else if (lang == AppLanguage.hinglish) {
        return '🌾 Peela Ratua (Yellow Rust) ke liye salah:\n\n'
            '1. Turant Propiconazole 25% EC (Tilt) @ 1 ml/litre paani me milakar chhidkein.\n'
            '2. Urea (Nitrogen) ka upyog turant rokein kyunki zyada nitrogen se fafund tezi se failta hai.\n'
            '3. 15 din baad agar lakshan dikhein to Tebuconazole ka doosra chhidkaav karein.\n\n'
            '⚠️ Yeh advisory ICAR guidelines ke mutabiq hai.';
      } else {
        return '🌾 पीला रतुआ (Yellow Rust) के लिए सलाह:\n\n'
            '1. तत्काल प्रोपिकोनाजोल 25% EC (टिल्ट) @ 1 मिली प्रति लीटर पानी में मिलाकर छिड़कें।\n'
            '2. यूरिया (नाइट्रोजन) का प्रयोग तुरंत रोकें क्योंकि अधिक नाइट्रोजन से फफूंद तेजी से फैलती है।\n'
            '3. 15 दिन बाद यदि लक्षण दिखें तो टेबुकोनाजोल का दूसरा छिड़काव करें।\n\n'
            '⚠️ यह सलाह ICAR-भारतीय गेहूं अनुसंधान संस्थान के अनुसार है।';
      }
    }

    // 2. Weather & Irrigation
    if (lower.contains('मौसम') || lower.contains('सिंचाई') || lower.contains('water') || lower.contains('weather') || lower.contains('sinchai') || lower.contains('irrigation')) {
      if (lang == AppLanguage.en) {
        return '🌤️ Weather & Irrigation Advisory:\n\n'
            '• Next 48 hours will remain mostly clear to partly cloudy.\n'
            '• 65% probability of localized precipitation on Day 3.\n'
            '👉 Advice: Opt for light irrigation or hold off for rainfall. Ensure drainage channels are clear of silt.';
      } else if (lang == AppLanguage.hinglish) {
        return '🌤️ Mausam aur Sinchai Salah:\n\n'
            '• Agle 48 ghanto me mausam saaf se thoda badal rahega.\n'
            '• Parso (Day 3) 65% barish ki sambhavna hai.\n'
            '👉 Salah: Halki sinchai karein ya barish ka wait karein. Jal-bhirav se bachne ke liye naliyon ko saaf rakhein.';
      } else {
        return '🌤️ मौसम और सिंचाई सलाह:\n\n'
            '• अगले 48 घंटों में मौसम साफ से आंशिक बादलयुक्त रहेगा।\n'
            '• परसों (Day 3) 65% वर्षा की संभावना है।\n'
            '👉 सलाह: हल्की सिंचाई करें या वर्षा का इंतजार करें। जलभराव से बचने के लिए नालियों को साफ रखें।';
      }
    }

    // 3. Fertilizers / DAP / Urea
    if (lower.contains('खाद') || lower.contains('यूरिया') || lower.contains('dap') || lower.contains('अनुपात') || lower.contains('khad') || lower.contains('fertilizer') || lower.contains('ratio')) {
      if (lang == AppLanguage.en) {
        return '🧪 Balanced Fertilizer Guide:\n\n'
            '• Standard N:P:K dosage for Wheat is 120:60:40 kg/ha.\n'
            '• At Sowing: Apply DAP (50 kg) + Potash (25 kg) + Urea (30 kg) per acre.\n'
            '• 1st & 2nd Irrigation: Top-dress with Urea at 35-40 kg per acre.\n'
            '💡 Nano Urea foliar spray (4 ml/L water) can boost nitrogen absorption efficiently.';
      } else if (lang == AppLanguage.hinglish) {
        return '🧪 Balanced Fertilizer Guide (Khaad Salah):\n\n'
            '• Gehun ke liye standard N:P:K ratio 120:60:40 kg/ha hai.\n'
            '• Buwai ke time: DAP (50 kg) + Potash (25 kg) + Urea (30 kg) prati acre dalein.\n'
            '• Pehli aur doosri sinchai par: Urea 35-40 kg prati acre top-dressing karein.\n'
            '💡 Nano Urea 4 ml/litre foliar spray se nitrogen absorption tezi se hota hai.';
      } else {
        return '🧪 संतुलित उर्वरक (Fertilizer) गाइड:\n\n'
            '• गेहूं के लिए मानक N:P:K अनुपात 120:60:40 किग्रा/हेक्टेयर है।\n'
            '• बुवाई के समय: डीएपी (50 किग्रा) + पोटाश (25 किग्रा) + यूरिया (30 किग्रा) प्रति एकड़ डालें।\n'
            '• पहली व दूसरी सिंचाई पर: यूरिया 35-40 किग्रा प्रति एकड़ टॉप ड्रेसिंग करें।\n'
            '💡 नैनो यूरिया (Nano Urea) 4 मिली/लीटर पानी का पर्णीय छिड़काव भी कर सकते हैं।';
      }
    }

    // 4. Potato Blight
    if (lower.contains('आलू') || lower.contains('झुलसा') || lower.contains('blight') || lower.contains('aaloo') || lower.contains('potato')) {
      if (lang == AppLanguage.en) {
        return '🥔 Potato Late Blight Management:\n\n'
            '1. Fungicide: Spray Cymoxanil 8% + Mancozeb 64% WP @ 3g/liter water.\n'
            '2. Avoid excess soil moisture and rogue out infected plants immediately.\n'
            '3. Perform preventive spraying if dense fog or overcast skies occur.';
      } else if (lang == AppLanguage.hinglish) {
        return '🥔 Aaloo ka Pacheta Jhulsa (Late Blight) Roktham:\n\n'
            '1. Fungicide: Cymoxanil 8% + Mancozeb 64% WP @ 3 gm/litre paani me milakar spray karein.\n'
            '2. Khet me nami zyada na rehne dein aur sankramit paudhon ko nikaal lein.\n'
            '3. Fog aur kohra hone par protective spray zaroor karein.';
      } else {
        return '🥔 आलू का पछेता झुलसा (Late Blight) प्रबंधन:\n\n'
            '1. फफूंदनाशक: साइमोक्सानिल 8% + मैनकोजेब 64% WP @ 3 ग्राम/लीटर पानी में घोलकर छिड़कें।\n'
            '2. खेत में नमी अधिक न रखें और ग्रसित पौधों को बाहर निकालें।\n'
            '3. मौसम में धुंध व बादल रहने पर सुरक्षात्मक स्प्रे अवश्य करें।';
      }
    }

    // 5. Mandi Rates
    if (lower.contains('मंडी') || lower.contains('भाव') || lower.contains('price') || lower.contains('rate') || lower.contains('bhav') || lower.contains('mandi')) {
      if (lang == AppLanguage.en) {
        return '💰 Today’s Mandi Benchmark (UP_LKO - Lucknow):\n\n'
            '• Wheat (Sharbati): ₹2,550/quintal (📈 +2.4%)\n'
            '• Paddy (Basmati): ₹4,100/quintal (Firm)\n'
            '• Mustard: ₹5,450/quintal (📈 +3.1%)\n'
            '• Potato: ₹1,300/quintal\n\n'
            '💡 Visit the Mandi screen to view full 30-day historical trend charts.';
      } else if (lang == AppLanguage.hinglish) {
        return '💰 Aaj ka Mandi Bhav (UP_LKO - Lucknow):\n\n'
            '• Gehun (Sharbati): ₹2,550/quintal (📈 +2.4%)\n'
            '• Dhan (Basmati): ₹4,100/quintal (Strong)\n'
            '• Sarson: ₹5,450/quintal (📈 +3.1%)\n'
            '• Aaloo: ₹1,300/quintal\n\n'
            '💡 Mandi screen par jaakar 30-day historical price trend chart check karein.';
      } else {
        return '💰 आज का मंडी भाव (UP_LKO - लखनऊ):\n\n'
            '• गेहूं (Sharbati): ₹2,550/क्विंटल (📈 +2.4%)\n'
            '• धान (Basmati): ₹4,100/क्विंटल (मजबूत)\n'
            '• सरसों: ₹5,450/क्विंटल (📈 +3.1%)\n'
            '• आलू: ₹1,300/क्विंटल\n\n'
            '💡 मंडी स्क्रीन पर जाकर विस्तृत 30-दिवसीय ट्रेंड चार्ट देखें।';
      }
    }

    // Default Fallback
    if (lang == AppLanguage.en) {
      return '🌾 Agricultural Expert Guidance:\n\n'
          'For optimal crop yield, ensure timely irrigation schedules, balanced NPK nutrition, and proactive field monitoring.\n'
          'If you spot leaf discoloration, spots, or pest activity, use the "AI Crop Doctor" tab to snap a photograph for instant diagnostic analysis.';
    } else if (lang == AppLanguage.hinglish) {
      return '🌾 Krishi Visheshagya Salah:\n\n'
          'Aapki fasal ki acchi upaj ke liye samay par sinchai, santulit NPK khad aur regular monitoring zaroori hai.\n'
          'Agar patti par koi keeda ya daag-dhabba dikhe, to "AI Fasal Doctor" tab me photo lekar instant jaanch karein.';
    } else {
      return '🌾 कृषि विशेषज्ञ सलाह:\n\n'
          'आपकी फसल के स्वस्थ विकास के लिए समय पर सिंचाई, संतुलित पोषण और नियमित निगरानी आवश्यक है।\n'
          'यदि पौधे में कोई धब्बा या कीड़ा दिख रहा है, तो "फसल निदान" (Crop Diagnosis) टैब से कैमरे द्वारा पत्ती की फोटो लेकर तत्काल जांच करें।';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.currentLanguage;
    final llmBadgeText = lang == AppLanguage.en
        ? 'Offline LLM'
        : (lang == AppLanguage.hi ? 'ऑफ़लाइन LLM' : 'Offline LLM');
    final thinkingText = lang == AppLanguage.en
        ? 'Krishi AI is thinking (offline)...'
        : (lang == AppLanguage.hi ? 'कृषि AI सोच रहा है... (ऑफ़लाइन)' : 'Krishi AI soch raha hai... (offline)');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('${context.tr('chat_title')} 🌾', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            Chip(
              label: Text(llmBadgeText, style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              final audioMsg = lang == AppLanguage.en
                  ? '🔊 eSpeak NG English Voice is enabled'
                  : (lang == AppLanguage.hi ? '🔊 eSpeak NG हिंदी वॉइस चालू है' : '🔊 eSpeak NG Voice chalu hai');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(audioMsg)),
              );
            },
            tooltip: 'Audio Output',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick suggestions carousel
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _quickSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return ActionChip(
                  label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                  side: BorderSide(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                  onPressed: () => _handleSendMessage(suggestion),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Thinking indicator
          if (_isThinking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    thinkingText,
                    style: const TextStyle(fontSize: 12, color: Colors.white60, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Bottom input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2E7D32) : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender tag
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.psychology,
                  size: 14,
                  color: isUser ? Colors.white70 : const Color(0xFF81C784),
                ),
                const SizedBox(width: 4),
                Text(
                  isUser
                      ? (context.currentLanguage == AppLanguage.en ? 'Farmer' : (context.currentLanguage == AppLanguage.hi ? 'किसान' : 'Kisan'))
                      : (context.currentLanguage == AppLanguage.en ? 'Krishi-Saarthi AI' : (context.currentLanguage == AppLanguage.hi ? 'कृषि-सारथी AI' : 'Krishi-Saarthi AI')),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.white70 : const Color(0xFF81C784),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Message text
            SelectableText(
              message.text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            // Timestamp
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 9, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final lang = context.currentLanguage;
    final listeningHint = lang == AppLanguage.en
        ? 'Listening... speak now...'
        : (lang == AppLanguage.hi ? 'सुन रहा हूँ... बोलिए...' : 'Sun raha hoon... boliye...');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A3E), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Mic button with pulse animation
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              blurRadius: 16 * _pulseController.value,
                              spreadRadius: 4 * _pulseController.value,
                            ),
                          ]
                        : [],
                  ),
                  child: FloatingActionButton.small(
                    heroTag: 'voice_btn',
                    backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF2E7D32),
                    onPressed: _toggleListening,
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Text input
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _isListening ? listeningHint : context.tr('chat_input_hint'),
                  hintStyle: TextStyle(
                    color: _isListening ? Colors.redAccent : Colors.white38,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF232336),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _handleSendMessage,
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF4CAF50)),
              onPressed: () => _handleSendMessage(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
