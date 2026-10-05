import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'community_models.dart';

class CommunityService extends ChangeNotifier {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal() {
    _loadFromStorage();
  }

  static const String _kCommunitiesKey = 'ks_communities_list_v2';
  static const String _kMessagesKey = 'ks_community_messages_v2';
  static const String _kPostsKey = 'ks_community_posts_v2';
  static const String _kCurrentUserId = 'user_you';
  static const String _kCurrentUserName = 'You';

  String get currentUserId => _kCurrentUserId;
  String get currentUserName => _kCurrentUserName;

  final List<Community> _communities = [];
  final Map<String, List<CommunityMessage>> _messages = {};
  final Map<String, List<CommunityPost>> _posts = {};

  List<Community> get communities => List.unmodifiable(_communities);
  List<Community> get joinedCommunities => _communities.where((c) => c.isJoined).toList();
  List<Community> get exploreCommunities => _communities.where((c) => !c.isJoined).toList();

  List<CommunityMessage> getMessages(String communityId) {
    return List.unmodifiable(_messages[communityId] ?? []);
  }

  List<CommunityPost> getPosts(String communityId) {
    return List.unmodifiable(_posts[communityId] ?? []);
  }

  Community? getCommunity(String communityId) {
    try {
      return _communities.firstWhere((c) => c.id == communityId);
    } catch (_) {
      return null;
    }
  }

  bool isCurrentUserAdmin(String communityId) {
    final c = getCommunity(communityId);
    if (c == null) return false;
    return c.isUserAdmin(_kCurrentUserId);
  }

  bool isCurrentUserLeaderOrAdmin(String communityId) {
    final c = getCommunity(communityId);
    if (c == null) return false;
    return c.isUserLeaderOrAdmin(_kCurrentUserId);
  }

  // ==========================================
  // STORAGE PERSISTENCE
  // ==========================================
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commStr = prefs.getString(_kCommunitiesKey);
      final msgStr = prefs.getString(_kMessagesKey);
      final postStr = prefs.getString(_kPostsKey);

      if (commStr != null && commStr.isNotEmpty) {
        final List list = jsonDecode(commStr);
        _communities.clear();
        _communities.addAll(list.map((item) => Community.fromJson(item as Map<String, dynamic>)));
      } else {
        _seedInitialCommunities();
      }

      if (msgStr != null && msgStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(msgStr);
        _messages.clear();
        map.forEach((k, v) {
          _messages[k] = (v as List).map((i) => CommunityMessage.fromJson(i as Map<String, dynamic>)).toList();
        });
      } else {
        _seedInitialMessages();
      }

      if (postStr != null && postStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(postStr);
        _posts.clear();
        map.forEach((k, v) {
          _posts[k] = (v as List).map((i) => CommunityPost.fromJson(i as Map<String, dynamic>)).toList();
        });
      } else {
        _seedInitialPosts();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('CommunityService load error: $e');
      _seedInitialCommunities();
      _seedInitialMessages();
      _seedInitialPosts();
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCommunitiesKey, jsonEncode(_communities.map((c) => c.toJson()).toList()));

      final Map<String, dynamic> msgMap = {};
      _messages.forEach((k, v) {
        msgMap[k] = v.map((m) => m.toJson()).toList();
      });
      await prefs.setString(_kMessagesKey, jsonEncode(msgMap));

      final Map<String, dynamic> postMap = {};
      _posts.forEach((k, v) {
        postMap[k] = v.map((p) => p.toJson()).toList();
      });
      await prefs.setString(_kPostsKey, jsonEncode(postMap));
    } catch (e) {
      debugPrint('CommunityService save error: $e');
    }
  }

  // ==========================================
  // CHAT ACTIONS (WhatsApp style)
  // ==========================================
  Future<void> sendTextMessage(String communityId, String text) async {
    if (text.trim().isEmpty) return;

    final msg = CommunityMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: _kCurrentUserId,
      senderName: _kCurrentUserName,
      senderPhone: '+91 98160 12345',
      senderRole: isCurrentUserAdmin(communityId)
          ? CommunityRole.admin
          : (isCurrentUserLeaderOrAdmin(communityId) ? CommunityRole.leader : CommunityRole.member),
      content: text.trim(),
      type: MessageType.text,
      timestamp: DateTime.now(),
      senderColorValue: 0xFF005C4B,
    );

    _messages.putIfAbsent(communityId, () => []).add(msg);
    _updateCommunityLastMessage(communityId, text.trim());
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> sendPhotoMessage(String communityId, String imagePath, String caption) async {
    final msg = CommunityMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: _kCurrentUserId,
      senderName: _kCurrentUserName,
      senderPhone: '+91 98160 12345',
      content: caption.trim().isEmpty ? '📷 Photo' : caption.trim(),
      type: MessageType.image,
      timestamp: DateTime.now(),
      mediaUrl: imagePath,
      senderColorValue: 0xFF005C4B,
    );

    _messages.putIfAbsent(communityId, () => []).add(msg);
    _updateCommunityLastMessage(communityId, '📷 Photo');
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> sendAudioMessage(String communityId, int durationSeconds) async {
    final minutes = durationSeconds ~/ 60;
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    final durationStr = '$minutes:$seconds';

    final msg = CommunityMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: _kCurrentUserId,
      senderName: _kCurrentUserName,
      senderPhone: '+91 98160 12345',
      content: '🎤 Voice message ($durationStr)',
      type: MessageType.audio,
      timestamp: DateTime.now(),
      audioDurationSeconds: durationSeconds,
      senderColorValue: 0xFF005C4B,
    );

    _messages.putIfAbsent(communityId, () => []).add(msg);
    _updateCommunityLastMessage(communityId, '🎤 Voice message ($durationStr)');
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> sendFileMessage(String communityId, String fileName, String fileSize) async {
    final msg = CommunityMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: _kCurrentUserId,
      senderName: _kCurrentUserName,
      senderPhone: '+91 98160 12345',
      content: '📄 $fileName',
      type: MessageType.file,
      timestamp: DateTime.now(),
      fileName: fileName,
      fileSize: fileSize,
      senderColorValue: 0xFF005C4B,
    );

    _messages.putIfAbsent(communityId, () => []).add(msg);
    _updateCommunityLastMessage(communityId, '📄 $fileName');
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> sendPoll(String communityId, String question, List<String> optionTexts, bool allowMultiple) async {
    if (question.trim().isEmpty || optionTexts.length < 2) return;

    final pollOptions = optionTexts
        .asMap()
        .entries
        .map((e) => CommunityPollOption(
              id: 'opt_${e.key}',
              text: e.value.trim(),
              voterUserIds: [],
              voterNames: [],
            ))
        .toList();

    final poll = CommunityPoll(
      id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
      question: question.trim(),
      options: pollOptions,
      allowMultipleAnswers: allowMultiple,
      createdAt: DateTime.now(),
      creatorId: _kCurrentUserId,
      creatorName: _kCurrentUserName,
    );

    final msg = CommunityMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: _kCurrentUserId,
      senderName: _kCurrentUserName,
      senderPhone: '+91 98160 12345',
      content: '📊 Poll: ${question.trim()}',
      type: MessageType.poll,
      timestamp: DateTime.now(),
      poll: poll,
      senderColorValue: 0xFF005C4B,
    );

    _messages.putIfAbsent(communityId, () => []).add(msg);
    _updateCommunityLastMessage(communityId, '📊 Poll: ${question.trim()}');
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> votePoll(String communityId, String messageId, String optionId) async {
    final list = _messages[communityId];
    if (list == null) return;

    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final msg = list[idx];
    final poll = msg.poll;
    if (poll == null || poll.isClosed) return;

    final updatedOptions = poll.options.map((opt) {
      if (opt.id == optionId) {
        final hasVoted = opt.voterUserIds.contains(_kCurrentUserId);
        final newVoterIds = List<String>.from(opt.voterUserIds);
        final newVoterNames = List<String>.from(opt.voterNames);

        if (hasVoted) {
          // Toggle off
          newVoterIds.remove(_kCurrentUserId);
          newVoterNames.remove(_kCurrentUserName);
        } else {
          // Vote for this option
          newVoterIds.add(_kCurrentUserId);
          newVoterNames.add(_kCurrentUserName);
        }
        return opt.copyWith(voterUserIds: newVoterIds, voterNames: newVoterNames);
      } else {
        if (!poll.allowMultipleAnswers) {
          // In single choice, remove user vote from other options
          final newVoterIds = List<String>.from(opt.voterUserIds)..remove(_kCurrentUserId);
          final newVoterNames = List<String>.from(opt.voterNames)..remove(_kCurrentUserName);
          return opt.copyWith(voterUserIds: newVoterIds, voterNames: newVoterNames);
        }
        return opt;
      }
    }).toList();

    final updatedPoll = poll.copyWith(options: updatedOptions);
    list[idx] = msg.copyWith(poll: updatedPoll);

    notifyListeners();
    await _saveToStorage();
  }

  Future<bool> togglePinMessage(String communityId, String messageId) async {
    if (!isCurrentUserLeaderOrAdmin(communityId)) return false;

    final list = _messages[communityId];
    if (list == null) return false;

    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return false;

    final targetMsg = list[idx];
    final bool newPinned = !targetMsg.isPinned;

    // Reset others if pinning single banner
    for (int i = 0; i < list.length; i++) {
      if (list[i].isPinned) {
        list[i] = list[i].copyWith(isPinned: false);
      }
    }

    list[idx] = targetMsg.copyWith(isPinned: newPinned);

    // Update community banner
    final commIdx = _communities.indexWhere((c) => c.id == communityId);
    if (commIdx != -1) {
      _communities[commIdx] = _communities[commIdx].copyWith(
        pinnedMessageId: newPinned ? targetMsg.id : null,
        pinnedMessageSnippet: newPinned ? targetMsg.content : null,
      );
    }

    // Add a system notification message
    final sysMsg = CommunityMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: 'system',
      senderName: 'System',
      content: newPinned
          ? '$_kCurrentUserName pinned a message'
          : '$_kCurrentUserName unpinned a message',
      type: MessageType.system,
      timestamp: DateTime.now(),
    );
    list.add(sysMsg);

    notifyListeners();
    await _saveToStorage();
    return true;
  }

  Future<void> addReaction(String communityId, String messageId, String emoji) async {
    final list = _messages[communityId];
    if (list == null) return;

    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final msg = list[idx];
    final reactions = List<MessageReaction>.from(msg.reactions);

    final rIdx = reactions.indexWhere((r) => r.emoji == emoji);
    if (rIdx != -1) {
      final existing = reactions[rIdx];
      if (existing.userIds.contains(_kCurrentUserId)) {
        // Remove reaction
        final newUsers = List<String>.from(existing.userIds)..remove(_kCurrentUserId);
        if (newUsers.isEmpty) {
          reactions.removeAt(rIdx);
        } else {
          reactions[rIdx] = existing.copyWith(userIds: newUsers);
        }
      } else {
        // Add user
        reactions[rIdx] = existing.copyWith(userIds: [...existing.userIds, _kCurrentUserId]);
      }
    } else {
      // New emoji reaction
      reactions.add(MessageReaction(emoji: emoji, userIds: [_kCurrentUserId]));
    }

    list[idx] = msg.copyWith(reactions: reactions);
    notifyListeners();
    await _saveToStorage();
  }

  void _updateCommunityLastMessage(String communityId, String snippet) {
    final idx = _communities.indexWhere((c) => c.id == communityId);
    if (idx != -1) {
      _communities[idx] = _communities[idx].copyWith(
        lastMessageSnippet: snippet,
        lastMessageTime: DateTime.now(),
      );
    }
  }

  // ==========================================
  // TWITTER / X STYLE COMMUNITY POSTS & FEED
  // ==========================================
  Future<void> createPost(
    String communityId,
    String content, {
    List<String> images = const [],
    List<String> tags = const [],
  }) async {
    if (content.trim().isEmpty) return;

    final post = CommunityPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      authorId: _kCurrentUserId,
      authorName: _kCurrentUserName,
      authorRole: isCurrentUserAdmin(communityId)
          ? CommunityRole.admin
          : (isCurrentUserLeaderOrAdmin(communityId) ? CommunityRole.leader : CommunityRole.member),
      content: content.trim(),
      images: images,
      timestamp: DateTime.now(),
      likes: 0,
      isLikedByMe: false,
      commentsCount: 0,
      tags: tags,
    );

    _posts.putIfAbsent(communityId, () => []).insert(0, post);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> likePost(String communityId, String postId) async {
    final list = _posts[communityId];
    if (list == null) return;

    final idx = list.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = list[idx];
    final bool newLiked = !post.isLikedByMe;
    final int newLikes = newLiked ? (post.likes + 1) : (post.likes - 1).clamp(0, 99999);

    list[idx] = post.copyWith(isLikedByMe: newLiked, likes: newLikes);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addCommentToPost(String communityId, String postId, String text) async {
    if (text.trim().isEmpty) return;
    final list = _posts[communityId];
    if (list == null) return;

    final idx = list.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = list[idx];
    final comment = CommunityComment(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      authorName: _kCurrentUserName,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    final updatedComments = List<CommunityComment>.from(post.comments)..add(comment);
    list[idx] = post.copyWith(
      comments: updatedComments,
      commentsCount: updatedComments.length,
    );

    notifyListeners();
    await _saveToStorage();
  }

  Future<bool> deletePost(String communityId, String postId) async {
    final list = _posts[communityId];
    if (list == null) return false;

    final idx = list.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;

    final post = list[idx];
    // Author or Admin can delete post
    if (post.authorId != _kCurrentUserId && !isCurrentUserAdmin(communityId)) {
      return false;
    }

    list.removeAt(idx);
    notifyListeners();
    await _saveToStorage();
    return true;
  }

  Future<bool> deleteMessage(String communityId, String messageId) async {
    final list = _messages[communityId];
    if (list == null) return false;

    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return false;

    final msg = list[idx];
    // Sender or Admin can delete message
    if (msg.senderId != _kCurrentUserId && !isCurrentUserAdmin(communityId)) {
      return false;
    }

    list.removeAt(idx);

    // If deleted message was pinned, clear pin snippet
    final commIdx = _communities.indexWhere((c) => c.id == communityId);
    if (commIdx != -1 && _communities[commIdx].pinnedMessageId == messageId) {
      _communities[commIdx] = _communities[commIdx].copyWith(
        pinnedMessageId: null,
        pinnedMessageSnippet: null,
      );
    }

    notifyListeners();
    await _saveToStorage();
    return true;
  }

  // ==========================================
  // MEMBER MANAGEMENT & ADMIN PERMISSIONS
  // ==========================================
  Future<bool> updateMemberRole(String communityId, String targetUserId, CommunityRole newRole) async {
    // SECURITY CHECK: Only admin can change roles
    if (!isCurrentUserAdmin(communityId)) return false;

    final commIdx = _communities.indexWhere((c) => c.id == communityId);
    if (commIdx == -1) return false;

    final comm = _communities[commIdx];
    final memberIdx = comm.members.indexWhere((m) => m.id == targetUserId);
    if (memberIdx == -1) return false;

    final targetMember = comm.members[memberIdx];
    final updatedMember = targetMember.copyWith(role: newRole);

    final updatedMembers = List<CommunityMember>.from(comm.members);
    updatedMembers[memberIdx] = updatedMember;

    _communities[commIdx] = comm.copyWith(members: updatedMembers);

    // Add system notification in chat
    final sysMsg = CommunityMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: 'system',
      senderName: 'System',
      content: '${targetMember.displayName} is now a ${newRole.label}',
      type: MessageType.system,
      timestamp: DateTime.now(),
    );
    _messages.putIfAbsent(communityId, () => []).add(sysMsg);

    notifyListeners();
    await _saveToStorage();
    return true;
  }

  Future<bool> updateMemberTag(String communityId, String targetUserId, String newTag) async {
    // Current user can edit own tag, or Admin can edit anyone's tag
    final bool canEdit = (targetUserId == _kCurrentUserId) || isCurrentUserAdmin(communityId);
    if (!canEdit) return false;

    final commIdx = _communities.indexWhere((c) => c.id == communityId);
    if (commIdx == -1) return false;

    final comm = _communities[commIdx];
    final memberIdx = comm.members.indexWhere((m) => m.id == targetUserId);
    if (memberIdx == -1) return false;

    final updatedMembers = List<CommunityMember>.from(comm.members);
    updatedMembers[memberIdx] = updatedMembers[memberIdx].copyWith(customTag: newTag.trim());

    _communities[commIdx] = comm.copyWith(members: updatedMembers);

    notifyListeners();
    await _saveToStorage();
    return true;
  }

  Future<bool> addMember(String communityId, CommunityMember newMember) async {
    // SECURITY CHECK: Only admin can add members directly
    if (!isCurrentUserAdmin(communityId)) return false;

    final commIdx = _communities.indexWhere((c) => c.id == communityId);
    if (commIdx == -1) return false;

    final comm = _communities[commIdx];
    if (comm.members.any((m) => m.id == newMember.id)) return false;

    final updatedMembers = List<CommunityMember>.from(comm.members)..add(newMember);
    _communities[commIdx] = comm.copyWith(members: updatedMembers);

    final sysMsg = CommunityMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: 'system',
      senderName: 'System',
      content: '${newMember.displayName} joined the group',
      type: MessageType.system,
      timestamp: DateTime.now(),
    );
    _messages.putIfAbsent(communityId, () => []).add(sysMsg);

    notifyListeners();
    await _saveToStorage();
    return true;
  }

  Future<bool> removeMember(String communityId, String targetUserId) async {
    if (!isCurrentUserAdmin(communityId)) return false;
    if (targetUserId == _kCurrentUserId) return false; // Cannot remove self this way

    final commIdx = _communities.indexWhere((c) => c.id == communityId);
    if (commIdx == -1) return false;

    final comm = _communities[commIdx];
    final removed = comm.members.firstWhere((m) => m.id == targetUserId, orElse: () => comm.members.first);
    final updatedMembers = comm.members.where((m) => m.id != targetUserId).toList();

    _communities[commIdx] = comm.copyWith(members: updatedMembers);

    final sysMsg = CommunityMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: 'system',
      senderName: 'System',
      content: '${removed.displayName} was removed from the community',
      type: MessageType.system,
      timestamp: DateTime.now(),
    );
    _messages.putIfAbsent(communityId, () => []).add(sysMsg);

    notifyListeners();
    await _saveToStorage();
    return true;
  }

  // ==========================================
  // CREATE & JOIN COMMUNITIES
  // ==========================================
  Future<Community> createCommunity({
    required String name,
    required String bio,
    required String description,
    required String category,
    required bool isPublic,
    int iconCodePoint = 0xe318,
    int iconColorValue = 0xFF2E7D32,
    List<CommunityMember>? initialMembers,
  }) async {
    final String newId = 'comm_${DateTime.now().millisecondsSinceEpoch}';

    // Creator is always initial Admin
    final currentUserMember = CommunityMember(
      id: _kCurrentUserId,
      displayName: _kCurrentUserName,
      bio: 'Community Creator & Organizer',
      customTag: 'Founder',
      role: CommunityRole.admin,
      joinedAt: DateTime.now(),
      isCurrentUser: true,
      avatarColorValue: 0xFF2E7D32,
    );

    final membersList = <CommunityMember>[currentUserMember];
    if (initialMembers != null) {
      for (final m in initialMembers) {
        if (m.id != _kCurrentUserId) {
          membersList.add(m);
        }
      }
    }

    final newCommunity = Community(
      id: newId,
      name: name.trim(),
      bio: bio.trim(),
      description: description.trim(),
      category: category,
      iconCodePoint: iconCodePoint,
      iconColorValue: iconColorValue,
      createdBy: _kCurrentUserId,
      createdAt: DateTime.now(),
      isPublic: isPublic,
      isJoined: true,
      members: membersList,
      lastMessageSnippet: 'Welcome to $name!',
      lastMessageTime: DateTime.now(),
      inviteCode: 'KS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );

    _communities.insert(0, newCommunity);

    // Initial system message
    final sysMsg = CommunityMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      communityId: newId,
      senderId: 'system',
      senderName: 'System',
      content: '$_kCurrentUserName created group "$name"',
      type: MessageType.system,
      timestamp: DateTime.now(),
    );
    _messages[newId] = [sysMsg];

    notifyListeners();
    await _saveToStorage();
    return newCommunity;
  }

  Future<void> joinCommunity(String communityId) async {
    final idx = _communities.indexWhere((c) => c.id == communityId);
    if (idx == -1) return;

    final comm = _communities[idx];
    if (comm.isJoined) return;

    final userMember = CommunityMember(
      id: _kCurrentUserId,
      displayName: _kCurrentUserName,
      bio: 'Kisan & Agri Explorer',
      role: CommunityRole.member,
      joinedAt: DateTime.now(),
      isCurrentUser: true,
      avatarColorValue: 0xFF2E7D32,
    );

    final updatedMembers = List<CommunityMember>.from(comm.members)..add(userMember);
    _communities[idx] = comm.copyWith(
      isJoined: true,
      members: updatedMembers,
    );

    final sysMsg = CommunityMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      senderId: 'system',
      senderName: 'System',
      content: '$_kCurrentUserName joined via invite link',
      type: MessageType.system,
      timestamp: DateTime.now(),
    );
    _messages.putIfAbsent(communityId, () => []).add(sysMsg);

    notifyListeners();
    await _saveToStorage();
  }

  Future<void> leaveCommunity(String communityId) async {
    final idx = _communities.indexWhere((c) => c.id == communityId);
    if (idx == -1) return;

    final comm = _communities[idx];
    final updatedMembers = comm.members.where((m) => m.id != _kCurrentUserId).toList();
    _communities[idx] = comm.copyWith(
      isJoined: false,
      members: updatedMembers,
    );

    notifyListeners();
    await _saveToStorage();
  }

  Future<bool> deleteCommunity(String communityId) async {
    // SECURITY CHECK: Only Admin can delete the community
    if (!isCurrentUserAdmin(communityId)) return false;

    final idx = _communities.indexWhere((c) => c.id == communityId);
    if (idx == -1) return false;

    _communities.removeAt(idx);
    _messages.remove(communityId);
    _posts.remove(communityId);

    notifyListeners();
    await _saveToStorage();
    return true;
  }

  Future<void> resetToDefaults() async {
    _seedInitialCommunities();
    _seedInitialMessages();
    _seedInitialPosts();
    notifyListeners();
    await _saveToStorage();
  }

  // ==========================================
  // SEED REALISTIC INITIAL DATA
  // ==========================================
  void _seedInitialCommunities() {
    _communities.clear();

    // 1. Churdhar Trek & Farmers Club (Image 1 & 2 exact representation)
    final churdharMembers = [
      CommunityMember(
        id: 'user_you',
        displayName: 'You',
        bio: 'The duty of self-discovery',
        customTag: 'Organizer',
        role: CommunityRole.admin,
        joinedAt: DateTime(2026, 8, 15),
        isCurrentUser: true,
        avatarColorValue: 0xFFF59E0B,
      ),
      CommunityMember(
        id: 'user_piyush',
        displayName: 'Piyush .. cR',
        bio: 'Mandi trade & logistics',
        role: CommunityRole.admin,
        joinedAt: DateTime(2026, 8, 16),
        avatarColorValue: 0xFF0284C7,
      ),
      CommunityMember(
        id: 'user_preetika',
        displayName: '~ preetikapanwar',
        phone: '+91 6230 964 723',
        bio: 'ICAR Plant Pathologist & Soil Expert',
        role: CommunityRole.admin,
        joinedAt: DateTime(2026, 8, 16),
        avatarColorValue: 0xFFEC4899,
      ),
      CommunityMember(
        id: 'user_mayank',
        displayName: 'Mayank .... Bro ...',
        bio: 'Stoic',
        customTag: 'Field Scout',
        role: CommunityRole.leader,
        joinedAt: DateTime(2026, 8, 17),
        avatarColorValue: 0xFF8B5CF6,
      ),
      CommunityMember(
        id: 'user_okay',
        displayName: '..... Okay....',
        bio: 'Apple Orchardist, Kotkhai',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 18),
        avatarColorValue: 0xFF64748B,
      ),
      CommunityMember(
        id: 'user_aditya',
        displayName: 'Aditya Kumar,BCA',
        bio: 'AgriTech Drone Pilot',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 19),
        avatarColorValue: 0xFF0D9488,
      ),
      CommunityMember(
        id: 'user_akshu',
        displayName: 'Akshu...',
        bio: 'Organic Farming Practitioner',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 20),
        avatarColorValue: 0xFFD97706,
      ),
      CommunityMember(
        id: 'user_ankit',
        displayName: 'Ankit Rana',
        bio: 'Seed & Fertilizer Collective',
        customTag: 'Coordinator',
        role: CommunityRole.leader,
        joinedAt: DateTime(2026, 8, 21),
        avatarColorValue: 0xFF2563EB,
      ),
      CommunityMember(
        id: 'user_avani',
        displayName: 'Avani Yarav',
        bio: 'Floriculture and Greenhouses',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 22),
        avatarColorValue: 0xFF9333EA,
      ),
      CommunityMember(
        id: 'user_bhandari',
        displayName: 'Bhandari .. Bhai',
        bio: 'Himachal Agro Transport',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 23),
        avatarColorValue: 0xFF059669,
      ),
      CommunityMember(
        id: 'user_shiivang',
        displayName: 'Shiivang Manhass',
        phone: '+91 95180 12365',
        bio: 'Expedition Guide & Mountain Farmer',
        role: CommunityRole.leader,
        joinedAt: DateTime(2026, 8, 24),
        avatarColorValue: 0xFFEA580C,
      ),
      CommunityMember(
        id: 'user_sanyam',
        displayName: '~ Sanyam',
        phone: '+91 95180 12365',
        bio: 'Smart Polyhouse automation',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 25),
        avatarColorValue: 0xFF16A34A,
      ),
      CommunityMember(
        id: 'user_utkarsh',
        displayName: 'Utkarsh... Bhai ......',
        bio: 'High altitude crop trialist',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 26),
        avatarColorValue: 0xFF4F46E5,
      ),
      CommunityMember(
        id: 'user_bhavishya',
        displayName: '~Bhavishya Panwar',
        bio: 'Mandi commission agent & advisor',
        role: CommunityRole.member,
        joinedAt: DateTime(2026, 8, 27),
        avatarColorValue: 0xFF0284C7,
      ),
    ];

    _communities.add(Community(
      id: 'comm_churdhar',
      name: 'Churdhar Trek & Farmers Club',
      bio: 'High altitude farming, trek coordination & community grain pool',
      description:
          'Official coordination circle for Churdhar mountain farmers and agro-tourists. We discuss trek logistics, weather advisories, local honey/apple trade, and emergency mesh communication.',
      category: 'Horticulture & Trek',
      iconCodePoint: 0xe644, // terrain / landscape
      iconColorValue: 0xFF2E7D32,
      createdBy: 'user_you',
      createdAt: DateTime(2026, 8, 15),
      isPublic: true,
      isJoined: true,
      members: churdharMembers,
      pinnedMessageId: 'msg_churdhar_pinned',
      pinnedMessageSnippet: 'Reach at ATM 4:45 Sharp (Changed)*',
      lastMessageSnippet: 'Bhandari .. Bhai: Hi',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 42)),
      unreadCount: 3,
      inviteCode: 'CHURDHAR-2026',
    ));

    // 2. Solan & Shimla Apple Innovators
    final appleMembers = [
      CommunityMember(
        id: 'user_you',
        displayName: 'You',
        bio: 'The duty of self-discovery',
        role: CommunityRole.admin,
        joinedAt: DateTime(2026, 7, 1),
        isCurrentUser: true,
      ),
      CommunityMember(
        id: 'user_dr_verma',
        displayName: 'Dr. Ramesh Verma (ICAR)',
        bio: 'Senior Pomologist, ICAR-CPRI',
        role: CommunityRole.admin,
        joinedAt: DateTime(2026, 7, 2),
      ),
      CommunityMember(
        id: 'user_kuldeep',
        displayName: 'Kuldeep Sharma (Solan)',
        bio: 'M9 Rootstock Apple Pioneer',
        role: CommunityRole.leader,
        joinedAt: DateTime(2026, 7, 3),
      ),
    ];

    _communities.add(Community(
      id: 'comm_apple',
      name: 'Solan & Shimla Apple Innovators',
      bio: 'Ultra High Density apple plantation & disease surveillance',
      description:
          'Discussion circle for apple cultivators across Solan, Shimla, and Kinnaur. Covers scab prevention, blossom thinning protocols, and wholesale grading standards.',
      category: 'Horticulture',
      iconCodePoint: 0xe000, // yard / nature
      iconColorValue: 0xFFD32F2F,
      createdBy: 'user_dr_verma',
      createdAt: DateTime(2026, 7, 1),
      isPublic: true,
      isJoined: true,
      members: appleMembers,
      lastMessageSnippet: 'Dr. Verma: Check leaf underside for Red Spider Mite nymphs',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      inviteCode: 'APPLE-INNOVATE',
    ));

    // 3. Krishi Vigyan Kendra (KVK) & ICAR Advisory
    _communities.add(Community(
      id: 'comm_kvk',
      name: 'ICAR & KVK Agronomy Central',
      bio: 'Verified agricultural science advisory directly from scientists',
      description:
          'Direct channel from Krishi Vigyan Kendra scientists to grassroots growers. Daily certified weather forecasts, spray schedules, and certified hybrid seed allotments.',
      category: 'KVK & Scientists',
      iconCodePoint: 0xe585, // school / science
      iconColorValue: 0xFF1D4ED8,
      createdBy: 'user_dr_verma',
      createdAt: DateTime(2026, 6, 10),
      isPublic: true,
      isJoined: true,
      members: [
        CommunityMember(
          id: 'user_you',
          displayName: 'You',
          bio: 'Progressive Farmer',
          role: CommunityRole.member,
          joinedAt: DateTime(2026, 6, 12),
          isCurrentUser: true,
        ),
        CommunityMember(
          id: 'user_dr_verma',
          displayName: 'Dr. Ramesh Verma',
          bio: 'Chief Agronomist',
          role: CommunityRole.admin,
          joinedAt: DateTime(2026, 6, 10),
        ),
      ],
      lastMessageSnippet: 'KVK Alert: Yellow Rust advisory issued for North Plains',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
      unreadCount: 1,
      inviteCode: 'ICAR-KVK-LIVE',
    ));

    // 4. UP & Punjab Gehu (Wheat) Alliance (Discoverable)
    _communities.add(Community(
      id: 'comm_wheat',
      name: 'UP & Punjab Gehu (Wheat) Alliance',
      bio: 'Rabi harvest pooling, combine harvester sharing & MSP updates',
      description:
          '210 farmers coordinating harvest timing, direct APMC procurement, combine harvesters rental sharing, and PBW-826 seed distributions.',
      category: 'Field Crops',
      iconCodePoint: 0xe25a, // grass
      iconColorValue: 0xFFF59E0B,
      createdBy: 'user_gurpreet',
      createdAt: DateTime(2026, 5, 20),
      isPublic: true,
      isJoined: false, // Discoverable
      members: [
        CommunityMember(
          id: 'user_gurpreet',
          displayName: 'Sardar Gurpreet Singh',
          bio: 'Ludhiana Wheat Collective',
          role: CommunityRole.admin,
          joinedAt: DateTime(2026, 5, 20),
        ),
      ],
      lastMessageSnippet: 'Tractor and laser land leveler available on rent',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      inviteCode: 'GEHU-MSP-PUNJAB',
    ));

    // 5. Mandi Spot Prices & Direct FPO Market (Discoverable)
    _communities.add(Community(
      id: 'comm_mandi',
      name: 'Mandi Spot Prices & Direct FPO Trade',
      bio: 'Daily verified mandi arrivals, buyer connects & zero middleman auctions',
      description:
          'Community for transparent rate reporting from Azadpur, Solan, Khanna, and Karnal mandis with transport pooling.',
      category: 'Mandi & Pricing',
      iconCodePoint: 0xe8cc, // storefront
      iconColorValue: 0xFF10B981,
      createdBy: 'user_ramlal',
      createdAt: DateTime(2026, 5, 1),
      isPublic: true,
      isJoined: false, // Discoverable
      members: [
        CommunityMember(
          id: 'user_ramlal',
          displayName: 'Ramlal Mandi Coordinator',
          bio: 'Registered trader',
          role: CommunityRole.admin,
          joinedAt: DateTime(2026, 5, 1),
        ),
      ],
      lastMessageSnippet: 'Tomato rates touched ₹48/kg in Solan terminal yard today',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 0,
      inviteCode: 'MANDI-DIRECT-26',
    ));
  }

  void _seedInitialMessages() {
    _messages.clear();

    // Messages for Churdhar Trek matching Image 1
    _messages['comm_churdhar'] = [
      CommunityMessage(
        id: 'msg_churdhar_0',
        communityId: 'comm_churdhar',
        senderId: 'user_sanyam',
        senderName: '~ Sanyam',
        senderPhone: '+91 95180 12365',
        senderRole: CommunityRole.member,
        content: 'Okay 👍',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 12)),
        senderColorValue: 0xFF16A34A,
      ),
      CommunityMessage(
        id: 'msg_churdhar_poll',
        communityId: 'comm_churdhar',
        senderId: 'user_shiivang',
        senderName: 'Shiivang Manhass',
        senderRole: CommunityRole.leader,
        content: '📊 Poll: Reach at ATM 4:50 AM Exactly !',
        type: MessageType.poll,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 9)),
        senderColorValue: 0xFFEA580C,
        poll: CommunityPoll(
          id: 'poll_atm_time',
          question: 'Reach at ATM 4:50 AM Exactly !',
          options: [
            const CommunityPollOption(
              id: 'opt_1',
              text: 'Will be there 🕯️',
              voterUserIds: ['user_shiivang', 'user_ankit', 'user_bhandari', 'user_piyush', 'user_preetika'],
              voterNames: ['Shiivang Manhass', 'Ankit Rana', 'Bhandari .. Bhai', 'Piyush .. cR', '~ preetikapanwar'],
            ),
            const CommunityPollOption(
              id: 'opt_2',
              text: 'Sona hai 🛌',
              voterUserIds: ['user_sanyam'],
              voterNames: ['~ Sanyam'],
            ),
          ],
          allowMultipleAnswers: false,
          isClosed: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 9)),
          creatorId: 'user_shiivang',
          creatorName: 'Shiivang Manhass',
        ),
      ),
      CommunityMessage(
        id: 'msg_churdhar_sys1',
        communityId: 'comm_churdhar',
        senderId: 'system',
        senderName: 'System',
        content: 'Shiivang Manhass pinned a message',
        type: MessageType.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      ),
      CommunityMessage(
        id: 'msg_churdhar_pinned',
        communityId: 'comm_churdhar',
        senderId: 'user_shiivang',
        senderName: 'Shiivang Manhass',
        senderRole: CommunityRole.leader,
        content: 'Reach at ATM 4:45 Sharp (Changed)* 👈',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 53)),
        isPinned: true,
        senderColorValue: 0xFFEA580C,
      ),
      CommunityMessage(
        id: 'msg_churdhar_sys2',
        communityId: 'comm_churdhar',
        senderId: 'system',
        senderName: 'System',
        content: 'Shiivang Manhass pinned a message',
        type: MessageType.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 52)),
      ),
      CommunityMessage(
        id: 'msg_churdhar_sanyam_joke',
        communityId: 'comm_churdhar',
        senderId: 'user_sanyam',
        senderName: '~ Sanyam',
        senderPhone: '+91 95180 12365',
        senderRole: CommunityRole.member,
        content: 'I will be there at 4:30 💀',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 51)),
        isEdited: true,
        reactions: [
          const MessageReaction(emoji: '👍', userIds: ['user_you', 'user_shiivang', 'user_ankit']),
        ],
        senderColorValue: 0xFF16A34A,
      ),
      CommunityMessage(
        id: 'msg_churdhar_ankit',
        communityId: 'comm_churdhar',
        senderId: 'user_ankit',
        senderName: 'Ankit Rana',
        senderRole: CommunityRole.leader,
        content: 'Jo jo 10 bande hai shoolini se zero point ke liye kal woh \'Hi\' message kardo group mein',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 33)),
        senderColorValue: 0xFF2563EB,
      ),
      CommunityMessage(
        id: 'msg_churdhar_shiivang_hi',
        communityId: 'comm_churdhar',
        senderId: 'user_shiivang',
        senderName: 'Shiivang Manhass',
        senderRole: CommunityRole.leader,
        content: 'Hi',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 32)),
        senderColorValue: 0xFFEA580C,
      ),
      CommunityMessage(
        id: 'msg_churdhar_sanyam_hi',
        communityId: 'comm_churdhar',
        senderId: 'user_sanyam',
        senderName: '~ Sanyam',
        senderPhone: '+91 95180 12365',
        senderRole: CommunityRole.member,
        content: 'Hi',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 32)),
        senderColorValue: 0xFF16A34A,
      ),
      CommunityMessage(
        id: 'msg_churdhar_bhandari_hi',
        communityId: 'comm_churdhar',
        senderId: 'user_bhandari',
        senderName: 'Bhandari .. Bhai',
        senderRole: CommunityRole.member,
        content: 'Hi',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
        senderColorValue: 0xFF059669,
      ),
    ];

    // Messages for Apple Innovators
    _messages['comm_apple'] = [
      CommunityMessage(
        id: 'msg_apple_1',
        communityId: 'comm_apple',
        senderId: 'user_dr_verma',
        senderName: 'Dr. Ramesh Verma (ICAR)',
        senderRole: CommunityRole.admin,
        content: 'Weather department has signaled sudden hail forecast for Theog & Kotkhai belt tonight. Please ensure anti-hail nets are securely tensioned.',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isPinned: true,
        reactions: [
          const MessageReaction(emoji: '🙏', userIds: ['user_you', 'user_kuldeep']),
        ],
        senderColorValue: 0xFFD32F2F,
      ),
      CommunityMessage(
        id: 'msg_apple_2',
        communityId: 'comm_apple',
        senderId: 'user_kuldeep',
        senderName: 'Kuldeep Sharma (Solan)',
        senderRole: CommunityRole.leader,
        content: 'We noticed early powdery mildew on Royal Gala grafted branch. Sprayed Wettable Sulfur 80% WP yesterday, response is looking positive.',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        senderColorValue: 0xFF0284C7,
      ),
    ];
  }

  void _seedInitialPosts() {
    _posts.clear();

    _posts['comm_churdhar'] = [
      CommunityPost(
        id: 'post_churdhar_1',
        communityId: 'comm_churdhar',
        authorId: 'user_shiivang',
        authorName: 'Shiivang Manhass',
        authorRole: CommunityRole.leader,
        content:
            'Churdhar Expedition and Field Baseline ready! We have mapped all water sources and high-altitude medicinal herbs along the trail. All 49 members please carry fleece warmers and personal mesh radios. 🏔️🌾 #ChurdharTrek #FarmerExpedition #HighAltitudeAgro',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 18,
        isLikedByMe: true,
        commentsCount: 3,
        tags: ['#ChurdharTrek', '#FarmerExpedition', '#HighAltitudeAgro'],
        comments: [
          CommunityComment(
            id: 'c1',
            authorName: 'Ankit Rana',
            content: 'Ready with 10 powerbanks and mesh beacons.',
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          ),
          CommunityComment(
            id: 'c2',
            authorName: '~ preetikapanwar',
            content: 'Please collect wild juniper and seabuckthorn soil samples along the peak ridge for our ICAR research!',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      CommunityPost(
        id: 'post_churdhar_2',
        communityId: 'comm_churdhar',
        authorId: 'user_piyush',
        authorName: 'Piyush .. cR',
        authorRole: CommunityRole.admin,
        content:
            'Update on community logistics: We have arranged 2 transport vehicles from Solan bypass at 5:00 AM sharp. Shared fuel pool cost comes to ₹240 per member. Please confirm by reacting to this post! 🚜✅',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        likes: 12,
        isLikedByMe: false,
        commentsCount: 1,
        tags: ['#Logistics', '#CommunityTransport'],
        comments: [
          CommunityComment(
            id: 'c3',
            authorName: 'Bhandari .. Bhai',
            content: 'Vehicle 1 is already fueled and parked near Shamti.',
            timestamp: DateTime.now().subtract(const Duration(hours: 7)),
          ),
        ],
      ),
    ];

    _posts['comm_apple'] = [
      CommunityPost(
        id: 'post_apple_1',
        communityId: 'comm_apple',
        authorId: 'user_dr_verma',
        authorName: 'Dr. Ramesh Verma (ICAR)',
        authorRole: CommunityRole.admin,
        content:
            'Scientific protocol for Autumn Pruning: Do not prune until complete leaf fall has occurred and trees enter deep dormancy. Early cuts expose vascular cambium to frost injury and canker entry. Detailed protocol PDF attached in chat. 🍎🔬 #AppleCare #ICARAdvisory',
        timestamp: DateTime.now().subtract(const Duration(hours: 14)),
        likes: 24,
        isLikedByMe: true,
        commentsCount: 5,
        tags: ['#AppleCare', '#ICARAdvisory', '#Horticulture'],
      ),
    ];
  }
}
