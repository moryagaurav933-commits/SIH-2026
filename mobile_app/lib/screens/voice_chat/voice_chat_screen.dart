import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_config.dart';
import '../../services/llm_service.dart';
import '../../services/device_permission_service.dart';
import '../../widgets/permission_palette_dialog.dart';
import 'camera_capture_sheet.dart';
import 'speech_bridge.dart' as speech_bridge;

/// Krishi Copilot (कृषि कॉपायलट) — Pure Dynamic AI Conversational Voice & Text Companion.
/// Zero predefined canned questions: evaluates all questions with 100% free-will Gemini 2.5 Flash.
/// Responds in natural human voice in the user's chosen language.
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
  bool _isSpeaking = false;
  bool _isThinking = false;
  bool _isAudioMuted = false;
  bool _initializedFromProvider = false;

  // Voice recording state in bottom bar
  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Animation controller for mic pulsation while recording
  late AnimationController _pulseController;

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

    // Pulsating microphone button animation during recording
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    _pulseController.dispose();
    _recordingTimer?.cancel();
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
      default:
        return "नमस्ते किसान भाई! मैंने आपके $diseaseName के निदान का पूरा विवरण देख लिया है। CIBRC अनुमोदित स्प्रे मात्रा, जैविक समाधान या बचाव के उपायों के बारे में आप मुझसे सीधे पूछ सकते हैं।";
    }
  }

  String _getEmptyVoiceMessage(String code) {
    switch (code) {
      case 'en':
        return 'No clear speech was detected. Please tap the mic and speak clearly.';
      case 'hinglish':
        return 'Koi saaf aawaz nahi sunai di. Kripya dubara mic dabakar bolein.';
      case 'pa':
        return 'ਕੋਈ ਆਵਾਜ਼ ਨਹੀਂ ਸੁਣੀ ਗਈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਮਾਈਕ ਦਬਾ ਕੇ ਬੋਲੋ।';
      case 'mr':
        return 'कोणताही स्पष्ट आवाज ऐकू आला नाही. कृपया पुन्हा माइक दाबून बोला.';
      case 'ta':
        return 'குரல் கேட்கவில்லை. தயவுசெய்து மீண்டும் மைக் அழுத்திப் பேசுங்கள்.';
      case 'te':
        return 'స్పష్టమైన శబ్దం వినపడలేదు. దయచేసి మళ్లీ మైక్ నొక్కి మాట్లాడండి.';
      case 'bn':
        return 'কোনো স্পষ্ট কণ্ঠস্বর শোনা যায়নি। দয়া করে আবার মাইক চেপে কথা বলুন।';
      case 'gu':
        return 'કોઈ સ્પષ્ટ અવાજ સંભળાયો નથી. કૃપા કરીને ફરીથી માઇક દબાવીને બોલો.';
      case 'kn':
        return 'ಯಾವುದೇ ಧ್ವನಿ ಕೇಳಿಸಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೊಮ್ಮೆ ಮೈಕ್ ಒತ್ತಿ ಮಾತನಾಡಿ.';
      default:
        return 'कोई स्पष्ट आवाज़ नहीं सुनाई दी। कृपया दोबारा माइक दबाकर स्पष्ट आवाज़ में बोलें।';
    }
  }

  String _getGreetingText(String code) {
    switch (code) {
      case 'en':
        return "Hello! I am Krishi Copilot. Tap the microphone to ask anything about your crops, fertilizers, pest remedies, or weather.";
      case 'hinglish':
        return "Ram-ram! Main Krishi Copilot hoon. Mic dabakar apni fasal, khad, bimari ya mausam ke baare mein poochein.";
      case 'pa':
        return "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਕਿਸਾਨ ਵੀਰ! ਮੈਂ ਕ੍ਰਿਸ਼ੀ ਕੋਪਾਇਲਟ ਹਾਂ। ਮਾਈਕ ਦਬਾ ਕੇ ਆਪਣੀ ਫ਼ਸਲ, ਖਾਦ ਜਾਂ ਕੀੜੇ-ਮਕੌੜਿਆਂ ਬਾਰੇ ਪੁੱਛੋ।";
      case 'mr':
        return "नमस्कार शेतकरी मित्रांनो! मी कृषी कॉपायलट आहे. माइक दाबून आपल्या पिकांबद्दल, खतांबद्दल किंवा रोगांबद्दल थेट विचारा.";
      case 'ta':
        return "வணக்கம் விவசாய தோழரே! நான் கிருஷி கோபைலட். மைக் அழுத்தி உங்கள் பயிர், உரம் அல்லது வானிலை பற்றி கேளுங்கள்.";
      case 'te':
        return "నమస్కారం రైతు సోదరా! నేను కృషి కోపైలట్. మైక్ నొక్కి మీ పంటలు, ఎరువులు లేదా వాతావరణం గురించి అడగండి.";
      case 'bn':
        return "নমস্কার কৃষক বন্ধু! আমি কৃষি কোপাইলট। মাইক চেপে আপনার ফসল, সার বা রোগ সম্পর্কে সরাসরি জিজ্ঞাসা করুন।";
      case 'gu':
        return "નમસ્તે ખેડૂત મિત્ર! હું કૃષિ કૉપાયલટ છું. માઇક દબાવીને તમારા પાક, ખાતર કે રોગ વિશે સીધું પૂછો.";
      case 'kn':
        return "ನಮಸ್ಕಾರ ರೈತ ಮಿತ್ರರೇ! ನಾನು ಕೃಷಿ ಕೋಪೈಲಟ್. ಮೈಕ್ ಒತ್ತಿ ನಿಮ್ಮ ಬೆಳೆ, ಗೊಬ್ಬರ ಅಥವಾ ರೋಗಗಳ ಬಗ್ಗೆ ನೇರವಾಗಿ ಕೇಳಿ.";
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
        _messages.add(
          ChatMessage(
            text: _getGreetingText(_activeLangCode),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
      _stopSpeechSynthesis();
      _speakText(_getGreetingText(_activeLangCode));
    }
  }

  // ---------------------------------------------------------------------------
  // NATURAL HUMAN SPEECH SYNTHESIS (TTS)
  // ---------------------------------------------------------------------------
  void _stopSpeechSynthesis() {
    speech_bridge.bridgeCancelSpeech();
    if (mounted && _isSpeaking) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  void _speakText(String text) {
    if (_isAudioMuted) return;
    _stopSpeechSynthesis();

    setState(() {
      _isSpeaking = true;
    });

    final cleanSpeech = text
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('`', '')
        .replaceAll('•', '')
        .replaceAll('- ', '')
        .trim();

    speech_bridge.bridgeSpeak(
      text: cleanSpeech,
      activeSpeechLocale: _activeSpeechLocale,
      activeLangCode: _activeLangCode,
    );

    final wordCount = cleanSpeech.split(' ').length;
    final estimatedSeconds = (wordCount / 2.8).clamp(3.0, 25.0);

    Future.delayed(Duration(milliseconds: (estimatedSeconds * 1000).toInt()), () {
      if (mounted && _isSpeaking) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // AUDIO RECORDING & AUTO-TRANSCRIBE TO INPUT BAR LOGIC
  // ---------------------------------------------------------------------------
  Future<void> _toggleAudioRecord() async {
    if (_isRecording) {
      // User tapped mic while recording -> STOP recording and TRANSCRIBE into the Ask Something bar!
      await _stopAndTranscribeToInputBar();
    } else {
      // User tapped mic while idle -> START recording speech
      await _startAudioRecord();
    }
  }

  Future<void> _startAudioRecord() async {
    final hasMic = await DevicePermissionService.requestMicrophone();
    if (!hasMic) {
      if (mounted) PermissionPaletteDialog.show(context);
      return;
    }

    _stopSpeechSynthesis();

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecording) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });

    // Start recording on host backend via ffmpeg (await so it launches immediately)
    try {
      final uri = Uri.parse(ApiConfig.voiceRecordStartUrl);
      final res = await http.post(uri).timeout(const Duration(seconds: 3));
      debugPrint('Voice record start response: ${res.statusCode}');
    } catch (e) {
      debugPrint('Voice record start error: $e');
    }

    // If running in Web browser, also trigger Web Speech API
    if (kIsWeb) {
      speech_bridge.bridgeStartListening(activeSpeechLocale: _activeSpeechLocale);
    }
  }

  /// Stops recording and immediately transcribes the speech into the Ask Something text field
  /// so the farmer can review, edit, or correct any errors before clicking submit.
  Future<void> _stopAndTranscribeToInputBar() async {
    _recordingTimer?.cancel();

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    try {
      final uri = Uri.parse(ApiConfig.voiceRecordStopUrl);
      final res = await http.post(uri).timeout(const Duration(seconds: 4));
      debugPrint('Voice record stop response: ${res.statusCode}');
    } catch (e) {
      debugPrint('Voice record stop error: $e');
    }

    if (kIsWeb) {
      speech_bridge.bridgeStopListening();
    }

    // Brief 300ms pause to allow ffmpeg process to cleanly finalize WAV headers
    await Future.delayed(const Duration(milliseconds: 300));

    String? webSpeechText;
    if (kIsWeb) {
      webSpeechText = speech_bridge.bridgeGetSpeechText();
    }

    try {
      final uri = Uri.parse(ApiConfig.voiceTranscribeUrl);
      final body = {
        'language': _activeLangCode,
        'language_name': _getLanguageDisplayName(_activeLangCode),
        'audio_base64': null,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transcription = (data['transcription'] ?? '').toString().trim();
        if (transcription.isNotEmpty &&
            !transcription.contains('Unclear Audio') &&
            !transcription.contains('स्पष्ट नहीं')) {
          if (mounted) {
            setState(() {
              _isTranscribing = false;
              _textController.text = transcription;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Voice transcribe error: $e');
    }

    // Fallback: Web speech API transcribed text if available
    if (webSpeechText != null && webSpeechText.trim().isNotEmpty) {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _textController.text = webSpeechText!.trim();
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isTranscribing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getEmptyVoiceMessage(_activeLangCode)),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF1E3A24),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelAudioRecord() async {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isTranscribing = false;
      _recordingSeconds = 0;
    });

    try {
      final uri = Uri.parse(ApiConfig.voiceRecordStopUrl);
      await http.post(uri).timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (kIsWeb) {
      speech_bridge.bridgeStopListening();
    }
  }

  // ---------------------------------------------------------------------------
  // SUBMIT / SEND HANDLER (IMAGE 3)
  // ---------------------------------------------------------------------------
  Future<void> _handleSendAction() async {
    // If the user tapped Send while recording was still active, stop & transcribe into text field first
    // so they can review and edit before final sending:
    if (_isRecording) {
      await _stopAndTranscribeToInputBar();
      return;
    }

    if (_isTranscribing) return;

    // Send verified/edited question from text bar
    final text = _textController.text.trim();
    if (text.isNotEmpty || _attachedImageBytes != null) {
      await _handleSendMessage(text);
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
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📷 फसल की तस्वीर संलग्न कर दी गई है।'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('तस्वीर लेने में त्रुटि: $e'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
          // Hardware Permissions Palette button
          IconButton(
            icon: const Icon(Icons.security_rounded, color: Color(0xFF4ADE80), size: 20),
            tooltip: 'हार्डवेयर अनुमतियां (Hardware Permissions)',
            onPressed: () => PermissionPaletteDialog.show(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // ─── 1. LANGUAGE SELECTOR PILLS ───
          _buildLanguageSelector(),

          // ─── 2. CONTINUOUS CONVERSATION STREAM (FULL SCREEN CLEAN EXPANDED) ───
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

          // ─── 3. RECORDING STATUS STRIP (ACTIVE OR TRANSCRIBING) ───
          if (_isRecording || _isTranscribing)
            _buildRecordingStatusStrip(),

          // ─── 4. BOTTOM INPUT BAR (TEXT, CAMERA, MIC, SEND) ───
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
  // 2. CONVERSATION MESSAGE BUBBLE (CLEAN - IMAGE 4 HEADER REMOVED)
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
  // 3. RECORDING STATUS STRIP
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 3. RECORDING STATUS STRIP
  // ---------------------------------------------------------------------------
  Widget _buildRecordingStatusStrip() {
    if (!_isRecording && !_isTranscribing) {
      return const SizedBox.shrink();
    }

    if (_isTranscribing) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F291E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4ADE80),
            width: 1,
          ),
        ),
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
            Expanded(
              child: Text(
                '✨ आवाज़ से शब्द लिखे जा रहे हैं... (Converting speech to text...)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF86EFAC),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final mins = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_recordingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '🎙️ बोलिए... आवाज़ रिकॉर्ड हो रही है ($mins:$secs) · रोकने के लिए माइक दबाएं',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFECACA),
              ),
            ),
          ),
          InkWell(
            onTap: _cancelAudioRecord,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, color: Colors.white70, size: 14),
                  SizedBox(width: 4),
                  Text('रद्द करें', style: TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. BOTTOM INPUT BAR (TEXT, CAMERA, MIC, SEND)
  // ---------------------------------------------------------------------------
  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0C170E),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Camera snap button
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF4ADE80), size: 22),
              tooltip: 'कैमरे से फोटो लें',
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
                enabled: !_isTranscribing,
                style: const TextStyle(fontSize: 13.5, color: Colors.white),
                decoration: InputDecoration(
                  hintText: _isTranscribing
                      ? '✨ आवाज़ से शब्द लिखे जा रहे हैं...'
                      : _isRecording
                          ? '🎙️ बोलिए... आवाज़ रिकॉर्ड हो रही है...'
                          : 'अपनी बोली में पूछें / Ask anything...',
                  hintStyle: TextStyle(
                    color: _isTranscribing
                        ? const Color(0xFF86EFAC)
                        : _isRecording
                            ? const Color(0xFFFCA5A5)
                            : Colors.white38,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF162819),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _handleSendAction(),
              ),
            ),
            const SizedBox(width: 6),

            // 🎤 Audio / Mic button (Image 2)
            _buildAudioRecordButton(),

            const SizedBox(width: 4),

            // 🚀 Send / Submit button (Image 3)
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. AUDIO / MIC BUTTON (IMAGE 2)
  // ---------------------------------------------------------------------------
  Widget _buildAudioRecordButton() {
    if (_isTranscribing) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0F291E),
          border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4ADE80),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        Color bgColor;
        Color iconColor;
        IconData iconData;
        String tooltip;
        BoxBorder? border;
        List<BoxShadow>? shadows;

        if (_isRecording) {
          bgColor = const Color(0xFFDC2626);
          iconColor = Colors.white;
          iconData = Icons.stop_rounded;
          tooltip = 'रिकॉर्डिंग रोकें और लिखें (Stop & Convert to Text)';
          border = Border.all(color: Colors.white, width: 2);
          shadows = [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.5 + 0.4 * pulse),
              blurRadius: 10 + 6 * pulse,
              spreadRadius: 1 + 2 * pulse,
            ),
          ];
        } else {
          bgColor = const Color(0xFF1B4332);
          iconColor = const Color(0xFF4ADE80);
          iconData = Icons.mic_rounded;
          tooltip = 'आवाज़ रिकॉर्ड करें (Tap to speak)';
          border = Border.all(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
            width: 1,
          );
        }

        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: _toggleAudioRecord,
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: border,
                boxShadow: shadows,
              ),
              child: Center(
                child: Icon(iconData, color: iconColor, size: 22),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 6. SEND / SUBMIT BUTTON (IMAGE 3)
  // ---------------------------------------------------------------------------
  Widget _buildSendButton() {
    return Tooltip(
      message: 'संदेश भेजें (Send message)',
      child: InkWell(
        onTap: _handleSendAction,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF15803D),
            border: Border.all(
              color: const Color(0xFF4ADE80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
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
