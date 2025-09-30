import 'package:flutter/material.dart';

/// Data module for Admin info screen.
/// Keeps simple, reusable data structures and sample data used by the widget.

class AdminInfo {
  final String name;
  final String role;
  final String apartment;
  final String phone;
  final String address;
  final String version;

  const AdminInfo({
    required this.name,
    required this.role,
    required this.apartment,
    required this.phone,
    required this.address,
    required this.version,
  });
}

const adminInfo = AdminInfo(
  name: '',
  role: '',
  apartment: '',
  phone: '',
  address: '',
  version: 'Version 1.4.3',
);

class InfoItem {
  final IconData icon;
  final String title;
  final Color? color;

  const InfoItem(this.icon, this.title, {this.color});
}

const contactItems = [
  InfoItem(Icons.email_outlined, ''),
  InfoItem(Icons.apartment, ''),
  InfoItem(Icons.phone, ''),
  InfoItem(Icons.location_on, ''),
];

const supportItems = [
  InfoItem(Icons.help_outline, 'Help & Feedback'),
  InfoItem(Icons.info_outline, 'About Us'),
  InfoItem(Icons.logout, 'Logout', color: Colors.red),
];
