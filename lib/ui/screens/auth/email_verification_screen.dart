import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _sendingEmail = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    // Send verification email on load if not already sent recently?
    // Actually, usually sent by previous screen. We'll assume it was sent.
  }

  Future<void> _checkVerification() async {
    setState(() => _verifying = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); // Force refresh from server
        if (user.emailVerified) {
          if (mounted) {
            context.go('/mode-selection');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Email not verified yet. Please check your inbox.'),
                backgroundColor: VxColors.warning,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: $e'),
            backgroundColor: VxColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _sendingEmail = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent!'),
              backgroundColor: VxColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error processing request: $e'), // Could be rate limited
            backgroundColor: VxColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingEmail = false);
      }
    }
  }

  void _bypassVerification() {
    // Debug only
    if (kDebugMode) {
      context.go('/mode-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: VxColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: VxColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 80,
                  color: VxColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Verify your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'We have sent a verification link to:\n$email',
                style: const TextStyle(
                  fontSize: 16,
                  color: VxColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                'Please click the link in your email to continue.',
                style: TextStyle(
                  fontSize: 14,
                  color: VxColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.primary,
                    foregroundColor: VxColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: VxColors.deepBlack,
                          ),
                        )
                      : const Text(
                          "I've Verified It",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Resend Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _sendingEmail ? null : _resendEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: VxColors.textSecondary,
                  ),
                  child: _sendingEmail
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend Email'),
                ),
              ),

              const SizedBox(height: 32),

              // Back to Login / Use Different Email
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Use Different Email / Sign In'),
              ),

              // Debug Bypass
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: OutlinedButton(
                    onPressed: _bypassVerification,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VxColors.danger,
                      side: const BorderSide(color: VxColors.danger),
                    ),
                    child: const Text('DEBUG: BYPASS VERIFICATION'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
