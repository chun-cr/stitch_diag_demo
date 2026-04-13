import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountryCodeOption {
  const CountryCodeOption({
    required this.name,
    required this.code,
    required this.flag,
    required this.searchTerms,
    this.preferred = false,
  });

  final String name;
  final String code;
  final String flag;
  final List<String> searchTerms;
  final bool preferred;
}

const List<CountryCodeOption> authCountryCodeOptions = [
  CountryCodeOption(
    name: '中国',
    code: '+86',
    flag: '🇨🇳',
    searchTerms: ['中国', 'china', 'cn', '+86'],
    preferred: true,
  ),
  CountryCodeOption(
    name: '英国',
    code: '+44',
    flag: '🇬🇧',
    searchTerms: ['英国', 'united kingdom', 'uk', 'britain', 'england', '+44'],
    preferred: true,
  ),
  CountryCodeOption(
    name: '西班牙',
    code: '+34',
    flag: '🇪🇸',
    searchTerms: ['西班牙', 'spain', 'es', '+34'],
  ),
  CountryCodeOption(
    name: '葡萄牙',
    code: '+351',
    flag: '🇵🇹',
    searchTerms: ['葡萄牙', 'portugal', 'pt', '+351'],
  ),
  CountryCodeOption(
    name: '法国',
    code: '+33',
    flag: '🇫🇷',
    searchTerms: ['法国', 'france', 'fr', '+33'],
  ),
  CountryCodeOption(
    name: '德国',
    code: '+49',
    flag: '🇩🇪',
    searchTerms: ['德国', 'germany', 'de', '+49'],
  ),
  CountryCodeOption(
    name: '日本',
    code: '+81',
    flag: '🇯🇵',
    searchTerms: ['日本', 'japan', 'jp', '+81'],
    preferred: true,
  ),
  CountryCodeOption(
    name: '韩国',
    code: '+82',
    flag: '🇰🇷',
    searchTerms: ['韩国', 'korea', 'kr', '+82'],
    preferred: true,
  ),
];

Future<CountryCodeOption?> showAuthCountryCodePicker(
  BuildContext context, {
  required List<CountryCodeOption> options,
  required String selectedCode,
}) {
  return showCupertinoModalPopup<CountryCodeOption>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.14),
    builder: (_) => AuthCountryCodePickerSheet(
      options: options,
      selectedCode: selectedCode,
    ),
  );
}

class CountryCodePickerTrigger extends StatefulWidget {
  const CountryCodePickerTrigger({
    super.key,
    required this.flag,
    required this.code,
    required this.onTap,
  });

  final String flag;
  final String code;
  final VoidCallback onTap;

  @override
  State<CountryCodePickerTrigger> createState() =>
      _CountryCodePickerTriggerState();
}

class _CountryCodePickerTriggerState extends State<CountryCodePickerTrigger> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.982 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _pressed ? 0.94 : 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: _pressed ? 0.72 : 0.48),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.05 : 0.03),
                blurRadius: _pressed ? 10 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                widget.code,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1810),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                turns: _pressed ? 0.5 : 0,
                child: Icon(
                  CupertinoIcons.chevron_down,
                  size: 12,
                  color: const Color(0xFFA09080).withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthCountryCodePickerSheet extends StatefulWidget {
  const AuthCountryCodePickerSheet({
    super.key,
    required this.options,
    required this.selectedCode,
  });

  final List<CountryCodeOption> options;
  final String selectedCode;

  @override
  State<AuthCountryCodePickerSheet> createState() =>
      _AuthCountryCodePickerSheetState();
}

class _AuthCountryCodePickerSheetState
    extends State<AuthCountryCodePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  double _lastHapticOffset = 0;
  double _dragOffset = 0;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(CountryCodeOption option) {
    if (_query.isEmpty) {
      return true;
    }
    final query = _query.toLowerCase();
    return option.searchTerms.any((term) => term.toLowerCase().contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options.where(_matches).toList(growable: false);
    final preferred = filtered
        .where((item) => item.preferred)
        .toList(growable: false);
    final grouped = _query.isEmpty
        ? filtered.where((item) => !item.preferred).toList(growable: false)
        : filtered;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = (screenHeight * 0.78).clamp(420.0, 640.0).toDouble();

    return Material(
      type: MaterialType.transparency,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            key: const ValueKey('country_code_picker_page'),
            height: sheetHeight,
            width: double.infinity,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFF9FBFD).withValues(alpha: 0.88),
                          const Color(0xFFF1F5F8).withValues(alpha: 0.74),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.56),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 30,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          _buildHandle(context),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                            child: Text(
                              _titleForLocale(context),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            child: CupertinoSearchTextField(
                              key: const ValueKey('country_code_picker_search'),
                              controller: _searchCtrl,
                              placeholder: _searchPlaceholderForLocale(context),
                              onChanged: (value) {
                                setState(() => _query = value.trim());
                              },
                            ),
                          ),
                          Expanded(
                            child:
                                NotificationListener<ScrollUpdateNotification>(
                                  onNotification: _handleScrollNotification,
                                  child: ListView(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    children: [
                                      if (_query.isEmpty &&
                                          preferred.isNotEmpty) ...[
                                        _SectionHeader(
                                          title: _preferredTitleForLocale(
                                            context,
                                          ),
                                        ),
                                        _SectionCard(
                                          children: [
                                            for (
                                              var i = 0;
                                              i < preferred.length;
                                              i++
                                            ) ...[
                                              _CountryCodeCell(
                                                option: preferred[i],
                                                selected:
                                                    preferred[i].code ==
                                                    widget.selectedCode,
                                                onTap: () =>
                                                    _select(preferred[i]),
                                              ),
                                              if (i != preferred.length - 1)
                                                const _CellDivider(),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                      ],
                                      if (grouped.isNotEmpty) ...[
                                        _SectionHeader(
                                          title: _allTitleForLocale(context),
                                        ),
                                        _SectionCard(
                                          children: [
                                            for (
                                              var i = 0;
                                              i < grouped.length;
                                              i++
                                            ) ...[
                                              _CountryCodeCell(
                                                option: grouped[i],
                                                selected:
                                                    grouped[i].code ==
                                                    widget.selectedCode,
                                                onTap: () =>
                                                    _select(grouped[i]),
                                              ),
                                              if (i != grouped.length - 1)
                                                const _CellDivider(),
                                            ],
                                          ],
                                        ),
                                      ],
                                      if (filtered.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 80,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _emptyStateForLocale(context),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: const Color(
                                                  0xFF3A3028,
                                                ).withValues(alpha: 0.55),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        if (details.delta.dy <= 0) {
          return;
        }
        setState(
          () => _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 72.0),
        );
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dragOffset > 28 || velocity > 480) {
          HapticFeedback.selectionClick();
          Navigator.of(context).maybePop();
          return;
        }
        setState(() => _dragOffset = 0);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
        child: Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF6C7480).withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollUpdateNotification notification) {
    final delta = notification.scrollDelta ?? 0;
    if (delta.abs() < 10) {
      return false;
    }
    final pixels = notification.metrics.pixels;
    if ((pixels - _lastHapticOffset).abs() >= 44) {
      _lastHapticOffset = pixels;
      HapticFeedback.selectionClick();
    }
    return false;
  }

  void _select(CountryCodeOption option) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(option);
  }

  String _titleForLocale(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Country or Region',
      'ja' => '国または地域',
      'ko' => '국가 또는 지역',
      _ => '选择国家或地区',
    };
  }

  String _searchPlaceholderForLocale(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Search by country or code',
      'ja' => '国名または区号で検索',
      'ko' => '국가명 또는 국가번호 검색',
      _ => '搜索国家或区号',
    };
  }

  String _preferredTitleForLocale(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Recommended',
      'ja' => '常用地域',
      'ko' => '자주 사용하는 지역',
      _ => '常用地区',
    };
  }

  String _allTitleForLocale(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'All Regions',
      'ja' => '全部の地域',
      'ko' => '전체 지역',
      _ => '全部地区',
    };
  }

  String _emptyStateForLocale(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'No matching country or region',
      'ja' => '一致する国または地域が見つかりません',
      'ko' => '일치하는 국가 또는 지역이 없습니다',
      _ => '没有匹配的国家或地区',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6C7480).withValues(alpha: 0.86),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.52),
          width: 0.8,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _CountryCodeCell extends StatelessWidget {
  const _CountryCodeCell({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CountryCodeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: ValueKey('country_code_picker_item_${option.code}'),
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      borderRadius: BorderRadius.circular(16),
      onPressed: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2D6A4F).withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(option.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              Text(
                option.code,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF2D6A4F)
                      : const Color(0xFF6C7480),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 18,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? const Icon(
                          CupertinoIcons.check_mark,
                          key: ValueKey('selected_country_code_check'),
                          size: 18,
                          color: Color(0xFF2D6A4F),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: Colors.black.withValues(alpha: 0.06),
      ),
    );
  }
}
