import 'package:finance_app/features/analysis/screens/analysis_page.dart';
import 'package:finance_app/features/home/home_screen.dart';
import 'package:finance_app/features/profile/screens/profile_page.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({super.key});

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int currentIndex = 0;
  final PageController _controller = PageController();

  /// 🔥 Keys for refresh
  Key homeKey = UniqueKey();
  Key analysisKey = UniqueKey();
  Key profileKey = UniqueKey();

  final icons = [
    Icons.home_rounded,
    Icons.bar_chart_rounded,
    Icons.person_rounded,
  ];

  final labels = ["Home", "Analysis", "Profile"];

  void onTap(int index) {
    if (index == currentIndex) {
      // 🔥 Scroll to top (uses PrimaryScrollController)
      final scrollController = PrimaryScrollController.of(context);

      if (scrollController != null && scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }

      // 🔥 Force refresh
      setState(() {
        if (index == 0) homeKey = UniqueKey();
        if (index == 1) analysisKey = UniqueKey();
        if (index == 2) profileKey = UniqueKey();
      });

      return;
    }

    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      /// 🔥 Pages
      body: PageView(
        controller: _controller,
        onPageChanged: (i) {
          if (i != currentIndex) {
            setState(() => currentIndex = i);
          }
        },
        children: [
          HomeScreen(key: homeKey),
          AnalysisPage(key: analysisKey),
          ProfilePage(key: profileKey),
        ],
      ),

      /// 🔥 Bottom Bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              /// 🔥 Moving Indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + (currentIndex * 1.0), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / icons.length,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),

              /// 🔥 Icons
              Row(
                children: List.generate(icons.length, (index) {
                  final isSelected = currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
