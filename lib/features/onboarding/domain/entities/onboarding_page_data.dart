import 'package:flutter/material.dart';

/// Static content for a single onboarding slide.
class OnboardingPageData {
  const OnboardingPageData({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;
}
