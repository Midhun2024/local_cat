import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_router.dart';
import '../../controllers/auth_controller.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/app_section_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Confirm Logout',
      message: 'Are you sure you want to end your session?',
      confirmText: 'Logout',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('No authenticated user session.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Card
                  Card(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name.isNotEmpty
                                      ? user.name
                                      : 'Unknown User',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${user.username} (ID: ${user.id})',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contact Information
                  AppSectionCard(
                    title: 'Contact Information',
                    leadingIcon: Icons.contact_mail_outlined,
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email.isNotEmpty ? user.email : 'N/A',
                        ),
                        const Divider(height: 20),
                        _ProfileInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: user.phone.isNotEmpty ? user.phone : 'N/A',
                        ),
                        const Divider(height: 20),
                        _ProfileInfoRow(
                          icon: Icons.language_outlined,
                          label: 'Website',
                          value: user.website.isNotEmpty ? user.website : 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Company Information
                  AppSectionCard(
                    title: 'Company Information',
                    leadingIcon: Icons.business_outlined,
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          icon: Icons.apartment_outlined,
                          label: 'Company Name',
                          value: user.companyName.isNotEmpty
                              ? user.companyName
                              : 'N/A',
                        ),
                        if (user.company.catchPhrase.isNotEmpty) ...[
                          const Divider(height: 20),
                          _ProfileInfoRow(
                            icon: Icons.format_quote_outlined,
                            label: 'Catchphrase',
                            value: user.company.catchPhrase,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Continue to Categories Button
                  AppButton(
                    text: 'Manage Categories',
                    icon: Icons.account_tree_outlined,
                    onPressed: () => context.push(AppRouter.categoriesRoute),
                  ),
                  const SizedBox(height: 12),

                  // Logout Button
                  AppButton(
                    text: 'Sign Out',
                    isOutlined: true,
                    icon: Icons.logout,
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
