import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_logo/app_logo.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import 'about_app_controller.dart';

class AboutAppPage extends ConsumerWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(aboutAppControllerProvider);

    return AppCurvedScaffold(
      title: Text('profile.about_title'.tr()),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: AppLogo(
              width: 200,
              height: 125,
              padding: 8,
              borderRadius: 18,
              backgroundColor: Colors.transparent,
              showShadow: false,
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeading(title: 'profile.our_story'.tr()),
          AppCard(
            padding: const EdgeInsets.all(22),
            borderRadius: AppStyle.borderRadiusLg,
            child: Text(
              'profile.about_description'.tr(),
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeading(title: 'profile.what_we_hold_to'.tr()),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ValueCard(title: 'profile.value_trusted_network'.tr()),
              _ValueCard(title: 'profile.value_local_support'.tr()),
              _ValueCard(title: 'profile.value_innovative_technology'.tr()),
              _ValueCard(title: 'profile.value_community_first'.tr()),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeading(title: 'profile.how_yno_works'.tr()),
          const SizedBox(height: 4),
          Column(
            children: [
              _HowItWorksCard(
                number: '01',
                title: 'profile.how_yno_step_1'.tr(),
              ),
              _HowItWorksCard(
                number: '02',
                title: 'profile.how_yno_step_2'.tr(),
              ),
              _HowItWorksCard(
                number: '03',
                title: 'profile.how_yno_step_3'.tr(),
              ),
              _HowItWorksCard(
                number: '04',
                title: 'profile.how_yno_step_4'.tr(),
              ),
              _HowItWorksCard(
                number: '05',
                title: 'profile.how_yno_step_5'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'profile.icon_credits'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 6),

          Center(
            child: InkWell(
              onTap: () async {
                final uri = Uri.parse(
                  'https://www.flaticon.com/legal',
                );

                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Flaticon - Receipt icons',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      borderRadius: AppStyle.borderRadiusLg,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({
    required this.number,
    required this.title,
  });

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                borderRadius: AppStyle.borderRadiusLg,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
