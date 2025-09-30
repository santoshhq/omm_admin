// Facade file: re-exports new module/widget split for compatibility.
export 'admin_info/admin_info_module.dart';
export 'admin_info/admin_info_widget.dart';

// Backwards-compatible `AdminPage` widget preserved for imports that used it.
import 'package:flutter/material.dart';
import 'admin_info/admin_info_module.dart';
import 'admin_info/admin_info_widget.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPageWidget(info: adminInfo);
  }
}
