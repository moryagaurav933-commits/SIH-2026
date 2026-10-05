import 'package:flutter/material.dart';
import '../../localization/app_language.dart';
import '../../localization/app_translations.dart';
import '../../utils/design_tokens.dart';
import 'community_chat_screen.dart';
import 'community_models.dart';
import 'community_service.dart';
import 'create_community_screen.dart';

class CommunityPaletteScreen extends StatefulWidget {
  const CommunityPaletteScreen({super.key});

  @override
  State<CommunityPaletteScreen> createState() => _CommunityPaletteScreenState();
}

class _CommunityPaletteScreenState extends State<CommunityPaletteScreen> with SingleTickerProviderStateMixin {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    _tabController.dispose();
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
          'Are you sure you want to delete "${community.name}"? All chats, files, and posts will be permanently removed.',
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
              if (ok) {
                _showCustomSnackBar('Community "${community.name}" deleted');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final joined = _service.joinedCommunities.where(_filterCommunity).toList();
    final explore = _service.exploreCommunities.where(_filterCommunity).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7), // Clean light green & white palette
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B381E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.currentLanguage == AppLanguage.hi ? 'कृषि समुदाय (Communities)' : 'Krishi Communities',
          style: const TextStyle(color: Color(0xFF1B381E), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded, color: Color(0xFF2E7D32)),
            tooltip: 'Create Community',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1B381E)),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'reset') {
                _service.resetToDefaults();
                _showCustomSnackBar('Default regional communities restored');
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 8),
                    Text('Restore Default Groups', style: TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(102),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F4),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD1E7D5)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: context.currentLanguage == AppLanguage.hi
                          ? 'समुदाय, फसल या विषय खोजें...'
                          : 'Search communities, crops, or topics...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),

              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2E7D32),
                indicatorWeight: 3,
                labelColor: const Color(0xFF1B381E),
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(
                    text: '${context.currentLanguage == AppLanguage.hi ? 'मेरे समूह' : 'My Groups'} (${_service.joinedCommunities.length})',
                  ),
                  Tab(
                    text: '${context.currentLanguage == AppLanguage.hi ? 'खोजें व जुड़ें' : 'Explore & Join'} (${_service.exploreCommunities.length})',
                  ),
                  Tab(
                    text: context.currentLanguage == AppLanguage.hi ? 'लाइव फीड' : 'Live Feed',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          context.currentLanguage == AppLanguage.hi ? 'नया समुदाय' : 'New Community',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Joined Communities (WhatsApp style chat list)
          _buildJoinedList(joined),

          // TAB 2: Explore & Join Communities
          _buildExploreList(explore),

          // TAB 3: All Community Posts Feed (Twitter style aggregated feed)
          _buildAggregatedFeed(),
        ],
      ),
    );
  }

  bool _filterCommunity(Community c) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return c.name.toLowerCase().contains(q) ||
        c.bio.toLowerCase().contains(q) ||
        c.description.toLowerCase().contains(q) ||
        c.category.toLowerCase().contains(q);
  }

  // ==========================================
  // TAB 1: JOINED COMMUNITIES
  // ==========================================
  Widget _buildJoinedList(List<Community> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF15803D), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'No active communities yet',
              style: TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Explore regional farming groups or start your own!',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Create Community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(left: 78, right: 16),
        child: Divider(color: Color(0xFFEDF2EE), height: 1),
      ),
      itemBuilder: (ctx, index) {
        final c = list[index];
        final bool isAdmin = _service.isCurrentUserAdmin(c.id);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommunityChatScreen(communityId: c.id)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar with category icon
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(c.iconColorValue),
                  child: Icon(c.iconData, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),

                // Name, last message, category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Admin',
                                      style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (c.lastMessageTime != null)
                            Text(
                              _formatListTime(c.lastMessageTime!),
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F7F4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFD1E7D5)),
                            ),
                            child: Text(
                              c.category,
                              style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.lastMessageSnippet ?? c.bio,
                              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${c.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 3-dots action popup for Admin delete or Leave
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'delete') {
                      _confirmDeleteCommunity(c);
                    } else if (val == 'leave') {
                      _service.leaveCommunity(c.id);
                      _showCustomSnackBar('Left "${c.name}"');
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (isAdmin)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever_rounded, color: colorTerracotta, size: 18),
                            SizedBox(width: 8),
                            Text('Delete Community', style: TextStyle(color: colorTerracotta, fontWeight: FontWeight.w600, fontSize: 13)),
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
                            Text('Leave Community', style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: EXPLORE & JOIN
  // ==========================================
  Widget _buildExploreList(List<Community> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF15803D), size: 48),
            ),
            const SizedBox(height: 14),
            const Text(
              'You have joined all regional communities!',
              style: TextStyle(color: Color(0xFF1F2937), fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a new custom circle for your village or crop.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final c = list[index];

        return Container(
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(c.iconColorValue),
                    child: Icon(c.iconData, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${c.category} • ${c.memberCount} members',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                c.description,
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_open_rounded, color: Color(0xFF15803D), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        c.isPublic ? 'Public group' : 'Private',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text('Join Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    onPressed: () async {
                      await _service.joinCommunity(c.id);
                      _showCustomSnackBar('Joined "${c.name}"');
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CommunityChatScreen(communityId: c.id)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: AGGREGATED LIVE FEED (Twitter Style)
  // ==========================================
  Widget _buildAggregatedFeed() {
    final allPosts = <Map<String, dynamic>>[];
    for (final c in _service.communities) {
      for (final p in _service.getPosts(c.id)) {
        allPosts.add({'community': c, 'post': p});
      }
    }

    allPosts.sort((a, b) => (b['post'] as CommunityPost).timestamp.compareTo((a['post'] as CommunityPost).timestamp));

    if (allPosts.isEmpty) {
      return const Center(
        child: Text('No community posts published yet', style: TextStyle(color: Color(0xFF6B7280))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: allPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final item = allPosts[index];
        final Community c = item['community'] as Community;
        final CommunityPost p = item['post'] as CommunityPost;
        final bool canDelete = p.authorId == _service.currentUserId || _service.isCurrentUserAdmin(c.id);

        return Container(
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
              // Community Source Pill & Delete option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(c.iconData, color: Color(c.iconColorValue), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        c.name,
                        style: TextStyle(color: Color(c.iconColorValue), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: colorTerracotta, size: 18),
                      tooltip: 'Delete Post',
                      onPressed: () async {
                        final ok = await _service.deletePost(c.id, p.id);
                        if (ok) {
                          _showCustomSnackBar('Post deleted');
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Author info
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: p.authorRole == CommunityRole.admin
                        ? const Color(0xFF15803D)
                        : (p.authorRole == CommunityRole.leader ? const Color(0xFF0284C7) : const Color(0xFF6B7280)),
                    child: Text(
                      p.authorName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.authorName,
                            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: p.authorRole == CommunityRole.admin
                                  ? const Color(0xFFDCFCE7)
                                  : (p.authorRole == CommunityRole.leader ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.authorRole.label,
                              style: TextStyle(
                                color: p.authorRole == CommunityRole.admin
                                    ? const Color(0xFF15803D)
                                    : (p.authorRole == CommunityRole.leader ? const Color(0xFF0369A1) : const Color(0xFF4B5563)),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatListTime(p.timestamp),
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Content
              Text(
                p.content,
                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13.5, height: 1.35),
              ),

              // Tags
              if (p.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: p.tags.map((tag) {
                    return Text(
                      tag.startsWith('#') ? tag : '#$tag',
                      style: const TextStyle(color: Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: Color(0xFFEDF2EE), height: 1),
              const SizedBox(height: 8),

              // Actions (Like, Comment, Share)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => _service.likePost(c.id, p.id),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Icon(
                            p.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: p.isLikedByMe ? Colors.redAccent : const Color(0xFF6B7280),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.likes}',
                            style: TextStyle(color: p.isLikedByMe ? Colors.redAccent : const Color(0xFF6B7280), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CommunityChatScreen(communityId: c.id)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined, color: Color(0xFF6B7280), size: 18),
                          const SizedBox(width: 4),
                          Text('${p.commentsCount}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _showCustomSnackBar('Post shared with regional network');
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
            ],
          ),
        );
      },
    );
  }

  String _formatListTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}
