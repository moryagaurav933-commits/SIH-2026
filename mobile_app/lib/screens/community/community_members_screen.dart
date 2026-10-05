import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../localization/app_language.dart';
import '../../localization/app_translations.dart';
import '../../utils/design_tokens.dart';
import 'community_models.dart';
import 'community_service.dart';

class CommunityMembersScreen extends StatefulWidget {
  final String communityId;

  const CommunityMembersScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
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
                // Pop back to CommunityPaletteScreen
                Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/community');
              }
            },
            child: const Text('Delete Community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveCommunity(Community community) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Leave Community?', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          'Do you want to exit "${community.name}"? You can re-join anytime from Explore.',
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTerracotta,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.leaveCommunity(community.id);
              if (mounted) {
                _showCustomSnackBar('Left "${community.name}"');
                Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/community');
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Color(0xFF1B381E)),
        ),
        body: const Center(
          child: Text('Community not found', style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }

    final bool isAdmin = _service.isCurrentUserAdmin(widget.communityId);
    final members = community.members.where((m) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = m.displayName.toLowerCase();
      final bio = (m.bio ?? '').toLowerCase();
      final phone = (m.phone ?? '').toLowerCase();
      return name.contains(q) || bio.contains(q) || phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7), // Clean light green-white shade
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B381E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                decoration: InputDecoration(
                  hintText: context.currentLanguage == AppLanguage.hi ? 'सदस्य खोजें...' : 'Search members...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(
                '${community.memberCount} ${context.currentLanguage == AppLanguage.hi ? 'सदस्य' : 'members'}',
                style: const TextStyle(
                  color: Color(0xFF1B381E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: const Color(0xFF1B381E)),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 1. Add members action (Admin only or disabled)
          _buildActionTile(
            icon: Icons.person_add_alt_1_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF15803D),
            title: context.currentLanguage == AppLanguage.hi ? 'सदस्य जोड़ें' : 'Add members',
            subtitle: isAdmin ? null : (context.currentLanguage == AppLanguage.hi ? 'केवल व्यवस्थापक' : 'Admin only'),
            onTap: () {
              if (isAdmin) {
                _showAddMemberModal(community);
              } else {
                _showCustomSnackBar(
                  context.currentLanguage == AppLanguage.hi
                      ? 'केवल समूह व्यवस्थापक सदस्य जोड़ सकते हैं'
                      : 'Only community admins can add members',
                  isError: true,
                );
              }
            },
          ),

          // 2. Invite via link or QR code
          _buildActionTile(
            icon: Icons.link_rounded,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            title: context.currentLanguage == AppLanguage.hi
                ? 'लिंक या QR कोड से आमंत्रित करें'
                : 'Invite via link or QR code',
            onTap: () => _showInviteDialog(community),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: Color(0xFFE5EBE6), height: 1),
          ),

          // 3. Member List items
          ...members.map((member) => _buildMemberTile(community, member, isAdmin)),

          const SizedBox(height: 24),

          // 4. Admin Community Delete Button OR Leave Community Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isAdmin
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFEE2E2),
                        child: Icon(Icons.delete_forever_rounded, color: colorTerracotta),
                      ),
                      title: const Text(
                        'Delete Community',
                        style: TextStyle(
                          color: colorTerracotta,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Admin Only • Permanently delete group, chat & posts',
                        style: TextStyle(color: Color(0xFF991B1B), fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: colorTerracotta),
                      onTap: () => _confirmDeleteCommunity(community),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF3F4F6),
                        child: Icon(Icons.exit_to_app_rounded, color: Color(0xFF6B7280)),
                      ),
                      title: const Text(
                        'Leave Community',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        'Exit group and mute future updates',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5),
                      ),
                      onTap: () => _confirmLeaveCommunity(community),
                    ),
                  ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(Community community, CommunityMember member, bool isViewerAdmin) {
    final bool isYou = member.isCurrentUser;

    return InkWell(
      onTap: () => _handleMemberTap(community, member, isViewerAdmin),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDF2EE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(member.avatarColorValue),
              child: Text(
                member.displayName.isNotEmpty
                    ? member.displayName.replaceAll('~', '').trim()[0].toUpperCase()
                    : 'K',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & Subtitle / Tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYou ? 'You' : member.displayName,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (isYou)
                    GestureDetector(
                      onTap: () => _showEditTagDialog(member),
                      child: Text(
                        member.customTag != null && member.customTag!.isNotEmpty
                            ? member.customTag!
                            : 'Add member tag',
                        style: const TextStyle(
                          color: Color(0xFF15803D), // WhatsApp green
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (member.phone != null && member.phone!.isNotEmpty)
                    Text(
                      member.phone!,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    )
                  else if (member.bio != null && member.bio!.isNotEmpty)
                    Text(
                      member.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                ],
              ),
            ),

            // Trailing Bio or Role Badge + Arrow
            if (isYou && member.bio != null && member.bio!.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  child: Text(
                    member.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ),
              ),

            // Role Badge (Admin / Leader)
            if (member.role == CommunityRole.admin)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (member.role == CommunityRole.leader)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF7DD3FC)),
                ),
                child: const Text(
                  'Leader',
                  style: TextStyle(
                    color: Color(0xFF0369A1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            if (!isYou) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMemberTap(Community community, CommunityMember member, bool isViewerAdmin) {
    if (member.isCurrentUser) {
      _showEditTagDialog(member);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Member summary
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(member.avatarColorValue),
                    child: Text(
                      member.displayName.replaceAll('~', '').trim()[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        if (member.bio != null) ...[
                          const SizedBox(height: 2),
                          Text(member.bio!, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: member.role == CommunityRole.admin
                                    ? const Color(0xFFDCFCE7)
                                    : (member.role == CommunityRole.leader ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                member.role.label,
                                style: TextStyle(
                                  color: member.role == CommunityRole.admin
                                      ? const Color(0xFF15803D)
                                      : (member.role == CommunityRole.leader ? const Color(0xFF0369A1) : const Color(0xFF4B5563)),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (member.customTag != null && member.customTag!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  member.customTag!,
                                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFE5E7EB)),

              // Admin controls (Enforced: only admin can modify roles)
              if (isViewerAdmin) ...[
                if (member.role != CommunityRole.admin)
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: Color(0xFF15803D)),
                    title: const Text('Make Community Admin', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                    subtitle: const Text('Can edit settings and manage all members', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await _service.updateMemberRole(community.id, member.id, CommunityRole.admin);
                      if (success) {
                        _showCustomSnackBar('${member.displayName} is now an Admin');
                      }
                    },
                  ),
                if (member.role != CommunityRole.leader)
                  ListTile(
                    leading: const Icon(Icons.star_rounded, color: Color(0xFF0284C7)),
                    title: const Text('Assign Leader Badge', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                    subtitle: const Text('Recognized authority in discussions', style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await _service.updateMemberRole(community.id, member.id, CommunityRole.leader);
                      if (success) {
                        _showCustomSnackBar('${member.displayName} is now a Leader');
                      }
                    },
                  ),
                if (member.role != CommunityRole.member)
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF6B7280)),
                    title: const Text('Demote to Member', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await _service.updateMemberRole(community.id, member.id, CommunityRole.member);
                      if (success) {
                        _showCustomSnackBar('${member.displayName} set to Member');
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.label_outline_rounded, color: Color(0xFFD97706)),
                  title: const Text('Edit Member Tag / Title', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditTagDialog(member);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_remove_rounded, color: colorTerracotta),
                  title: Text(
                    'Remove ${member.displayName}',
                    style: const TextStyle(color: colorTerracotta, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await _service.removeMember(community.id, member.id);
                    if (success) {
                      _showCustomSnackBar('${member.displayName} was removed');
                    }
                  },
                ),
              ] else ...[
                // Non-admin view: privacy protected info only
                ListTile(
                  leading: const Icon(Icons.message_rounded, color: Color(0xFF15803D)),
                  title: const Text('Send Direct Message', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCustomSnackBar('Direct messaging initiated');
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF)),
                  title: Text('Admin permissions required to modify roles', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEditTagDialog(CommunityMember member) {
    final controller = TextEditingController(text: member.customTag ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            member.isCurrentUser ? 'Edit Your Member Tag' : 'Edit Tag for ${member.displayName}',
            style: const TextStyle(color: Color(0xFF1B381E), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1F2937)),
                decoration: InputDecoration(
                  hintText: 'e.g. Lead Agronomist, Honey Specialist',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF4F8F4),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await _service.updateMemberTag(widget.communityId, member.id, controller.text);
                if (success) {
                  _showCustomSnackBar('Member tag updated');
                }
              },
              child: const Text('Save Tag', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddMemberModal(Community community) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    CommunityRole selectedRole = CommunityRole.member;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Member to Community',
                        style: TextStyle(color: Color(0xFF1B381E), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                      hintText: 'e.g. Ramesh Kumar',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF4F8F4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: Color(0xFF1F2937)),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                      hintText: '+91 98765 43210',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF4F8F4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    style: const TextStyle(color: Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      labelText: 'Bio / Tagline',
                      labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                      hintText: 'e.g. Wheat farmer, Solan',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF4F8F4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Assign Initial Role:', style: TextStyle(color: Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleChip(CommunityRole.member, selectedRole, (r) => setModalState(() => selectedRole = r)),
                      const SizedBox(width: 8),
                      _buildRoleChip(CommunityRole.leader, selectedRole, (r) => setModalState(() => selectedRole = r)),
                      const SizedBox(width: 8),
                      _buildRoleChip(CommunityRole.admin, selectedRole, (r) => setModalState(() => selectedRole = r)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        final newMember = CommunityMember(
                          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                          displayName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                          role: selectedRole,
                          joinedAt: DateTime.now(),
                          avatarColorValue: 0xFF2E7D32,
                        );
                        final ok = await _service.addMember(widget.communityId, newMember);
                        if (ok) {
                          _showCustomSnackBar('${newMember.displayName} added to group');
                        }
                      },
                      child: const Text('Add to Community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleChip(CommunityRole role, CommunityRole selected, ValueChanged<CommunityRole> onSelect) {
    final bool isSel = role == selected;
    return ChoiceChip(
      label: Text(role.label),
      selected: isSel,
      onSelected: (_) => onSelect(role),
      selectedColor: role == CommunityRole.admin
          ? const Color(0xFF15803D)
          : (role == CommunityRole.leader ? const Color(0xFF0284C7) : const Color(0xFF475569)),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSel ? Colors.white : const Color(0xFF334155),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide(color: isSel ? Colors.transparent : const Color(0xFFCBD5E1)),
    );
  }

  void _showInviteDialog(Community community) {
    final String inviteLink = 'https://krishisaarthi.org/join/${community.inviteCode}';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Invite to ${community.name}',
            style: const TextStyle(color: Color(0xFF1B381E), fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1E7D5)),
                ),
                child: QrImageView(
                  data: inviteLink,
                  version: QrVersions.auto,
                  size: 180.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1B5E20)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1B5E20)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1E7D5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        inviteLink,
                        style: const TextStyle(color: Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF15803D), size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteLink));
                        _showCustomSnackBar('Invite link copied to clipboard');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
              label: const Text('Share Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                Share.share('Join our agricultural community "${community.name}" on Krishi Saarthi: $inviteLink');
                _showCustomSnackBar('Share dialog opened');
              },
            ),
          ],
        );
      },
    );
  }
}
