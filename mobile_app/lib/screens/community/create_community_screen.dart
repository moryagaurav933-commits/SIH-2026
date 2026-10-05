import 'package:flutter/material.dart';
import '../../localization/app_language.dart';
import '../../localization/app_translations.dart';
import '../../utils/design_tokens.dart';
import 'community_chat_screen.dart';
import 'community_models.dart';
import 'community_service.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  IconData _selectedIcon = Icons.groups_rounded;
  int _selectedColorValue = 0xFF2E7D32; // Forest Green
  String _selectedCategory = 'Horticulture';
  bool _isPublic = true;

  // Available icon choices
  final List<Map<String, dynamic>> _iconChoices = [
    {'icon': Icons.groups_rounded, 'label': 'Group'},
    {'icon': Icons.yard_rounded, 'label': 'Yard'},
    {'icon': Icons.grass_rounded, 'label': 'Field'},
    {'icon': Icons.terrain_rounded, 'label': 'Mountain'},
    {'icon': Icons.storefront_rounded, 'label': 'Mandi'},
    {'icon': Icons.science_rounded, 'label': 'KVK Science'},
    {'icon': Icons.water_drop_rounded, 'label': 'Water/Irrig'},
    {'icon': Icons.eco_rounded, 'label': 'Eco Nature'},
  ];

  // Available color choices
  final List<int> _colorChoices = [
    0xFF2E7D32, // Forest Green
    0xFF15803D, // Emerald
    0xFF0284C7, // Sky Blue
    0xFFD97706, // Amber Gold
    0xFFDC2626, // Terracotta Red
    0xFF7C3AED, // Violet
    0xFF0D9488, // Teal
  ];

  final List<String> _categories = [
    'Horticulture',
    'Field Crops',
    'Organic Farming',
    'Mandi & Trading',
    'KVK & Scientists',
    'Machinery & Rental',
    'General',
  ];

  // Candidate members to select from
  final List<Map<String, dynamic>> _candidateMembers = [
    {
      'id': 'user_piyush',
      'name': 'Piyush .. cR',
      'bio': 'Mandi trade & logistics',
      'phone': '+91 98160 55555',
      'role': CommunityRole.member,
      'selected': true,
    },
    {
      'id': 'user_preetika',
      'name': '~ preetikapanwar',
      'bio': 'Plant Pathologist & Soil Expert',
      'phone': '+91 6230 964 723',
      'role': CommunityRole.member,
      'selected': true,
    },
    {
      'id': 'user_ankit',
      'name': 'Ankit Rana',
      'bio': 'Seed & Fertilizer Collective',
      'phone': '+91 94180 12345',
      'role': CommunityRole.leader,
      'selected': true,
    },
    {
      'id': 'user_shiivang',
      'name': 'Shiivang Manhass',
      'bio': 'Mountain Agro Guide',
      'phone': '+91 95180 12365',
      'role': CommunityRole.member,
      'selected': false,
    },
    {
      'id': 'user_dr_verma',
      'name': 'Dr. Ramesh Verma',
      'bio': 'ICAR-IARI Senior Agronomist',
      'phone': '+91 98100 88888',
      'role': CommunityRole.leader,
      'selected': false,
    },
    {
      'id': 'user_mayank',
      'name': 'Mayank .... Bro ...',
      'bio': 'Field Scout & Mechanization',
      'phone': '+91 98160 77777',
      'role': CommunityRole.member,
      'selected': false,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _descController.dispose();
    super.dispose();
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

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showCustomSnackBar('Please enter community name', isError: true);
      return;
    }

    final bio = _bioController.text.trim().isEmpty ? 'Official farming circle for $name' : _bioController.text.trim();
    final desc = _descController.text.trim().isEmpty
        ? 'Welcome to $name. Share field observations, market insights, and crop protection updates.'
        : _descController.text.trim();

    final selectedMembers = _candidateMembers
        .where((m) => m['selected'] == true)
        .map((m) => CommunityMember(
              id: m['id'] as String,
              displayName: m['name'] as String,
              bio: m['bio'] as String?,
              phone: m['phone'] as String?,
              role: m['role'] as CommunityRole,
              joinedAt: DateTime.now(),
              avatarColorValue: _selectedColorValue,
            ))
        .toList();

    final newComm = await _service.createCommunity(
      name: name,
      bio: bio,
      description: desc,
      category: _selectedCategory,
      isPublic: _isPublic,
      iconCodePoint: _selectedIcon.codePoint,
      iconColorValue: _selectedColorValue,
      initialMembers: selectedMembers,
    );

    _showCustomSnackBar('Community "$name" created! You are the Admin.');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityChatScreen(communityId: newComm.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7), // Clean light theme
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B381E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.currentLanguage == AppLanguage.hi ? 'नया समुदाय बनाएं' : 'Create Community',
          style: const TextStyle(color: Color(0xFF1B381E), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Community Icon & Color Palette Card
          Container(
            padding: const EdgeInsets.all(18),
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
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(_selectedColorValue),
                  child: Icon(_selectedIcon, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose Icon & Color Palette',
                  style: TextStyle(color: Color(0xFF1B381E), fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Icon Picker
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _iconChoices.map((item) {
                      final iconData = item['icon'] as IconData;
                      final bool isSel = iconData == _selectedIcon;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => _selectedIcon = iconData),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? const Color(0xFF15803D) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(iconData, color: isSel ? const Color(0xFF15803D) : const Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Color Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _colorChoices.map((c) {
                    final bool isSel = c == _selectedColorValue;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedColorValue = c),
                        child: CircleAvatar(
                          radius: isSel ? 16 : 13,
                          backgroundColor: Color(c),
                          child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Community Details Card
          Container(
            padding: const EdgeInsets.all(18),
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
                const Text(
                  'Community Details',
                  style: TextStyle(color: Color(0xFF1B381E), fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // Name
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14.5),
                  decoration: InputDecoration(
                    labelText: 'Community Name *',
                    labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                    hintText: 'e.g. Kinnaur Apple Grower Circle',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAF9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // Bio
                TextField(
                  controller: _bioController,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Short Bio / Tagline',
                    labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                    hintText: 'e.g. High altitude orchards & pest alerts',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAF9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Description & Community Rules',
                    labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                    hintText: 'Describe purpose, crop varieties, guidelines...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAF9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 14),

                // Category dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Agricultural Category',
                    labelStyle: const TextStyle(color: Color(0xFF4B5563)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAF9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E7D5))),
                  ),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 10),

                // Privacy Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFF2E7D32),
                  activeTrackColor: const Color(0xFFA5D6A7),
                  title: const Text('Public Community', style: TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _isPublic ? 'Anyone can discover and join from Explore' : 'Invite-only or by admin approval',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  value: _isPublic,
                  onChanged: (val) => setState(() => _isPublic = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add Initial Members & Role Tagging Card
          Container(
            padding: const EdgeInsets.all(18),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Initial Members & Roles',
                      style: TextStyle(color: Color(0xFF1B381E), fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_candidateMembers.where((m) => m['selected'] == true).length} Selected',
                        style: const TextStyle(color: Color(0xFF15803D), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tag active farmers as Leaders or Members. You are automatically Admin.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                const SizedBox(height: 12),

                ...List.generate(_candidateMembers.length, (idx) {
                  final m = _candidateMembers[idx];
                  final bool isSel = m['selected'] as bool;
                  final role = m['role'] as CommunityRole;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFF7FAF7) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSel,
                          activeColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() {
                              _candidateMembers[idx]['selected'] = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['name'] as String,
                                style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                              if (m['bio'] != null)
                                Text(
                                  m['bio'] as String,
                                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11.5),
                                ),
                            ],
                          ),
                        ),
                        // Role Dropdown tag
                        if (isSel)
                          DropdownButton<CommunityRole>(
                            value: role,
                            dropdownColor: Colors.white,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF15803D), size: 18),
                            items: [
                              DropdownMenuItem(
                                value: CommunityRole.member,
                                child: Text('Member', style: TextStyle(color: CommunityRole.member.badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: CommunityRole.leader,
                                child: Text('Leader', style: TextStyle(color: CommunityRole.leader.badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            onChanged: (newRole) {
                              if (newRole != null) {
                                setState(() {
                                  _candidateMembers[idx]['role'] = newRole;
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.group_add_rounded, color: Colors.white),
              label: const Text(
                'Create Community',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _handleCreate,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
