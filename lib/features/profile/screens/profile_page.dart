import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: ListView(
        key: const PageStorageKey("profile_scroll"),
        children: List.generate(
          15,
          (index) => ListTile(title: Text("Profile $index")),
        ),
      ),
    );
  }
}
