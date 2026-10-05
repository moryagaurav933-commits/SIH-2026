import 'package:flutter/material.dart';

enum CommunityRole {
  admin,
  leader,
  member,
}

extension CommunityRoleExtension on CommunityRole {
  String get label {
    switch (this) {
      case CommunityRole.admin:
        return 'Admin';
      case CommunityRole.leader:
        return 'Leader';
      case CommunityRole.member:
        return 'Member';
    }
  }

  Color get badgeColor {
    switch (this) {
      case CommunityRole.admin:
        return const Color(0xFF10B981); // Emerald Green
      case CommunityRole.leader:
        return const Color(0xFF0284C7); // Sky Blue
      case CommunityRole.member:
        return const Color(0xFF64748B); // Slate
    }
  }
}

enum MessageType {
  text,
  image,
  audio,
  file,
  poll,
  system,
}

class CommunityMember {
  final String id;
  final String displayName;
  final String? phone;
  final String? bio;
  final String? customTag;
  final CommunityRole role;
  final DateTime joinedAt;
  final bool isCurrentUser;
  final int avatarColorValue;
  final String? avatarUrl;

  const CommunityMember({
    required this.id,
    required this.displayName,
    this.phone,
    this.bio,
    this.customTag,
    required this.role,
    required this.joinedAt,
    this.isCurrentUser = false,
    this.avatarColorValue = 0xFF2E7D32,
    this.avatarUrl,
  });

  CommunityMember copyWith({
    String? displayName,
    String? phone,
    String? bio,
    String? customTag,
    CommunityRole? role,
    bool? isCurrentUser,
    int? avatarColorValue,
    String? avatarUrl,
  }) {
    return CommunityMember(
      id: id,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      customTag: customTag ?? this.customTag,
      role: role ?? this.role,
      joinedAt: joinedAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'phone': phone,
        'bio': bio,
        'customTag': customTag,
        'role': role.index,
        'joinedAt': joinedAt.toIso8601String(),
        'isCurrentUser': isCurrentUser,
        'avatarColorValue': avatarColorValue,
        'avatarUrl': avatarUrl,
      };

  factory CommunityMember.fromJson(Map<String, dynamic> json) => CommunityMember(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        phone: json['phone'] as String?,
        bio: json['bio'] as String?,
        customTag: json['customTag'] as String?,
        role: CommunityRole.values[(json['role'] as int?) ?? 2],
        joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
        avatarColorValue: json['avatarColorValue'] as int? ?? 0xFF2E7D32,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class CommunityPollOption {
  final String id;
  final String text;
  final List<String> voterUserIds;
  final List<String> voterNames;

  const CommunityPollOption({
    required this.id,
    required this.text,
    this.voterUserIds = const [],
    this.voterNames = const [],
  });

  int get voteCount => voterUserIds.length;

  CommunityPollOption copyWith({
    List<String>? voterUserIds,
    List<String>? voterNames,
  }) {
    return CommunityPollOption(
      id: id,
      text: text,
      voterUserIds: voterUserIds ?? this.voterUserIds,
      voterNames: voterNames ?? this.voterNames,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'voterUserIds': voterUserIds,
        'voterNames': voterNames,
      };

  factory CommunityPollOption.fromJson(Map<String, dynamic> json) => CommunityPollOption(
        id: json['id'] as String,
        text: json['text'] as String,
        voterUserIds: List<String>.from(json['voterUserIds'] ?? []),
        voterNames: List<String>.from(json['voterNames'] ?? []),
      );
}

class CommunityPoll {
  final String id;
  final String question;
  final List<CommunityPollOption> options;
  final bool allowMultipleAnswers;
  final bool isClosed;
  final DateTime createdAt;
  final String creatorId;
  final String creatorName;

  const CommunityPoll({
    required this.id,
    required this.question,
    required this.options,
    this.allowMultipleAnswers = false,
    this.isClosed = false,
    required this.createdAt,
    required this.creatorId,
    required this.creatorName,
  });

  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.voteCount);

  bool hasUserVoted(String userId) {
    return options.any((opt) => opt.voterUserIds.contains(userId));
  }

  CommunityPoll copyWith({
    List<CommunityPollOption>? options,
    bool? isClosed,
  }) {
    return CommunityPoll(
      id: id,
      question: question,
      options: options ?? this.options,
      allowMultipleAnswers: allowMultipleAnswers,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt,
      creatorId: creatorId,
      creatorName: creatorName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'allowMultipleAnswers': allowMultipleAnswers,
        'isClosed': isClosed,
        'createdAt': createdAt.toIso8601String(),
        'creatorId': creatorId,
        'creatorName': creatorName,
      };

  factory CommunityPoll.fromJson(Map<String, dynamic> json) => CommunityPoll(
        id: json['id'] as String,
        question: json['question'] as String,
        options: (json['options'] as List? ?? [])
            .map((o) => CommunityPollOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        allowMultipleAnswers: json['allowMultipleAnswers'] as bool? ?? false,
        isClosed: json['isClosed'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        creatorId: json['creatorId'] as String? ?? '',
        creatorName: json['creatorName'] as String? ?? '',
      );
}

class MessageReaction {
  final String emoji;
  final List<String> userIds;

  const MessageReaction({
    required this.emoji,
    required this.userIds,
  });

  int get count => userIds.length;

  MessageReaction copyWith({List<String>? userIds}) {
    return MessageReaction(
      emoji: emoji,
      userIds: userIds ?? this.userIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'userIds': userIds,
      };

  factory MessageReaction.fromJson(Map<String, dynamic> json) => MessageReaction(
        emoji: json['emoji'] as String,
        userIds: List<String>.from(json['userIds'] ?? []),
      );
}

class CommunityMessage {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final String? senderPhone;
  final CommunityRole senderRole;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final int? audioDurationSeconds;
  final CommunityPoll? poll;
  final bool isPinned;
  final bool isEdited;
  final List<MessageReaction> reactions;
  final int senderColorValue;

  const CommunityMessage({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    this.senderPhone,
    this.senderRole = CommunityRole.member,
    required this.content,
    required this.type,
    required this.timestamp,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.audioDurationSeconds,
    this.poll,
    this.isPinned = false,
    this.isEdited = false,
    this.reactions = const [],
    this.senderColorValue = 0xFF10B981,
  });

  CommunityMessage copyWith({
    String? content,
    CommunityPoll? poll,
    bool? isPinned,
    bool? isEdited,
    List<MessageReaction>? reactions,
  }) {
    return CommunityMessage(
      id: id,
      communityId: communityId,
      senderId: senderId,
      senderName: senderName,
      senderPhone: senderPhone,
      senderRole: senderRole,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      audioDurationSeconds: audioDurationSeconds,
      poll: poll ?? this.poll,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      reactions: reactions ?? this.reactions,
      senderColorValue: senderColorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'communityId': communityId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhone': senderPhone,
        'senderRole': senderRole.index,
        'content': content,
        'type': type.index,
        'timestamp': timestamp.toIso8601String(),
        'mediaUrl': mediaUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'audioDurationSeconds': audioDurationSeconds,
        'poll': poll?.toJson(),
        'isPinned': isPinned,
        'isEdited': isEdited,
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'senderColorValue': senderColorValue,
      };

  factory CommunityMessage.fromJson(Map<String, dynamic> json) => CommunityMessage(
        id: json['id'] as String,
        communityId: json['communityId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        senderPhone: json['senderPhone'] as String?,
        senderRole: CommunityRole.values[(json['senderRole'] as int?) ?? 2],
        content: json['content'] as String,
        type: MessageType.values[(json['type'] as int?) ?? 0],
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        mediaUrl: json['mediaUrl'] as String?,
        fileName: json['fileName'] as String?,
        fileSize: json['fileSize'] as String?,
        audioDurationSeconds: json['audioDurationSeconds'] as int?,
        poll: json['poll'] != null ? CommunityPoll.fromJson(json['poll'] as Map<String, dynamic>) : null,
        isPinned: json['isPinned'] as bool? ?? false,
        isEdited: json['isEdited'] as bool? ?? false,
        reactions: (json['reactions'] as List? ?? [])
            .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
            .toList(),
        senderColorValue: json['senderColorValue'] as int? ?? 0xFF10B981,
      );
}

class CommunityComment {
  final String id;
  final String authorName;
  final String content;
  final DateTime timestamp;

  const CommunityComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CommunityComment.fromJson(Map<String, dynamic> json) => CommunityComment(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        content: json['content'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final CommunityRole authorRole;
  final String content;
  final List<String> images;
  final DateTime timestamp;
  final int likes;
  final bool isLikedByMe;
  final int commentsCount;
  final List<CommunityComment> comments;
  final List<String> tags;

  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    this.authorRole = CommunityRole.member,
    required this.content,
    this.images = const [],
    required this.timestamp,
    this.likes = 0,
    this.isLikedByMe = false,
    this.commentsCount = 0,
    this.comments = const [],
    this.tags = const [],
  });

  CommunityPost copyWith({
    int? likes,
    bool? isLikedByMe,
    int? commentsCount,
    List<CommunityComment>? comments,
  }) {
    return CommunityPost(
      id: id,
      communityId: communityId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      content: content,
      images: images,
      timestamp: timestamp,
      likes: likes ?? this.likes,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'communityId': communityId,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole.index,
        'content': content,
        'images': images,
        'timestamp': timestamp.toIso8601String(),
        'likes': likes,
        'isLikedByMe': isLikedByMe,
        'commentsCount': commentsCount,
        'comments': comments.map((c) => c.toJson()).toList(),
        'tags': tags,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        communityId: json['communityId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        authorRole: CommunityRole.values[(json['authorRole'] as int?) ?? 2],
        content: json['content'] as String,
        images: List<String>.from(json['images'] ?? []),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        likes: json['likes'] as int? ?? 0,
        isLikedByMe: json['isLikedByMe'] as bool? ?? false,
        commentsCount: json['commentsCount'] as int? ?? 0,
        comments: (json['comments'] as List? ?? [])
            .map((c) => CommunityComment.fromJson(c as Map<String, dynamic>))
            .toList(),
        tags: List<String>.from(json['tags'] ?? []),
      );
}

class Community {
  final String id;
  final String name;
  final String bio;
  final String description;
  final int iconCodePoint;
  final int iconColorValue;
  final String category;
  final String createdBy;
  final DateTime createdAt;
  final bool isPublic;
  final bool isJoined;
  final List<CommunityMember> members;
  final String? pinnedMessageSnippet;
  final String? pinnedMessageId;
  final String? lastMessageSnippet;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String inviteCode;

  const Community({
    required this.id,
    required this.name,
    required this.bio,
    required this.description,
    this.iconCodePoint = 0xe318, // Icons.groups_rounded
    this.iconColorValue = 0xFF2E7D32,
    this.category = 'General',
    required this.createdBy,
    required this.createdAt,
    this.isPublic = true,
    this.isJoined = true,
    required this.members,
    this.pinnedMessageSnippet,
    this.pinnedMessageId,
    this.lastMessageSnippet,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.inviteCode,
  });

  int get memberCount => members.length;

  IconData get iconData {
    switch (iconCodePoint) {
      case 0xe000:
        return Icons.yard_rounded;
      case 0xe25a:
        return Icons.grass_rounded;
      case 0xe644:
        return Icons.terrain_rounded;
      case 0xe8cc:
        return Icons.storefront_rounded;
      case 0xe585:
        return Icons.science_rounded;
      case 0xe2e6:
        return Icons.water_drop_rounded;
      case 0xe3ae:
        return Icons.eco_rounded;
      case 0xe318:
      default:
        return Icons.groups_rounded;
    }
  }

  bool isUserAdmin(String userId) {
    return members.any((m) => m.id == userId && m.role == CommunityRole.admin);
  }

  bool isUserLeaderOrAdmin(String userId) {
    return members.any((m) => m.id == userId && (m.role == CommunityRole.admin || m.role == CommunityRole.leader));
  }

  Community copyWith({
    String? name,
    String? bio,
    String? description,
    int? iconCodePoint,
    int? iconColorValue,
    String? category,
    bool? isPublic,
    bool? isJoined,
    List<CommunityMember>? members,
    String? pinnedMessageSnippet,
    String? pinnedMessageId,
    String? lastMessageSnippet,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Community(
      id: id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconColorValue: iconColorValue ?? this.iconColorValue,
      category: category ?? this.category,
      createdBy: createdBy,
      createdAt: createdAt,
      isPublic: isPublic ?? this.isPublic,
      isJoined: isJoined ?? this.isJoined,
      members: members ?? this.members,
      pinnedMessageSnippet: pinnedMessageSnippet ?? this.pinnedMessageSnippet,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
      lastMessageSnippet: lastMessageSnippet ?? this.lastMessageSnippet,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      inviteCode: inviteCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bio': bio,
        'description': description,
        'iconCodePoint': iconCodePoint,
        'iconColorValue': iconColorValue,
        'category': category,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'isPublic': isPublic,
        'isJoined': isJoined,
        'members': members.map((m) => m.toJson()).toList(),
        'pinnedMessageSnippet': pinnedMessageSnippet,
        'pinnedMessageId': pinnedMessageId,
        'lastMessageSnippet': lastMessageSnippet,
        'lastMessageTime': lastMessageTime?.toIso8601String(),
        'unreadCount': unreadCount,
        'inviteCode': inviteCode,
      };

  factory Community.fromJson(Map<String, dynamic> json) => Community(
        id: json['id'] as String,
        name: json['name'] as String,
        bio: json['bio'] as String,
        description: json['description'] as String,
        iconCodePoint: json['iconCodePoint'] as int? ?? 0xe318,
        iconColorValue: json['iconColorValue'] as int? ?? 0xFF2E7D32,
        category: json['category'] as String? ?? 'General',
        createdBy: json['createdBy'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isPublic: json['isPublic'] as bool? ?? true,
        isJoined: json['isJoined'] as bool? ?? true,
        members: (json['members'] as List? ?? [])
            .map((m) => CommunityMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        pinnedMessageSnippet: json['pinnedMessageSnippet'] as String?,
        pinnedMessageId: json['pinnedMessageId'] as String?,
        lastMessageSnippet: json['lastMessageSnippet'] as String?,
        lastMessageTime: json['lastMessageTime'] != null
            ? DateTime.tryParse(json['lastMessageTime'] as String)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
        inviteCode: json['inviteCode'] as String? ?? '',
      );
}
