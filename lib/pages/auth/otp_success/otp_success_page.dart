import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';

/// Kept for route compatibility — success UX now lives as a bottom drawer
/// on [OtpVerificationPage]. Registration can continue only with the
/// verification token returned by OTP verification.
class OtpSuccessPage extends StatefulWidget {
  const OtpSuccessPage({
    super.key,
    required this.phone,
    required this.verificationToken,
  });

  final String phone;
  final String verificationToken;

  @override
  State<OtpSuccessPage> createState() => _OtpSuccessPageState();
}

class _OtpSuccessPageState extends State<OtpSuccessPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.verificationToken.isEmpty) {
        context.goNamed(RouteNames.login);
        return;
      }

      context.goNamed(
        RouteNames.setUsernamePassword,
        queryParameters: {
          'phone': widget.phone,
          'verification_token': widget.verificationToken,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.onPrimary),
      ),
    );
  }
}
