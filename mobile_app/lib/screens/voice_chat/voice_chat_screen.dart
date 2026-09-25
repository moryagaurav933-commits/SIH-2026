import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/llm_service.dart';
import 'camera_capture_sheet.dart';

import 'speech_bridge.dart' as speech_bridge;

/// Krishi Copilot (कृषि कॉपायलट) — Pure Dynamic AI Conversational Voice & Text Companion.
/// Zero predefined canned questions: evaluates all questions with 100% free-will Gemini 2.5 Flash.
/// Responds in natural human voice (Sherpa style) in the user's chosen language.
class VoiceChatScreen extends StatefulWidget {
  final String? initialContext;
  final String? initialDiseaseName;
  const VoiceChatScreen({
    super.key,
    this.initialContext,
    this.initialDiseaseName,
  });

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  // Active language configuration
  late String _activeLangCode; // e.g., 'hi', 'en', 'hinglish', 'pa', 'mr'
  late String _activeSpeechLocale; // e.g., 'hi-IN', 'en-IN', 'pa-IN', 'mr-IN'

  // State flags
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  bool _isAudioMuted = false;
  bool _initializedFromProvider = false;

  // Real-time transcribed text
  String _liveTranscription =
      'Tap the microphone to speak...\nमाइक पर टैप करके अपनी बोली में पूछें...';
  String _statusLine = 'Tap microphone to speak | बोलकर बात करें';

  // Animation controllers
  late AnimationController _waveformController;
  late AnimationController _pulseController;
  Timer? _sttPollingTimer;
  DateTime? _lastSpeechTimestamp;
  String _lastTranscribedText = '';

  // Conversation history
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  Uint8List? _attachedImageBytes;
  final ImagePicker _picker = ImagePicker();
  final LLMService _llmService = LLMService();

  // Supported regional languages for Krishi Copilot
  final List<Map<String, String>> _availableLanguages = [
    {'code': 'hi', 'locale': 'hi-IN', 'name': 'हिंदी'},
    {'code': 'hinglish', 'locale': 'hi-IN', 'name': 'Hinglish'},
    {'code': 'en', 'locale': 'en-IN', 'name': 'English'},
    {'code': 'pa', 'locale': 'pa-IN', 'name': 'ਪੰਜਾਬੀ'},
    {'code': 'mr', 'locale': 'mr-IN', 'name': 'मराठी'},
    {'code': 'ta', 'locale': 'ta-IN', 'name': 'தமிழ்'},
    {'code': 'te', 'locale': 'te-IN', 'name': 'తెలుగు'},
    {'code': 'bn', 'locale': 'bn-IN', 'name': 'বাংলা'},
    {'code': 'gu', 'locale': 'gu-IN', 'name': 'ગુજરાતી'},
    {'code': 'kn', 'locale': 'kn-IN', 'name': 'ಕನ್ನಡ'},
  ];

  @override
  void initState() {
    super.initState();
    _activeLangCode = 'hi';
    _activeSpeechLocale = 'hi-IN';

    // Waveform oscillating animation
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();

    // Pulsating microphone button animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromProvider) {
      // Inherit language chosen from Home screen language selection
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      _setLanguageByCode(langProvider.code, notify: false);

      // Initial friendly greeting in chosen language
      final greetingMsg = widget.initialContext != null
          ? _getDiagnosisGreetingText(_activeLangCode, widget.initialDiseaseName ?? 'फसल रोग')
          : _getGreetingText(_activeLangCode);
      _messages.add(
        ChatMessage(
          text: greetingMsg,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      _initializedFromProvider = true;
    }
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _pulseController.dispose();
    _sttPollingTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    _stopSpeechSynthesis();
    super.dispose();
  }


  String _getDiagnosisGreetingText(String code, String diseaseName) {
    switch (code) {
      case 'en':
        return "Hello! I have loaded your complete diagnosis report for $diseaseName. Feel free to ask me anything about CIBRC chemical spray dosage, organic remedies, soil health, or prevention steps!";
      case 'hinglish':
        return "Namaste! Maine aapke $diseaseName ka pura report load kar liya hai. Recommended spray dosage, desi/jaivik upchar ya bachav ke baare mein koi bhi sawal poochein!";
      case 'pa':
        return "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਕਿਸਾਨ ਵੀਰ! ਮੈਂ ਤੁਹਾਡੇ $diseaseName ਦੀ ਪੂਰੀ ਰਿਪੋਰਟ ਵੇਖ ਲਈ ਹੈ। ਦਵਾਈ ਦੇ ਛਿੜਕਾਅ, ਜੈਵਿਕ ਉਪਚਾਰ ਜਾਂ ਰੋਕਥਾਮ ਬਾਰੇ ਕੁਝ ਵੀ ਪੁੱਛੋ।";
      case 'mr':
        return "नमस्कार शेतकरी मित्रांनो! मी तुमच्या $diseaseName चे संपूर्ण निदान पाहिले आहे. औषध फवारणीचे प्रमाण, सेंद्रिय उपाय किंवा प्रतिबंधात्मक उपायांबद्दल काहीही विचारा.";
      case 'bn':
        return "নমস্কার! আমি আপনার $diseaseName এর সম্পূর্ণ রোগ রিপোর্ট বিশ্লেষণ করেছি। অনুমোদিত ওষুধ স্প্রে বা জৈব প্রতিকার সম্পর্কে যেকোনো প্রশ্ন করতে পারেন।";
      case 'gu':
        return "નમસ્તે ખેડૂત મિત્ર! મેં તમારા $diseaseName નો સંપૂર્ણ રિપોર્ટ જોયો છે. સ્પ્રેની માત્રા, જૈવિક ઉપચાર અથવા બચાવ વિશે ગમે તે પ્રશ્ન પૂછો.";
      case 'te':
        return "నమస్కారం! నేను మీ $diseaseName నిర్ధారణ నివేదికను చూశాను. రసాయన లేదా సేంద్రీయ నివారణ చర్యల గురించి నన్ను అడగండి.";
      case 'ta':
        return "வணக்கம் விவசாய தோழரே! உங்கள் $diseaseName நோய்க்கான முழு அறிக்கையை பார்த்துள்ளேன். மருந்தளவு அல்லது இயற்கை தீர்வுகள் பற்றி கேளுங்கள்.";
      case 'kn':
        return "ನಮಸ್ಕಾರ! ನಿಮ್ಮ $diseaseName ರೋಗದ ವರದಿಯನ್ನು ಪರಿಶೀಲಿಸಿದ್ದೇನೆ. ಔಷಧಿ ಸಿಂಪಡಣೆ ಪ್ರಮಾಣ ಅಥವಾ ಸಾವಯವ ಪರಿಹಾರಗಳ ಬಗ್ಗೆ ಯಾವುದೇ ಪ್ರಶ್ನೆಗಳನ್ನು ಕೇಳಿ.";
      case 'ur':
        return "سلام کسان بھائی! میں نے آپ کی $diseaseName کی تشخیص کی رپورٹ دیکھ لی ہے۔ اسپرے کے تناسب، نامیاتی علاج یا روک تھام کے بارے میں کوئی بھی سوال پوچھیں۔";
      default:
        return "नमस्ते किसान भाई! मैंने आपके $diseaseName के निदान का पूरा विवरण देख लिया है। CIBRC अनुमोदित स्प्रे मात्रा, जैविक समाधान या बचाव के उपायों के बारे में आप मुझसे सीधे पूछ सकते हैं।";
    }
  }

  String _getGreetingText(String code) {
    switch (code) {
      case 'en':
        return "Hello friend! I am Krishi Copilot. Ask me anything in your voice about your crops, fertilizers, disease symptoms, or weather.";
      case 'hinglish':
        return "Ram-ram bhai! Main Krishi Copilot hoon. Apni fasal, khad, beej ya mausam ke baare mein bolkar ya likhkar poochein.";
      case 'pa':
        return "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਕਿਸਾਨ ਵੀਰ! ਮੈਂ ਕ੍ਰਿਸ਼ੀ ਕੋਪਾਇਲਟ ਹਾਂ। ਆਪਣੀ ਫ਼ਸਲ, ਕੀੜੇ-ਮਕੌੜੇ ਜਾਂ ਮੰਡੀ ਬਾਰੇ ਬੋਲ ਕੇ ਪੁੱਛੋ।";
      case 'mr':
        return "राम-राम शेतकरी बांधवांनो! मी कृषी कॉपायलट आहे. पीक, खते किंवा रोगराईबद्दल बोलून विचारा.";
      case 'ta':
        return "வணக்கம் விவசாய தோழரே! நான் கிருஷி கோபைலட். உங்கள் பயிர் மற்றும் உரம் பற்றி பேசி கேளுங்கள்.";
      case 'te':
        return "నమస్కారం రైతు సోదరా! నేను కృషి కోపైలట్. పంటలు, ఎరువులు లేదా వాతావరణం గురించి అడగండి.";
      default:
        return "राम-राम किसान भाई! मैं कृषि कॉपायलट हूँ। माइक दबाकर अपनी फसल, खाद, रोग या मौसम के बारे में सीधे पूछें।";
    }
  }

  void _setLanguageByCode(String code, {bool notify = true}) {
    String matchedLocale = 'hi-IN';
    for (final l in _availableLanguages) {
      if (l['code'] == code) {
        matchedLocale = l['locale']!;
        break;
      }
    }

    _activeLangCode = code;
    _activeSpeechLocale = matchedLocale;

    if (notify && mounted) {
      setState(() {
        final label = _activeLangCode == 'en' ? 'Language updated' : 'भाषा चुनी गई';
        _statusLine = '$label | Tap microphone to speak';
      });
      _stopSpeechSynthesis();
    }
  }

  // ---------------------------------------------------------------------------
  // NATURAL HUMAN SPEECH SYNTHESIS (TTS)
  // ---------------------------------------------------------------------------
  void _stopSpeechSynthesis() {
    if (kIsWeb) {
      speech_bridge.bridgeCancelSpeech();
    }
  }

  void _speakText(String text) {
    if (_isAudioMuted) return;
    _stopSpeechSynthesis();

    setState(() {
      _isSpeaking = true;
      _statusLine = '🔊 Speaking... | उत्तर सुनिए...';
    });

    if (kIsWeb) {
      speech_bridge.bridgeSpeak(
        text: text,
        activeSpeechLocale: _activeSpeechLocale,
        activeLangCode: _activeLangCode,
      );
    }

    // Auto-calculate speaking timeout based on word count
    final wordCount = text.split(' ').length;
    final estimatedSeconds = (wordCount / 3.1).clamp(2.5, 14.0);

    Future.delayed(Duration(milliseconds: (estimatedSeconds * 1000).toInt()), () {
      if (mounted && _isSpeaking) {
        setState(() {
          _isSpeaking = false;
          _statusLine = 'Tap microphone to speak | बोलकर बात करें';
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // SPEECH RECOGNITION (STT) & DYNAMIC AI EVALUATION
  // ---------------------------------------------------------------------------
  void _toggleVoice() {
    if (_isListening) {
      // User manually stopped microphone: evaluate whatever was said immediately
      _stopVoice(evaluateIfNotEmpty: true);
    } else {
      _startVoice();
    }
  }

  void _startVoice() {
    _stopSpeechSynthesis();

    setState(() {
      _isListening = true;
      _isSpeaking = false;
      _lastSpeechTimestamp = null;
      _lastTranscribedText = '';
      _statusLine = '🔴 सुन रहा हूँ... अपनी पूरी बात कहें';
      _liveTranscription =
          'सुन रहा हूँ... बोलिए (माइक बंद करने पर या 5 सेकंड शांत रहने पर उत्तर मिलेगा)';
    });

    if (kIsWeb) {
      speech_bridge.bridgeStartListening(
        activeSpeechLocale: _activeSpeechLocale,
      );

      // Poll speech transcription every 100ms for real-time text and 5-second silence detection
      _sttPollingTimer?.cancel();
      _sttPollingTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted || !_isListening) {
          timer.cancel();
          return;
        }

        final currentText = speech_bridge.bridgeGetSpeechText();

        if (currentText.isNotEmpty) {
          // If words have updated / user is speaking
          if (currentText != _lastTranscribedText) {
            _lastTranscribedText = currentText;
            _lastSpeechTimestamp = DateTime.now();
            setState(() {
              _liveTranscription = currentText;
              _statusLine = '🔴 बोल रहे हैं... (सुन रहा हूँ)';
            });
          } else if (_lastSpeechTimestamp != null) {
            // User has paused: calculate elapsed silence duration
            final silenceElapsedMs = DateTime.now()
                .difference(_lastSpeechTimestamp!)
                .inMilliseconds;
            final remainingSilenceSec =
                ((5000 - silenceElapsedMs) / 1000).clamp(0.0, 5.0);

            if (silenceElapsedMs >= 1500 && silenceElapsedMs < 5000) {
              final statusMsg =
                  '⏳ शांति: ${remainingSilenceSec.toStringAsFixed(1)}s (रुकने पर उत्तर मिलेगा)';
              if (_statusLine != statusMsg) {
                setState(() {
                  _statusLine = statusMsg;
                });
              }
            }

            // Continuous 5-Second Silence Detected! Complete talk and evaluate!
            if (silenceElapsedMs >= 5000) {
              timer.cancel();
              _stopVoice();
              _processDynamicVoiceQuery(currentText);
              return;
            }
          }
        }
      });
    } else {
      // Mobile platform fallback
    }
  }

  void _stopVoice({bool evaluateIfNotEmpty = false}) {
    _sttPollingTimer?.cancel();
    String textToEvaluate = _lastTranscribedText;

    if (kIsWeb) {
      final t = speech_bridge.bridgeStopListening();
      if (t.isNotEmpty) textToEvaluate = t;
    }

    setState(() {
      _isListening = false;
      if (!_isSpeaking && !_isThinking) {
        _statusLine = 'Tap microphone to speak | बोलकर बात करें';
      }
    });

    if (evaluateIfNotEmpty && textToEvaluate.trim().isNotEmpty) {
      _processDynamicVoiceQuery(textToEvaluate.trim());
    }
  }

  /// 100% Free-Will AI Evaluation with Gemini 2.5 Flash in chosen language
  Future<void> _processDynamicVoiceQuery(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    setState(() {
      _liveTranscription = cleanText;
      _messages.add(
        ChatMessage(
          text: cleanText,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isThinking = true;
      _statusLine = '⚡ Evaluating your question... (विचार कर रहा है...)';
    });
    _scrollToBottom();

    // Build previous conversation turns for multi-turn conversational memory
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();
    if (widget.initialContext != null) {
      history.insert(0, {
        'role': 'user',
        'text': 'ACTIVE DIAGNOSIS CONTEXT: ${widget.initialContext!}',
      });
      history.insert(1, {
        'role': 'model',
        'text': 'Understood. I will provide accurate agronomic guidance tailored to this diagnosis.',
      });
    }

    // Call Gemini 2.5 Flash with 5-pillar agronomic Sherpa engine & chosen language
    final response = await _llmService.answerConversationalVoice(
      cleanText,
      _activeLangCode,
      conversationHistory: history,
    );

    if (mounted) {
      setState(() {
        _isThinking = false;
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();

      // Speak response aloud naturally like a human
      _speakText(response);
    }
  }

  // ---------------------------------------------------------------------------
  // TEXT & CAMERA CROP PHOTO HANDLING
  // ---------------------------------------------------------------------------
  Future<void> _openCameraModule() async {
    final Uint8List? capturedBytes = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CameraCaptureSheet(),
    );

    if (capturedBytes != null && mounted) {
      setState(() {
        _attachedImageBytes = capturedBytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📷 फसल की तस्वीर संलग्न कर दी गई है।'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        setState(() {
          _attachedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('तस्वीर लेने में त्रुटि: $e')),
        );
      }
    }
  }

  Future<void> _handleSendMessage(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty && _attachedImageBytes == null) return;

    final imageToSend = _attachedImageBytes;
    final textToSend = cleanQuery.isEmpty
        ? 'कृपया इस फसल/पत्ती का विश्लेषण कर रोग व उपचार बताएं।'
        : cleanQuery;

    setState(() {
      _messages.add(
        ChatMessage(
          text: textToSend,
          isUser: true,
          timestamp: DateTime.now(),
          imageBytes: imageToSend,
        ),
      );
      _isThinking = true;
      _attachedImageBytes = null;
      _textController.clear();
      _liveTranscription = textToSend;
    });
    _scrollToBottom();

    String? b64Image;
    if (imageToSend != null) {
      b64Image = base64Encode(imageToSend);
    }

    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();
    if (widget.initialContext != null) {
      history.insert(0, {
        'role': 'user',
        'text': 'ACTIVE DIAGNOSIS CONTEXT: ${widget.initialContext!}',
      });
      history.insert(1, {
        'role': 'model',
        'text': 'Understood. I will provide accurate agronomic guidance tailored to this diagnosis.',
      });
    }

    final response = await _llmService.answerConversationalVoice(
      textToSend,
      _activeLangCode,
      imageBase64: b64Image,
      conversationHistory: history,
    );

    if (mounted) {
      setState(() {
        _isThinking = false;
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();

      // Read answer aloud naturally
      _speakText(response);
    }
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

  // ---------------------------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040C06),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1C0F),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4ADE80), width: 1),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Color(0xFF4ADE80), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Krishi Copilot',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'AI कृषक साथी · ${_getLanguageDisplayName(_activeLangCode)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF86EFAC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Audio Mute / Speaker toggle
          IconButton(
            icon: Icon(
              _isAudioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: _isAudioMuted ? Colors.redAccent : const Color(0xFF4ADE80),
              size: 22,
            ),
            tooltip: _isAudioMuted ? 'Unmute voice' : 'Mute voice',
            onPressed: () {
              setState(() {
                _isAudioMuted = !_isAudioMuted;
                if (_isAudioMuted) _stopSpeechSynthesis();
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // ─── 1. LANGUAGE SELECTOR PILLS ───
          _buildLanguageSelector(),

          // ─── 2. KRISHI COPILOT VOICE CENTERPIECE PANEL ───
          _buildVoiceCenterpiece(),

          // ─── 3. CONTINUOUS CONVERSATION STREAM ───
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Krishi Copilot विचार कर रहा है...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA5D6A7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Attached Image Preview Bar
          if (_attachedImageBytes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF142417),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _attachedImageBytes!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📷 फसल की तस्वीर संलग्न है',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'AI मॉडल रोग का सटीक निदान करेगा',
                          style: TextStyle(fontSize: 10, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.redAccent, size: 20),
                    onPressed: () {
                      setState(() => _attachedImageBytes = null);
                    },
                  ),
                ],
              ),
            ),

          // ─── 4. BOTTOM INPUT BAR (TEXT & PHOTO) ───
          _buildBottomInputBar(),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    for (final l in _availableLanguages) {
      if (l['code'] == code) return l['name']!;
    }
    return 'हिंदी';
  }

  // ---------------------------------------------------------------------------
  // 1. LANGUAGE SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildLanguageSelector() {
    return Container(
      color: const Color(0xFF0A1C0F),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _availableLanguages.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final lang = _availableLanguages[index];
            final isActive = _activeLangCode == lang['code'];

            return InkWell(
              onTap: () => _setLanguageByCode(lang['code']!),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2E7D32)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.16),
                    width: isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    lang['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. KRISHI COPILOT VOICE CENTERPIECE (7-BAR WAVE + 72px GLOWING MIC)
  // ---------------------------------------------------------------------------
  Widget _buildVoiceCenterpiece() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.6),
          radius: 1.2,
          colors: [
            Color(0x404CAF50), // Green radial highlight
            Color(0xFF0C2214),
            Color(0xFF040C06),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 7 Animated Waveform Bars
          _buildWaveformBars(),
          const SizedBox(height: 14),

          // 72px Circular Glowing Mic Button
          _buildMicButton(),
          const SizedBox(height: 10),

          // Status Line
          Text(
            _statusLine,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xCCFFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // Live Transcription Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              _liveTranscription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE8F5E9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformBars() {
    final isActive = _isListening || _isSpeaking;
    final delays = [0.05, 0.12, 0.24, 0.36, 0.24, 0.12, 0.05];

    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final t = _waveformController.value;
            final phase = delays[index] * 2 * math.pi;
            final scale = isActive
                ? (0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * t + phase)))
                : 0.25;
            final height = 24.0 * scale;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 4.5,
              height: height.clamp(6.0, 24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                borderRadius: BorderRadius.circular(2.5),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.55),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final isRed = _isListening;
        final pulseVal = _pulseController.value;

        return GestureDetector(
          onTap: _toggleVoice,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isRed
                  ? const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 3,
              ),
              boxShadow: [
                if (isRed)
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.7 * pulseVal),
                    blurRadius: 20 * pulseVal,
                    spreadRadius: 4 * pulseVal,
                  )
                else
                  BoxShadow(
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: isRed
                  ? const Icon(Icons.stop_rounded,
                      color: Colors.white, size: 36)
                  : const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 36),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CONVERSATION MESSAGE BUBBLE
  // ---------------------------------------------------------------------------
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1E4620) : const Color(0xFF0F2012),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                  width: 1,
                ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.psychology_rounded,
                  size: 13,
                  color: isUser ? Colors.white70 : const Color(0xFF69F0AE),
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? 'आप (Farmer)' : 'कृषि कॉपायलट',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.white70 : const Color(0xFF69F0AE),
                  ),
                ),
                if (!isUser) ...[
                  const Spacer(),
                  InkWell(
                    onTap: () => _speakText(message.text),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _isSpeaking
                            ? Icons.volume_up_rounded
                            : Icons.play_arrow_rounded,
                        size: 16,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            if (message.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    message.imageBytes!,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            SelectableText(
              message.text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),

            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 8.5, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. BOTTOM INPUT BAR (TEXT & CAMERA)
  // ---------------------------------------------------------------------------
  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0C170E),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Camera snap button (Live Camera Module)
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF4ADE80), size: 22),
              tooltip: 'कैमरे से फोटो लें (लाइव कैमरा)',
              onPressed: _openCameraModule,
            ),

            // Gallery pick button
            IconButton(
              icon: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFFA5D6A7), size: 22),
              tooltip: 'गैलरी से फोटो चुनें',
              onPressed: () => _pickImage(ImageSource.gallery),
            ),

            // Text input
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(fontSize: 13.5, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'अपनी बोली में पूछें / Ask anything...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF162819),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _handleSendMessage,
              ),
            ),
            const SizedBox(width: 4),

            // Send button
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF4ADE80)),
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
  final Uint8List? imageBytes;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageBytes,
  });
}
