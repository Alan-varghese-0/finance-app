import 'package:flutter/material.dart';
import 'package:finance_app/features/analysis/screens/analysis_page.dart';
import 'package:finance_app/features/home/home_screen.dart';
import 'package:finance_app/features/profile/screens/profile_page.dart';
import 'package:finance_app/theme/theme.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({super.key});

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int currentIndex = 0;
  final controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: PageView(
        controller: controller,
        onPageChanged: (i) => setState(() => currentIndex = i),
        children: const [HomeScreen(), AnalysisPage(), ProfilePage()],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (i) {
          setState(() => currentIndex = i);
          controller.jumpToPage(i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Analysis",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
