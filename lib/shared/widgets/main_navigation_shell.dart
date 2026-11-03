import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/app/theme/neumorphic_styles.dart';
import 'package:lembur/features/settings/presentation/settings_provider.dart';
import 'package:provider/provider.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    required this.currentIndex,
    required this.child,
    super.key,
  });

  final int currentIndex;
  final Widget child;

  static const _paths = ['/', '/history', '/documents', '/settings'];
  static const _items = [
    (Icons.home_rounded, 'Beranda'),
    (Icons.history_rounded, 'Riwayat'),
    (Icons.description_rounded, 'Dokumen'),
    (Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final needsSetup = !context.watch<SettingsProvider>().documentsReady;
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(24),
            boxShadow: NeumorphicStyles.raised(blur: 18, offset: 7),
            border: Border.all(color: Colors.white70),
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final selected = currentIndex == index;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => context.go(_paths[index]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? const Color(0xFFEAF2FF)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow:
                          selected
                              ? NeumorphicStyles.soft(blur: 8, offset: 3)
                              : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          isLabelVisible: index == 3 && needsSetup,
                          backgroundColor: AppColors.warning,
                          child: Icon(
                            _items[index].$1,
                            size: selected ? 25 : 22,
                            color:
                                selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[index].$2,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
