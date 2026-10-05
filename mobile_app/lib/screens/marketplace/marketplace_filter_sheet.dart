// -*- coding: utf-8 -*-
import 'package:flutter/material.dart';
import 'marketplace_model.dart';

class MarketplaceFilterSheet extends StatefulWidget {
  final FilterState initialFilter;
  final ValueChanged<FilterState>? onApply;

  const MarketplaceFilterSheet({
    super.key,
    required this.initialFilter,
    this.onApply,
  });

  @override
  State<MarketplaceFilterSheet> createState() => _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState extends State<MarketplaceFilterSheet> {
  late FilterState _filter;

  static const Color colorPrimary = Color(0xFF2E7D32);
  static const Color colorHairline = Color(0xFFE0E8E0);
  static const Color colorText = Color(0xFF1A1A1A);
  static const Color colorMuted = Color(0xFF6B8F6B);

  final List<String> availableBrands = [
    'Syngenta',
    'Bayer CropScience',
    'UPL Agro',
    'IFFCO Kisan',
    'FMC Agro',
    'Kraft Seeds',
    'Green India',
    'Rallis India',
    'Crystal Crop',
    'Multiplex Bio',
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header: Filters + Clear All + Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorText,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filter.reset();
                        });
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: colorHairline),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Categories
                _buildSectionHeader('CATEGORIES'),
                const SizedBox(height: 8),
                _buildCategoryList(),
                const SizedBox(height: 18),
                const Divider(height: 1, color: colorHairline),

                // 2. Price Range Slider & Histogram
                _buildSectionHeader('PRICE'),
                _buildPriceSection(),
                const SizedBox(height: 18),
                const Divider(height: 1, color: colorHairline),

                // 3. Krishi Assured Checkbox
                _buildAssuredCheckbox(),
                const SizedBox(height: 12),
                const Divider(height: 1, color: colorHairline),

                // 4. Brand Filter
                _buildBrandFilter(),
                const SizedBox(height: 12),
                const Divider(height: 1, color: colorHairline),

                // 5. Customer Ratings
                _buildCustomerRatings(),
                const SizedBox(height: 12),
                const Divider(height: 1, color: colorHairline),

                // 6. Offers
                _buildOffersSection(),
                const SizedBox(height: 12),
                const Divider(height: 1, color: colorHairline),

                // 7. Discount
                _buildDiscountSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Bar: Reset & Apply
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: colorHairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: colorHairline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _filter.reset();
                      });
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: colorText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (widget.onApply != null) {
                        widget.onApply!(_filter);
                      }
                      Navigator.pop(context, _filter);
                    },
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ProductCategory.values.map((cat) {
        final bool isSelected = _filter.category == cat;
        return InkWell(
          onTap: () {
            setState(() {
              _filter.category = cat;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? colorPrimary : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? colorPrimary : colorText,
                    ),
                  ),
                ),
                Text(
                  cat.hindiName,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? colorPrimary : colorMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Stylized bar histogram above slider (inspired by Image 2)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildHistBar(20),
            _buildHistBar(35),
            _buildHistBar(60),
            _buildHistBar(45),
            _buildHistBar(80),
            _buildHistBar(50),
            _buildHistBar(30),
            _buildHistBar(15),
          ],
        ),
        RangeSlider(
          values: RangeValues(_filter.minPrice, _filter.maxPrice),
          min: 50,
          max: 5000,
          divisions: 99,
          activeColor: const Color(0xFF2874F0),
          inactiveColor: Colors.grey.shade200,
          onChanged: (RangeValues values) {
            setState(() {
              _filter.minPrice = values.start.roundToDouble();
              _filter.maxPrice = values.end.roundToDouble();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colorHairline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Min: ₹${_filter.minPrice.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const Text('to', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colorHairline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Max: ₹${_filter.maxPrice.toInt()}+',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistBar(double height) {
    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }

  Widget _buildAssuredCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _filter.assuredOnly = !_filter.assuredOnly;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: _filter.assuredOnly,
              activeColor: const Color(0xFF0D47A1),
              onChanged: (v) {
                setState(() {
                  _filter.assuredOnly = v ?? false;
                });
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF1D4ED8), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Krishi Assured',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Icon(Icons.help_outline_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandFilter() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: true,
      title: const Text(
        'BRAND',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: 0.6,
        ),
      ),
      children: availableBrands.map((brand) {
        final bool isChecked = _filter.selectedBrands.contains(brand);
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: colorPrimary,
          title: Text(
            brand,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          value: isChecked,
          onChanged: (bool? val) {
            setState(() {
              if (val == true) {
                _filter.selectedBrands.add(brand);
              } else {
                _filter.selectedBrands.remove(brand);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCustomerRatings() {
    final ratings = [4.0, 3.0, 2.0, 1.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CUSTOMER RATINGS'),
        ...ratings.map((r) {
          final isSelected = _filter.minRating == r;
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: colorPrimary,
            title: Row(
              children: [
                Text(
                  '${r.toInt()}★ & above',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: index < r ? const Color(0xFF388E3C) : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            value: isSelected,
            onChanged: (bool? val) {
              setState(() {
                _filter.minRating = val == true ? r : 0.0;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildOffersSection() {
    final offers = ['Special Price', 'Buy More, Save More', 'Kisan DBT Subsidy'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OFFERS'),
        ...offers.map((offer) {
          final isChecked = _filter.selectedOffers.contains(offer);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: colorPrimary,
            title: Text(
              offer,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            value: isChecked,
            onChanged: (bool? val) {
              setState(() {
                if (val == true) {
                  _filter.selectedOffers.add(offer);
                } else {
                  _filter.selectedOffers.remove(offer);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildDiscountSection() {
    final discounts = [50, 40, 30, 20, 10];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DISCOUNT'),
        ...discounts.map((d) {
          final isSelected = _filter.minDiscount == d;
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: colorPrimary,
            title: Text(
              '$d% or more',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            value: isSelected,
            onChanged: (bool? val) {
              setState(() {
                _filter.minDiscount = val == true ? d : 0;
              });
            },
          );
        }),
      ],
    );
  }
}
