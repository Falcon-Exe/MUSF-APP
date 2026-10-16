import 'package:flutter/material.dart';

import '../features/leadership/presentation/pages/admin_leadership_page.dart';

class ManageLeadershipPage extends StatelessWidget {
  final VoidCallback? onBack;

  const ManageLeadershipPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return HomeBackgroundAdminPage(onBack: onBack);
  }
}
