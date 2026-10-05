import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/design_tokens.dart';
import 'community_members_screen.dart';
import 'community_models.dart';
import 'community_service.dart';
import 'poll_widgets.dart';

class CommunityChatScreen extends StatefulWidget {
  final String communityId;

  const CommunityChatScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> with SingleTickerProviderStateMixin {
  final CommunityService _service = CommunityService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _postController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  // Voice recording state
  bool _isRecordingAudio = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Audio playback state
  String? _playingAudioMsgId;
  double _audioPlayProgress = 0.0;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _textController.dispose();
    _postController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? colorTerracotta : colorPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================
  // AUDIO RECORDING & PLAYBACK
  // ==========================================
  void _startAudioRecording() {
    setState(() {
      _isRecordingAudio = true;
      _recordingSeconds = 0;
    });
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  void _stopAndSendAudio() {
    _recordingTimer?.cancel();
    final sec = _recordingSeconds > 0 ? _recordingSeconds : 4;
    setState(() {
      _isRecordingAudio = false;
      _recordingSeconds = 0;
    });
    _service.sendAudioMessage(widget.communityId, sec);
    _scrollToBottom();
    _showCustomSnackBar('Voice message sent');
  }

  void _cancelAudioRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecordingAudio = false;
      _recordingSeconds = 0;
    });
    _showCustomSnackBar('Recording cancelled');
  }

  void _toggleAudioPlayback(CommunityMessage msg) {
    if (_playingAudioMsgId == msg.id) {
      // Pause
      _playbackTimer?.cancel();
      setState(() {
        _playingAudioMsgId = null;
      });
    } else {
      // Play
      _playbackTimer?.cancel();
      final totalSec = msg.audioDurationSeconds ?? 15;
      setState(() {
        _playingAudioMsgId = msg.id;
        _audioPlayProgress = 0.0;
      });

      const int tickMs = 100;
      final totalTicks = (totalSec * 1000) / tickMs;
      int currentTick = 0;

      _playbackTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        currentTick++;
        if (currentTick >= totalTicks) {
          timer.cancel();
          setState(() {
            _playingAudioMsgId = null;
            _audioPlayProgress = 0.0;
          });
        } else {
          setState(() {
            _audioPlayProgress = currentTick / totalTicks;
          });
        }
      });
    }
  }

  // ==========================================
  // IMAGE SHARING
  // ==========================================
  Future<void> _pickAndSendImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file != null) {
        _showImageCaptionDialog(file.path, isLocalFile: true);
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      _showPresetFarmPhotosPicker();
    }
  }

  void _showPresetFarmPhotosPicker() {
    final List<Map<String, String>> presets = [
      {
        'title': 'Apple Scab & Foliar Blight Leaf',
        'desc': 'Brown spots on upper foliage. Spray Mancozeb 75% WP?',
        'tag': 'Crop Health',
        'image': 'assets/images/placeholder_leaf.png',
      },
      {
        'title': 'Wheat Golden Grain Harvest',
        'desc': 'Moisture test at 12.4%. Ready for Mandi auction!',
        'tag': 'Harvest',
        'image': 'assets/images/placeholder_field.png',
      },
      {
        'title': 'Tractor Hydraulic Disc Plough',
        'desc': 'Available for farm rental in Solan/Shimla block @ ₹800/hr',
        'tag': 'Machinery',
        'image': 'assets/images/placeholder_tractor.png',
      },
      {
        'title': 'APMC Mandi Auction Slip #4812',
        'desc': 'Grade A Royal Delicious traded at ₹2,800 / box today',
        'tag': 'Mandi Price',
        'image': 'assets/images/placeholder_receipt.png',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Farm Photo',
                  style: TextStyle(color: Color(0xFF1B381E), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select from recent crop observations or pick from storage:',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Pick from Gallery / Camera buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 20),
                    label: const Text('Device Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(source: ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(source: ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Preset Farm Observations:', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),

            ...presets.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1E7D5)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.yard_rounded, color: Color(0xFF15803D), size: 22),
                    ),
                    title: Text(p['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1F2937))),
                    subtitle: Text(p['desc']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11.5)),
                    trailing: const Icon(Icons.send_rounded, color: Color(0xFF15803D), size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      _service.sendPhotoMessage(widget.communityId, p['image']!, p['desc']!);
                      _scrollToBottom();
                      _showCustomSnackBar('Farm photo shared');
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showImageCaptionDialog(String imagePath, {bool isLocalFile = false}) {
    final captionCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Send Photo with Caption', style: TextStyle(color: Color(0xFF1B381E), fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1E7D5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isLocalFile
                    ? Image.file(File(imagePath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 40, color: Color(0xFF2E7D32))))
                    : const Center(child: Icon(Icons.image, size: 40, color: Color(0xFF2E7D32))),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: captionCtrl,
              autofocus: true,
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a message or description...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAF9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            label: const Text('Send Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              _service.sendPhotoMessage(widget.communityId, imagePath, captionCtrl.text);
              _scrollToBottom();
              _showCustomSnackBar('Photo sent');
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DOCUMENT / FILE SHARING
  // ==========================================
  void _showDocumentPicker() {
    final List<Map<String, String>> docs = [
      {
        'name': 'Kharif_Soil_Health_Card_2026.pdf',
        'size': '2.4 MB',
        'type': 'PDF',
      },
      {
        'name': 'ICAR_Apple_Scab_Fungicide_Advisory.pdf',
        'size': '1.1 MB',
        'type': 'PDF',
      },
      {
        'name': 'PM_Kisan_DBT_Subsidy_Rules.pdf',
        'size': '890 KB',
        'type': 'PDF',
      },
      {
        'name': 'Shimla_Solan_Mandi_Rate_Index.xlsx',
        'size': '640 KB',
        'type': 'EXCEL',
      },
      {
        'name': 'Drip_Irrigation_Subsidy_Invoice.pdf',
        'size': '450 KB',
        'type': 'PDF',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Document / File',
                  style: TextStyle(color: Color(0xFF1B381E), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select an agricultural advisory, report, or test card to share with the group:',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 14),

            ...docs.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1E7D5)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: d['type'] == 'PDF' ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        d['type'] == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded,
                        color: d['type'] == 'PDF' ? colorTerracotta : const Color(0xFF15803D),
                        size: 22,
                      ),
                    ),
                    title: Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
                    subtitle: Text('${d['size']} • ${d['type']}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11.5)),
                    trailing: const Icon(Icons.send_rounded, color: Color(0xFF15803D), size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      _service.sendFileMessage(widget.communityId, d['name']!, d['size']!);
                      _scrollToBottom();
                      _showCustomSnackBar('Document shared with community');
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ATTACHMENT MENU (+ BUTTON)
  // ==========================================
  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Content',
              style: TextStyle(color: Color(0xFF1B381E), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  bg: const Color(0xFFDCFCE7),
                  fg: const Color(0xFF15803D),
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSendImage(source: ImageSource.camera);
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library_rounded,
                  bg: const Color(0xFFE0F2FE),
                  fg: const Color(0xFF0284C7),
                  label: 'Photos',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetFarmPhotosPicker();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.description_rounded,
                  bg: const Color(0xFFFEF3C7),
                  fg: const Color(0xFFD97706),
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDocumentPicker();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.poll_rounded,
                  bg: const Color(0xFFF3E8FF),
                  fg: const Color(0xFF7C3AED),
                  label: 'Poll',
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => CreatePollDialog(
                        onCreated: (q, opts, multi) {
                          _service.sendPoll(widget.communityId, q, opts, multi);
                          _scrollToBottom();
                          _showCustomSnackBar('Poll created');
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color bg,
    required Color fg,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  // ==========================================
  // MESSAGE BALLOON ACTION SHEET (Copy, Delete, Pin, Reactions)
  // ==========================================
  void _showMessageActionBalloon(CommunityMessage msg, Community community) {
    final bool isAdmin = _service.isCurrentUserAdmin(community.id);
    final bool isMyMessage = msg.senderId == _service.currentUserId;
    final bool canDelete = isMyMessage || isAdmin;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EMOJI REACTION ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '❤️', '🌾', '🙏', '👏', '😂'].map((emoji) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _service.addReaction(widget.communityId, msg.id, emoji);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 20),

            // Actions list
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Color(0xFF15803D)),
              title: const Text('Copy Message Text', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg.content));
                _showCustomSnackBar('Message copied');
              },
            ),

            if (isAdmin)
              ListTile(
                leading: Icon(msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: const Color(0xFF0284C7)),
                title: Text(msg.isPinned ? 'Unpin Message' : 'Pin to Top Banner', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _service.togglePinMessage(widget.communityId, msg.id);
                  _showCustomSnackBar(msg.isPinned ? 'Message unpinned' : 'Message pinned to group banner');
                },
              ),

            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: colorTerracotta),
                title: const Text('Delete Message', style: TextStyle(fontWeight: FontWeight.bold, color: colorTerracotta)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _service.deleteMessage(widget.communityId, msg.id);
                  if (ok) {
                    _showCustomSnackBar('Message deleted');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONFIRM DELETE COMMUNITY (ADMIN ONLY)
  // ==========================================
  void _confirmDeleteCommunity(Community community) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
            SizedBox(width: 10),
            Text('Delete Community?', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${community.name}"? All chat messages, media, polls, and posts will be removed for everyone.',
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTerracotta,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _service.deleteCommunity(community.id);
              if (ok && mounted) {
                _showCustomSnackBar('Community "${community.name}" deleted');
                Navigator.pop(context); // Return to community list
              }
            },
            child: const Text('Delete Community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final community = _service.getCommunity(widget.communityId);
    if (community == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 1),
        body: const Center(child: Text('Community not found', style: TextStyle(color: Color(0xFF6B7280)))),
      );
    }

    final messages = _service.getMessages(widget.communityId);
    final posts = _service.getPosts(widget.communityId);
    final bool isAdmin = _service.isCurrentUserAdmin(widget.communityId);

    // Format members preview string for header
    final membersPreview = community.members.map((m) => m.displayName).join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF6), // Fresh WhatsApp-style light green mist
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B381E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommunityMembersScreen(communityId: widget.communityId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(community.iconColorValue),
                child: Icon(community.iconData, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        color: Color(0xFF1B381E),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      membersPreview,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Color(0xFF15803D)),
            tooltip: 'View Members',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityMembersScreen(communityId: widget.communityId),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1B381E)),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'members') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CommunityMembersScreen(communityId: widget.communityId)),
                );
              } else if (val == 'share') {
                final link = 'https://krishisaarthi.org/join/${community.inviteCode}';
                Share.share('Join our agricultural community "${community.name}": $link');
              } else if (val == 'delete') {
                _confirmDeleteCommunity(community);
              } else if (val == 'leave') {
                _service.leaveCommunity(community.id);
                _showCustomSnackBar('Left "${community.name}"');
                Navigator.pop(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.group_rounded, color: Color(0xFF15803D), size: 18),
                    SizedBox(width: 8),
                    Text('Group Info & Members', style: TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: Color(0xFF0284C7), size: 18),
                    SizedBox(width: 8),
                    Text('Invite via Link / QR', style: TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
                  ],
                ),
              ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: colorTerracotta, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Community', style: TextStyle(fontSize: 13, color: colorTerracotta, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app_rounded, color: Color(0xFF6B7280), size: 18),
                      SizedBox(width: 8),
                      Text('Leave Community', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2E7D32),
              indicatorWeight: 3,
              labelColor: const Color(0xFF1B381E),
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Chat & Polls'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dynamic_feed_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Community Posts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: WHATSAPP-STYLE LIVE GROUP CHAT
          _buildChatTab(community, messages),

          // TAB 2: TWITTER-STYLE COMMUNITY POST FEED
          _buildFeedTab(community, posts),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: CHAT & POLLS (WHATSAPP STYLE)
  // ==========================================
  Widget _buildChatTab(Community community, List<CommunityMessage> messages) {
    return Column(
      children: [
        // Top Pinned Message Banner
        if (community.pinnedMessageSnippet != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              border: Border(bottom: BorderSide(color: Color(0xFF86EFAC))),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin_rounded, color: Color(0xFF15803D), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    community.pinnedMessageSnippet!,
                    style: const TextStyle(color: Color(0xFF166534), fontSize: 12.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_service.isCurrentUserLeaderOrAdmin(community.id))
                  GestureDetector(
                    onTap: () => _service.togglePinMessage(community.id, community.pinnedMessageId ?? ''),
                    child: const Icon(Icons.close, color: Color(0xFF166534), size: 16),
                  ),
              ],
            ),
          ),

        // Message List
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF15803D), size: 36),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Start the conversation!',
                        style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Share a photo, voice message, or create a poll.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final msg = messages[index];
                    return _buildMessageItem(community, msg);
                  },
                ),
        ),

        // Bottom Input Bar
        _buildBottomBar(community),
      ],
    );
  }

  Widget _buildMessageItem(Community community, CommunityMessage msg) {
    if (msg.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.content,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final bool isMe = msg.senderId == _service.currentUserId;

    return GestureDetector(
      onLongPress: () => _showMessageActionBalloon(msg, community),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: Color(msg.senderColorValue),
                child: Text(
                  msg.senderName.replaceAll('~', '').trim()[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
            ],

            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  // WhatsApp Sent: Soft mint green; Received: Crisp white with subtle border
                  color: isMe ? const Color(0xFFD9FDD3) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 14),
                  ),
                  border: Border.all(
                    color: isMe ? const Color(0xFFB7E4B2) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender Header
                    if (!isMe) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.senderName,
                            style: const TextStyle(
                              color: Color(0xFF15803D), // WhatsApp sender green
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          if (msg.senderRole == CommunityRole.admin) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text('Admin', style: TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          if (msg.senderRole == CommunityRole.leader) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text('Leader', style: TextStyle(color: Color(0xFF0284C7), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          if (msg.senderPhone != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              msg.senderPhone!,
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],

                    // Message Content by Type
                    if (msg.type == MessageType.poll && msg.poll != null)
                      _buildPollCard(community, msg)
                    else if (msg.type == MessageType.image)
                      _buildImageBubble(msg)
                    else if (msg.type == MessageType.file)
                      _buildFileBubble(msg)
                    else if (msg.type == MessageType.audio)
                      _buildAudioBubble(msg)
                    else
                      Text(
                        msg.content,
                        style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                      ),

                    const SizedBox(height: 4),

                    // Timestamp & Status Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (msg.isPinned) ...[
                          const Icon(Icons.push_pin_rounded, color: Color(0xFF15803D), size: 12),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatMessageTime(msg.timestamp),
                          style: TextStyle(
                            color: isMe ? const Color(0xFF166534).withValues(alpha: 0.7) : const Color(0xFF9CA3AF),
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.done_all, color: Color(0xFF16A34A), size: 14),
                        ],
                      ],
                    ),

                    // Emoji Reactions display
                    if (msg.reactions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: msg.reactions.map((r) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD1E7D5)),
                            ),
                            child: Text(
                              '${r.emoji} ${r.userIds.length > 1 ? r.userIds.length : ''}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // POLL CARD (Interactive matching Image 1)
  // ==========================================
  Widget _buildPollCard(Community community, CommunityMessage msg) {
    final poll = msg.poll!;
    final totalVotes = poll.totalVotes;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1E7D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.poll_rounded, color: Color(0xFF15803D), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            poll.allowMultipleAnswers ? 'Select one or more' : 'Select one',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          ),
          const SizedBox(height: 10),

          ...poll.options.map((opt) {
            final hasVoted = opt.voterUserIds.contains(_service.currentUserId);
            final double pct = totalVotes > 0 ? (opt.voteCount / totalVotes) : 0.0;

            return InkWell(
              onTap: () => _service.votePoll(community.id, msg.id, opt.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasVoted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: hasVoted ? const Color(0xFF15803D) : const Color(0xFF9CA3AF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt.text,
                            style: TextStyle(
                              color: const Color(0xFF1F2937),
                              fontSize: 13,
                              fontWeight: hasVoted ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (opt.voteCount > 0) ...[
                          Text(
                            '${opt.voteCount}',
                            style: const TextStyle(color: Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.person, color: Color(0xFF15803D), size: 12),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hasVoted ? const Color(0xFF15803D) : const Color(0xFF86EFAC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => PollVotesSheet(poll: poll),
                );
              },
              child: const Text(
                'View votes',
                style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // IMAGE BUBBLE
  // ==========================================
  Widget _buildImageBubble(CommunityMessage msg) {
    final bool isFile = msg.mediaUrl != null && File(msg.mediaUrl!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 170,
            width: double.infinity,
            color: const Color(0xFFF3F7F4),
            child: isFile
                ? Image.file(File(msg.mediaUrl!), fit: BoxFit.cover)
                : Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFDCFCE7),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.yard_rounded, size: 48, color: Color(0xFF15803D)),
                        SizedBox(height: 6),
                        Text(
                          'Farm Crop Observation',
                          style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (msg.content.isNotEmpty && msg.content != '📷 Photo') ...[
          const SizedBox(height: 6),
          Text(msg.content, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13.5)),
        ],
      ],
    );
  }

  // ==========================================
  // FILE BUBBLE
  // ==========================================
  Widget _buildFileBubble(CommunityMessage msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1E7D5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: colorTerracotta, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.fileName ?? msg.content,
                  style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  msg.fileSize ?? 'Agricultural PDF Report',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF15803D), size: 20),
            tooltip: 'Share File',
            onPressed: () {
              Share.share('Agricultural Document: ${msg.fileName ?? msg.content}');
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // AUDIO BUBBLE (Interactive Play/Pause Scrubber)
  // ==========================================
  Widget _buildAudioBubble(CommunityMessage msg) {
    final bool isPlaying = _playingAudioMsgId == msg.id;
    final int totalSec = msg.audioDurationSeconds ?? 15;
    final int currentSec = (totalSec * _audioPlayProgress).round();
    final String timeStr = isPlaying
        ? '00:${(totalSec - currentSec).toString().padLeft(2, '0')}'
        : '00:${totalSec.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1E7D5)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _toggleAudioPlayback(msg),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isPlaying ? _audioPlayProgress : 0.0,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Voice message', style: TextStyle(color: Color(0xFF4B5563), fontSize: 11)),
                    Text(timeStr, style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM BAR (Input, Attachments, Recording)
  // ==========================================
  Widget _buildBottomBar(Community community) {
    if (_isRecordingAudio) {
      // Audio recording live interface
      final minutes = _recordingSeconds ~/ 60;
      final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5EBE6))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: colorTerracotta, size: 24),
              onPressed: _cancelAudioRecording,
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recording $minutes:$seconds',
              style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            InkWell(
              onTap: _stopAndSendAudio,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5EBE6))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // + Attachment Button
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF15803D), size: 26),
              tooltip: 'Share Media, File, Poll',
              onPressed: _showAttachmentSheet,
            ),

            // Text Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD1E7D5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Message community...',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _service.sendTextMessage(widget.communityId, text);
                      _textController.clear();
                      _scrollToBottom();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Camera Button
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF15803D), size: 22),
              tooltip: 'Camera / Farm Photo',
              onPressed: _showPresetFarmPhotosPicker,
            ),

            // Mic Button or Send Button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (ctx, val, _) {
                final bool hasText = val.text.trim().isNotEmpty;
                return InkWell(
                  onTap: () {
                    if (hasText) {
                      _service.sendTextMessage(widget.communityId, val.text);
                      _textController.clear();
                      _scrollToBottom();
                    } else {
                      _startAudioRecording();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasText ? Icons.send_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: TWITTER-STYLE COMMUNITY POST FEED
  // ==========================================
  Widget _buildFeedTab(Community community, List<CommunityPost> posts) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Create Post Card at the top
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5EBE6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Text('Y', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "What's happening on your farm? #CropUpdate",
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEDF2EE), height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        backgroundColor: const Color(0xFFF3F7F4),
                        label: const Text('#WheatYield', style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold)),
                        side: const BorderSide(color: Color(0xFFD1E7D5)),
                        onPressed: () {
                          _postController.text = '${_postController.text} #WheatYield '.trimLeft();
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFFF3F7F4),
                        label: const Text('#PestAlert', style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold)),
                        side: const BorderSide(color: Color(0xFFD1E7D5)),
                        onPressed: () {
                          _postController.text = '${_postController.text} #PestAlert '.trimLeft();
                        },
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      final text = _postController.text.trim();
                      if (text.isEmpty) return;
                      _service.createPost(community.id, text);
                      _postController.clear();
                      _showCustomSnackBar('Post published to community');
                    },
                    child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Posts List
        if (posts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.dynamic_feed_rounded, color: Color(0xFF9CA3AF), size: 40),
                  SizedBox(height: 10),
                  Text('No posts in this community yet', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                  SizedBox(height: 4),
                  Text('Be the first to share an agricultural update!', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...posts.map((post) => _buildPostCard(community, post)),
      ],
    );
  }

  Widget _buildPostCard(Community community, CommunityPost post) {
    final bool canDelete = post.authorId == _service.currentUserId || _service.isCurrentUserAdmin(community.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header & 3-dots action popup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: post.authorRole == CommunityRole.admin
                        ? const Color(0xFF15803D)
                        : (post.authorRole == CommunityRole.leader ? const Color(0xFF0284C7) : const Color(0xFF6B7280)),
                    child: Text(
                      post.authorName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: post.authorRole == CommunityRole.admin
                                  ? const Color(0xFFDCFCE7)
                                  : (post.authorRole == CommunityRole.leader ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              post.authorRole.label,
                              style: TextStyle(
                                color: post.authorRole == CommunityRole.admin
                                    ? const Color(0xFF15803D)
                                    : (post.authorRole == CommunityRole.leader ? const Color(0xFF0284C7) : const Color(0xFF4B5563)),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatMessageTime(post.timestamp),
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              // 3-dots action menu on post
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) async {
                  if (val == 'delete') {
                    final ok = await _service.deletePost(community.id, post.id);
                    if (ok) {
                      _showCustomSnackBar('Post deleted');
                    }
                  } else if (val == 'share') {
                    Share.share('Agricultural Community Post: ${post.content}');
                  }
                },
                itemBuilder: (ctx) => [
                  if (canDelete)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: colorTerracotta, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Post', style: TextStyle(color: colorTerracotta, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, color: Color(0xFF6B7280), size: 18),
                        SizedBox(width: 8),
                        Text('Share Post', style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Content
          Text(
            post.content,
            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, height: 1.35),
          ),

          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: post.tags.map((tag) {
                return Text(
                  tag.startsWith('#') ? tag : '#$tag',
                  style: const TextStyle(color: Color(0xFF15803D), fontSize: 12.5, fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEDF2EE), height: 1),
          const SizedBox(height: 8),

          // Likes, Comments, Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () => _service.likePost(community.id, post.id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: post.isLikedByMe ? Colors.redAccent : const Color(0xFF6B7280),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likes}',
                        style: TextStyle(
                          color: post.isLikedByMe ? Colors.redAccent : const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showAddCommentDialog(community, post),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined, color: Color(0xFF6B7280), size: 18),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Share.share('Agricultural Community Post: ${post.content}');
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, color: Color(0xFF6B7280), size: 18),
                      SizedBox(width: 4),
                      Text('Share', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Comments Thread
          if (post.comments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: post.comments.map((cmt) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${cmt.authorName}: ',
                            style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          TextSpan(
                            text: cmt.content,
                            style: const TextStyle(color: Color(0xFF374151), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddCommentDialog(Community community, CommunityPost post) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Comment', style: TextStyle(color: Color(0xFF1B381E), fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: commentCtrl,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Write a comment or advice...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF9FAF9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final text = commentCtrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                _service.addCommentToPost(community.id, post.id, text);
                _showCustomSnackBar('Comment added');
              }
            },
            child: const Text('Reply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
