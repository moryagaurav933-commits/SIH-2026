import 'package:flutter/material.dart';
import '../../utils/design_tokens.dart';
import 'community_models.dart';

class CreatePollDialog extends StatefulWidget {
  final Function(String question, List<String> options, bool allowMultiple) onCreated;

  const CreatePollDialog({
    super.key,
    required this.onCreated,
  });

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(text: 'Will be there 🕯️'),
    TextEditingController(text: 'Sona hai 🛌'),
  ];
  bool _allowMultiple = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final c = _optionControllers.removeAt(index);
        c.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.poll_rounded, color: Color(0xFF15803D), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Create Community Poll',
                        style: TextStyle(
                          color: Color(0xFF1B381E),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question input
              const Text(
                'Poll Question',
                style: TextStyle(color: Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _questionController,
                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Best sowing time for Shivalik Wheat?',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF4F8F4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1E7D5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Options
              const Text(
                'Options',
                style: TextStyle(color: Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF4F8F4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFD1E7D5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: colorTerracotta, size: 20),
                          tooltip: 'Remove',
                          onPressed: () => _removeOption(index),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              if (_optionControllers.length < 6)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2E7D32), size: 18),
                  label: const Text(
                    'Add another option',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 10),
              const Divider(color: Color(0xFFE5E7EB)),

              // Multiple answers switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF2E7D32),
                activeTrackColor: const Color(0xFFA5D6A7),
                title: const Text(
                  'Allow multiple answers',
                  style: TextStyle(color: Color(0xFF1F2937), fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                value: _allowMultiple,
                onChanged: (val) => setState(() => _allowMultiple = val),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final q = _questionController.text.trim();
                    final opts = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                    if (q.isEmpty || opts.length < 2) return;

                    Navigator.pop(context);
                    widget.onCreated(q, opts, _allowMultiple);
                  },
                  child: const Text(
                    'Send Community Poll',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PollVotesSheet extends StatelessWidget {
  final CommunityPoll poll;

  const PollVotesSheet({
    super.key,
    required this.poll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.how_to_vote_rounded, color: Color(0xFF15803D), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Poll Votes Breakdown',
                    style: TextStyle(color: Color(0xFF1B381E), fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            poll.question,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE5E7EB)),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: poll.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final opt = poll.options[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5EBE6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              opt.text,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${opt.voteCount} vote${opt.voteCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (opt.voterNames.isEmpty)
                        const Text(
                          'No votes yet for this option',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontStyle: FontStyle.italic),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: opt.voterNames.map((name) {
                            return Chip(
                              backgroundColor: const Color(0xFFF0FDF4),
                              avatar: CircleAvatar(
                                backgroundColor: const Color(0xFF2E7D32),
                                radius: 10,
                                child: Text(
                                  name.trim()[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              label: Text(
                                name,
                                style: const TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              side: const BorderSide(color: Color(0xFFBBF7D0)),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
