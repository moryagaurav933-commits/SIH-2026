import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../providers/language_provider.dart';
import '../services/device_permission_service.dart';

/// Krishi-Saarthi Hardware Permission Palette Dialog & Modal
/// Prominently requests and manages Camera, Microphone, and GPS permissions
/// for Desktop (macOS) and Mobile platforms with 10-language dynamic localization.
class PermissionPaletteDialog extends StatefulWidget {
  final VoidCallback? onPermissionsUpdated;

  const PermissionPaletteDialog({
    super.key,
    this.onPermissionsUpdated,
  });

  /// Static helper to show as a modal dialog
  static Future<void> show(BuildContext context,
      {VoidCallback? onPermissionsUpdated}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PermissionPaletteDialog(
        onPermissionsUpdated: onPermissionsUpdated,
      ),
    );
  }

  /// Static helper to check whether all core permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    return await DevicePermissionService.areAllGranted();
  }

  @override
  State<PermissionPaletteDialog> createState() =>
      _PermissionPaletteDialogState();
}

class _PermissionPaletteDialogState extends State<PermissionPaletteDialog> {
  // Theme Colors
  static const Color colorPrimary = Color(0xFF2E7D32);
  static const Color colorForest = Color(0xFF1B5E20);
  static const Color colorAmber = Color(0xFFE65100);
  static const Color colorBorder = Color(0xFFE0E8E0);

  bool _isChecking = true;
  bool _isRequestingAll = false;
  bool _hasCamera = false;
  bool _hasMicrophone = false;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _checkStatuses();
  }

  Future<void> _checkStatuses() async {
    setState(() => _isChecking = true);
    try {
      final cam = await DevicePermissionService.checkCamera();
      final mic = await DevicePermissionService.checkMicrophone();
      final loc = await DevicePermissionService.checkLocation();

      if (mounted) {
        setState(() {
          _hasCamera = cam;
          _hasMicrophone = mic;
          _hasLocation = loc;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _requestCamera() async {
    try {
      final granted = await DevicePermissionService.requestCamera();
      if (mounted) {
        setState(() => _hasCamera = granted);
        widget.onPermissionsUpdated?.call();
      }
    } catch (e) {
      debugPrint('Camera request error: $e');
    }
  }

  Future<void> _requestMicrophone() async {
    try {
      final granted = await DevicePermissionService.requestMicrophone();
      if (mounted) {
        setState(() => _hasMicrophone = granted);
        widget.onPermissionsUpdated?.call();
      }
    } catch (e) {
      debugPrint('Mic request error: $e');
    }
  }

  Future<void> _requestLocation() async {
    try {
      final granted = await DevicePermissionService.requestLocation();
      if (mounted) {
        setState(() => _hasLocation = granted);
        widget.onPermissionsUpdated?.call();
      }
    } catch (e) {
      debugPrint('Location request error: $e');
    }
  }

  Future<void> _requestAll() async {
    setState(() => _isRequestingAll = true);
    try {
      final results = await DevicePermissionService.requestAll();
      if (mounted) {
        setState(() {
          _hasCamera = results['camera'] ?? false;
          _hasMicrophone = results['microphone'] ?? false;
          _hasLocation = results['location'] ?? false;
          _isRequestingAll = false;
        });
        widget.onPermissionsUpdated?.call();
      }
    } catch (e) {
      debugPrint('Request all error: $e');
      if (mounted) {
        setState(() => _isRequestingAll = false);
      }
    }
  }

  Future<void> _openSettings() async {
    await DevicePermissionService.openSettings();
    // After returning from system settings, re-check permission status
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      await _checkStatuses();
      widget.onPermissionsUpdated?.call();
    }
  }

  // ─── 10-Language Dictionary for Permission Palette ───
  String _t(String key, AppLanguage lang) {
    const Map<String, Map<AppLanguage, String>> strings = {
      'title': {
        AppLanguage.hinglish: 'Hardware Permissions',
        AppLanguage.hi: 'हार्डवेयर अनुमतियां',
        AppLanguage.en: 'Device Permissions',
        AppLanguage.bn: 'হার্ডওয়্যার অনুমতি',
        AppLanguage.gu: 'હાર્ડવેર પરવાનગીઓ',
        AppLanguage.mr: 'हार्डवेअर परवानग्या',
        AppLanguage.te: 'హార్డ్‌వేర్ అనుమతులు',
        AppLanguage.ta: 'வன்பொருள் அனுமதிகள்',
        AppLanguage.ur: 'ہارڈ ویئر اجازتیں',
        AppLanguage.kn: 'ಯಂತ್ರಾಂಶ ಅನುಮತಿಗಳು',
      },
      'subtitle': {
        AppLanguage.hinglish:
            'Krishi-Saarthi ke behtar experience ke liye permissions allow karein',
        AppLanguage.hi:
            'कृषि-सारथी के संपूर्ण अनुभव के लिए अनुमतियां सक्रिय करें',
        AppLanguage.en:
            'Enable permissions for the full Krishi-Saarthi OS experience',
        AppLanguage.bn: 'কৃষি-সারথির সম্পূর্ণ অভিজ্ঞতার জন্য অনুমতি দিন',
        AppLanguage.gu: 'કૃષિ-સારથીના સંપૂર્ણ અનુભવ માટે પરવાનગી આપો',
        AppLanguage.mr: 'कृषी-सारथीच्या संपूर्ण अनुभवासाठी परवानग्या द्या',
        AppLanguage.te: 'కృషి-సారథి పూర్తి అనుభవం కోసం అనుమతులను ప్రారంభించండి',
        AppLanguage.ta:
            'கிருஷி-சாரதியின் முழுமையான பயன்பாட்டிற்கு அனுமதி வழங்கவும்',
        AppLanguage.ur:
            'کرشی سارتھی کے مکمل تجربے کے لیے اجازتیں فعال کریں',
        AppLanguage.kn:
            'ಕೃಷಿ-ಸಾರಥಿಯ ಸಂಪೂರ್ಣ ಅನುಭವಕ್ಕಾಗಿ ಅನುಮತಿಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ',
      },
      'allActive': {
        AppLanguage.hinglish: 'Sabhi jaruri permissions active hain ✓',
        AppLanguage.hi: 'सभी आवश्यक अनुमतियां सक्रिय हैं ✓',
        AppLanguage.en: 'All required permissions are active ✓',
        AppLanguage.bn: 'সমস্ত প্রয়োজনীয় অনুমতি সক্রিয় আছে ✓',
        AppLanguage.gu: 'બધી જરૂરી પરવાનગીઓ સક્રિય છે ✓',
        AppLanguage.mr: 'सर्व आवश्यक परवानग्या सक्रिय आहेत ✓',
        AppLanguage.te: 'అన్ని అవసరమైన అనుమతులు సక్రియంగా ఉన్నాయి ✓',
        AppLanguage.ta: 'அனைத்து தேவையான அனுமதிகளும் செயலில் உள்ளன ✓',
        AppLanguage.ur: 'تمام ضروری اجازتیں فعال ہیں ✓',
        AppLanguage.kn: 'ಎಲ್ಲಾ ಅಗತ್ಯ ಅನುಮತಿಗಳು ಸಕ್ರಿಯವಾಗಿವೆ ✓',
      },
      'someMissing': {
        AppLanguage.hinglish:
            'Kripya niche di gayi permissions grant karein:',
        AppLanguage.hi: 'कृपया नीचे दी गई अनुमतियां प्रदान करें:',
        AppLanguage.en: 'Please grant the permissions below:',
        AppLanguage.bn: 'অনুগ্রহ করে নীচের অনুমতিগুলি প্রদান করুন:',
        AppLanguage.gu: 'કૃપા કરીને નીચે આપેલી પરવાનગીઓ આપો:',
        AppLanguage.mr: 'कृपया खालील परवानग्या द्या:',
        AppLanguage.te: 'దయచేసి క్రింది అనుమతులను మంజూరు చేయండి:',
        AppLanguage.ta: 'கீழே உள்ள அனுமதிகளை வழங்கவும்:',
        AppLanguage.ur: 'براہ کرم نیچے دی گئی اجازتیں دیں:',
        AppLanguage.kn: 'ದಯವಿಟ್ಟು ಕೆಳಗಿನ ಅನುಮತಿಗಳನ್ನು ನೀಡಿ:',
      },
      'cameraTitle': {
        AppLanguage.hinglish: 'Camera (कैमरा)',
        AppLanguage.hi: 'कैमरा (Camera)',
        AppLanguage.en: 'Camera',
        AppLanguage.bn: 'ক্যামেরা (Camera)',
        AppLanguage.gu: 'કેમેરા (Camera)',
        AppLanguage.mr: 'कॅमेरा (Camera)',
        AppLanguage.te: 'కెమెరా (Camera)',
        AppLanguage.ta: 'கேமரா (Camera)',
        AppLanguage.ur: 'کیمرہ (Camera)',
        AppLanguage.kn: 'ಕ್ಯಾಮೆರಾ (Camera)',
      },
      'cameraDesc': {
        AppLanguage.hinglish:
            'Fasal rog diagnosis aur bima video evidence ke liye',
        AppLanguage.hi:
            'फसल रोग निदान एवं फसल बीमा वीडियो साक्ष्य रिकॉर्डिंग हेतु',
        AppLanguage.en:
            'For AI leaf disease diagnosis and PMFBY insurance proof',
        AppLanguage.bn: 'ফসলের রোগ নির্ণয় ও বীমা ভিডিও প্রমাণের জন্য',
        AppLanguage.gu: 'પાક રોગ નિદાન અને પાક વીમા વિડિઓ પુરાવા માટે',
        AppLanguage.mr: 'पीक रोग निदान आणि पीक विमा व्हिडिओ पुराव्यासाठी',
        AppLanguage.te:
            'పంట వ్యాధి నిర్ధారణ మరియు పంట బీమా వీడియో సాక్ష్యం కోసం',
        AppLanguage.ta:
            'பயிர் நோய் கண்டறிதல் மற்றும் பயிர் காப்பீட்டு சான்றுகளுக்கு',
        AppLanguage.ur:
            'فصل کی بیماری کی تشخیص اور فصل بیمہ ثبوت کے لیے',
        AppLanguage.kn: 'ಬೆಳೆ ರೋಗ ಪತ್ತೆ ಮತ್ತು ಬೆಳೆ ವಿಮೆ ವೀಡಿಯೊ ಪುರಾವೆಗಾಗಿ',
      },
      'micTitle': {
        AppLanguage.hinglish: 'Microphone (माइक्रोफोन)',
        AppLanguage.hi: 'माइक्रोफोन (Microphone)',
        AppLanguage.en: 'Microphone',
        AppLanguage.bn: 'মাইক্রোফোন (Microphone)',
        AppLanguage.gu: 'માઇક્રોફોન (Microphone)',
        AppLanguage.mr: 'मायक्रोफोन (Microphone)',
        AppLanguage.te: 'మైక్రోఫోన్ (Microphone)',
        AppLanguage.ta: 'மைக்ரோஃபோன் (Microphone)',
        AppLanguage.ur: 'مائیکروفون (Microphone)',
        AppLanguage.kn: 'ಮೈಕ್ರೊಫೋನ್ (Microphone)',
      },
      'micDesc': {
        AppLanguage.hinglish:
            'Krishi Copilot se bolkar baat karne aur voice query ke liye',
        AppLanguage.hi:
            'कृषि कॉपायलट से बोलकर सवाल पूछने एवं वॉइस संवाद हेतु',
        AppLanguage.en:
            'For Krishi Copilot voice chat and Indian speech interaction',
        AppLanguage.bn: 'কৃষি কপালটের সাথে ভয়েস চ্যাট ও কথা বলার জন্য',
        AppLanguage.gu: 'કૃષિ કોપાયલોટ સાથે બોલીને સવાલ પૂછવા માટે',
        AppLanguage.mr: 'कृषी कॉपायलटशी बोलून संवाद साधण्यासाठी',
        AppLanguage.te: 'కృషి కోపైలట్‌తో వాయిస్ సంభాషణ కోసం',
        AppLanguage.ta: 'கிருஷி கோபைலட்டுடன் குரல் உரையாடலுக்கு',
        AppLanguage.ur: 'کرشی کو پائلٹ سے بول کر سوال پوچھنے کے لیے',
        AppLanguage.kn: 'ಕೃಷಿ ಕೋಪೈಲಟ್ ಜೊತೆ ಧ್ವನಿ ಸಂಭಾಷಣೆಗಾಗಿ',
      },
      'locTitle': {
        AppLanguage.hinglish: 'Location (स्थान GPS)',
        AppLanguage.hi: 'स्थान (GPS Location)',
        AppLanguage.en: 'GPS Location',
        AppLanguage.bn: 'অবস্থান (GPS Location)',
        AppLanguage.gu: 'સ્થાન (GPS Location)',
        AppLanguage.mr: 'स्थान (GPS Location)',
        AppLanguage.te: 'స్థానం (GPS Location)',
        AppLanguage.ta: 'இருப்பிடம் (GPS Location)',
        AppLanguage.ur: 'مقام (GPS Location)',
        AppLanguage.kn: 'ಸ್ಥಳ (GPS Location)',
      },
      'locDesc': {
        AppLanguage.hinglish:
            'Local weather, mandi prices aur geo-tagged claims ke liye',
        AppLanguage.hi:
            'सटीक मौसम पूर्वानुमान, नजदीकी मंडी भाव व जिओ-टैग्ड बीमा हेतु',
        AppLanguage.en:
            'For hyperlocal weather alerts, mandi prices & geo-tagged claims',
        AppLanguage.bn:
            'স্থানীয় আবহাওয়া, নিকটতম মান্ডি দর ও বীমা দাবির জন্য',
        AppLanguage.gu:
            'સ્થાનિક હવામાન, નજીકના માર્કેટ ભાવ અને વીમા દાવા માટે',
        AppLanguage.mr:
            'स्थानिक हवामान, जवळचे बाजार भाव आणि विमा दाव्यासाठी',
        AppLanguage.te:
            'స్థానిక వాతావరణం, సమీప మార్కెట్ ధరలు మరియు బీమా క్లెయిమ్‌ల కోసం',
        AppLanguage.ta:
            'உள்ளூர் வானிலை, அருகிலுள்ள மண்டி விலை மற்றும் காப்பீட்டுக்கு',
        AppLanguage.ur:
            'مقامی موسم، قریبی منڈی ریٹ اور بیمہ دعووں کے لیے',
        AppLanguage.kn:
            'ಸ್ಥಳೀಯ ಹವಾಮಾನ, ಸಮೀಪದ ಮಾರುಕಟ್ಟೆ ದರಗಳು ಮತ್ತು ವಿಮಾ ಕ್ಲೈಮ್‌ಗಳಿಗಾಗಿ',
      },
      'grant': {
        AppLanguage.hinglish: 'Allow',
        AppLanguage.hi: 'अनुमति दें',
        AppLanguage.en: 'Grant',
        AppLanguage.bn: 'অনুমতি দিন',
        AppLanguage.gu: 'પરવાનગી આપો',
        AppLanguage.mr: 'परवानगी द्या',
        AppLanguage.te: 'అనుమతించు',
        AppLanguage.ta: 'அனுமதிக்கவும்',
        AppLanguage.ur: 'اجازت دیں',
        AppLanguage.kn: 'ಅನುಮತಿಸಿ',
      },
      'granted': {
        AppLanguage.hinglish: 'Active ✓',
        AppLanguage.hi: 'सक्रिय ✓',
        AppLanguage.en: 'Active ✓',
        AppLanguage.bn: 'সক্রিয় ✓',
        AppLanguage.gu: 'સક્રિય ✓',
        AppLanguage.mr: 'सक्रिय ✓',
        AppLanguage.te: 'సక్రియం ✓',
        AppLanguage.ta: 'செயலில் ✓',
        AppLanguage.ur: 'فعال ✓',
        AppLanguage.kn: 'ಸಕ್ರಿಯ ✓',
      },
      'grantAll': {
        AppLanguage.hinglish: 'Sabhi Permissions Allow Karein',
        AppLanguage.hi: 'सभी अनुमतियां सक्रिय करें',
        AppLanguage.en: 'Grant All Permissions',
        AppLanguage.bn: 'সমস্ত অনুমতি দিন',
        AppLanguage.gu: 'બધી પરવાનગીઓ સક્રિય કરો',
        AppLanguage.mr: 'सर्व परवानग्या सक्रिय करा',
        AppLanguage.te: 'అన్ని అనుమతులను ప్రారంభించండి',
        AppLanguage.ta: 'அனைத்து அனுமதிகளையும் வழங்கவும்',
        AppLanguage.ur: 'تمام اجازتیں فعال کریں',
        AppLanguage.kn: 'ಎಲ್ಲಾ ಅನುಮತಿಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ',
      },
      'openSettings': {
        AppLanguage.hinglish: 'System Settings Kholein ⚙️',
        AppLanguage.hi: 'सिस्टम सेटिंग्स खोलें (System Settings) ⚙️',
        AppLanguage.en: 'Open System Settings ⚙️',
        AppLanguage.bn: 'সিস্টেম সেটিংস খুলুন ⚙️',
        AppLanguage.gu: 'સિસ્ટમ સેટિંગ્સ ખોલો ⚙️',
        AppLanguage.mr: 'सिस्टम सेटिंग्ज उघडा ⚙️',
        AppLanguage.te: 'సిస్టమ్ సెట్టింగ్‌లను తెరవండి ⚙️',
        AppLanguage.ta: 'கணினி அமைப்புகளைத் திறக்கவும் ⚙️',
        AppLanguage.ur: 'سسٹم سیٹنگز کھولیں ⚙️',
        AppLanguage.kn: 'ಸಿಸ್ಟಮ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ ⚙️',
      },
      'done': {
        AppLanguage.hinglish: 'Done (पूर्ण)',
        AppLanguage.hi: 'पूर्ण (Done)',
        AppLanguage.en: 'Done',
        AppLanguage.bn: 'সম্পন্ন (Done)',
        AppLanguage.gu: 'સંપૂર્ણ (Done)',
        AppLanguage.mr: 'पूर्ण (Done)',
        AppLanguage.te: 'పూర్తయింది (Done)',
        AppLanguage.ta: 'முடிந்தது (Done)',
        AppLanguage.ur: 'مکمل (Done)',
        AppLanguage.kn: 'ಪೂರ್ಣಗೊಂಡಿದೆ (Done)',
      },
      'macNotice': {
        AppLanguage.hinglish:
            'macOS par permissions band hone par System Settings > Privacy & Security me chalu karein.',
        AppLanguage.hi:
            'यदि macOS ने अनुमति रोक दी है, तो "सिस्टम सेटिंग्स खोलें" बटन दबाकर Privacy & Security में अनुमति चालू करें।',
        AppLanguage.en:
            'If macOS blocked access, click "Open System Settings" to enable in Privacy & Security.',
        AppLanguage.bn:
            'macOS এ অনুমতি ব্লক থাকলে, Privacy & Security থেকে চালু করতে "সিস্টেম সেটিংস খুলুন" এ ক্লিক করুন।',
        AppLanguage.gu:
            'જો macOS એ પરવાનગી રોકી હોય, તો Privacy & Security માં સક્ષમ કરવા "સિસ્ટમ સેટિંગ્સ ખોલો" પર ક્લિક કરો.',
        AppLanguage.mr:
            'macOS वर परवानगी अडकल्यास, Privacy & Security मध्ये सक्षम करण्यासाठी "सिस्टम सेटिंग्ज उघडा" वर क्लिक करा.',
        AppLanguage.te:
            'macOS లో అనుమతి నిరోధించబడితే, Privacy & Security లో ప్రారంభించడానికి "సిస్టమ్ సెట్టింగ్‌లను తెరవండి" క్లిక్ చేయండి.',
        AppLanguage.ta:
            'macOS இல் அனுமதி தடுக்கப்பட்டால், Privacy & Security இல் இயக்க "கணினி அமைப்புகளைத் திறக்கவும்" என்பதைக் கிளிக் செய்யவும்.',
        AppLanguage.ur:
            'اگر macOS نے اجازت روک دی ہے تو Privacy & Security میں فعال کرنے کے لیے "سسٹم سیٹنگز کھولیں" پر کلک کریں۔',
        AppLanguage.kn:
            'macOS ನಲ್ಲಿ ಅನುಮತಿಯನ್ನು ನಿರ್ಬಂಧಿಸಿದ್ದರೆ, Privacy & Security ನಲ್ಲಿ ಸಕ್ರಿಯಗೊಳಿಸಲು "ಸಿಸ್ಟಮ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ" ಕ್ಲಿಕ್ ಮಾಡಿ.',
      },
    };

    final entry = strings[key];
    if (entry == null) return key;
    return entry[lang] ?? entry[AppLanguage.hinglish] ?? entry[AppLanguage.en] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.currentLanguage;

    final bool allGranted = _hasCamera && _hasMicrophone && _hasLocation;
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header: Shield Icon + Title + Close ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: allGranted
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: allGranted
                              ? colorPrimary.withValues(alpha: 0.3)
                              : colorAmber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        allGranted
                            ? Icons.verified_user_rounded
                            : Icons.security_rounded,
                        color: allGranted ? colorPrimary : colorAmber,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('title', lang),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _t('subtitle', lang),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 22, color: Colors.black54),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Overall Status Banner ───
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: allGranted
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: allGranted
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFFFFCC80),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        allGranted
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        size: 18,
                        color: allGranted ? colorPrimary : colorAmber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          allGranted
                              ? _t('allActive', lang)
                              : _t('someMissing', lang),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: allGranted ? colorForest : colorAmber,
                          ),
                        ),
                      ),
                      if (_isChecking)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 1. Camera Item ───
                _buildPermissionRow(
                  icon: Icons.camera_alt_rounded,
                  title: _t('cameraTitle', lang),
                  description: _t('cameraDesc', lang),
                  isGranted: _hasCamera,
                  onGrantPressed: _requestCamera,
                  lang: lang,
                ),
                const SizedBox(height: 10),

                // ─── 2. Microphone Item ───
                _buildPermissionRow(
                  icon: Icons.mic_rounded,
                  title: _t('micTitle', lang),
                  description: _t('micDesc', lang),
                  isGranted: _hasMicrophone,
                  onGrantPressed: _requestMicrophone,
                  lang: lang,
                ),
                const SizedBox(height: 10),

                // ─── 3. Location Item ───
                _buildPermissionRow(
                  icon: Icons.location_on_rounded,
                  title: _t('locTitle', lang),
                  description: _t('locDesc', lang),
                  isGranted: _hasLocation,
                  onGrantPressed: _requestLocation,
                  lang: lang,
                ),
                const SizedBox(height: 16),

                // ─── Platform Help Tip ───
                if (isDesktop) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.laptop_mac_rounded,
                            size: 16, color: Color(0xFF475569)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _t('macNotice', lang),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF334155),
                                height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Bottom Actions: Grant All & Open System Settings ───
                if (!allGranted) ...[
                  ElevatedButton.icon(
                    onPressed: _isRequestingAll ? null : _requestAll,
                    icon: _isRequestingAll
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.done_all_rounded,
                            color: Colors.white, size: 20),
                    label: Text(
                      _isRequestingAll
                          ? 'सक्रिय किया जा रहा है...'
                          : _t('grantAll', lang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded,
                        size: 18, color: Color(0xFF2E7D32)),
                    label: Text(
                      _t('openSettings', lang),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                          color: Color(0xFF81C784), width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    label: Text(
                      _t('done', lang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onGrantPressed,
    required AppLanguage lang,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isGranted ? const Color(0xFFF1F8E9) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? const Color(0xFFA5D6A7) : colorBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? colorPrimary.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isGranted ? colorPrimary : Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (isGranted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _t('granted', lang),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onGrantPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(60, 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                _t('grant', lang),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
