import 'dart:async';

import 'package:cg_net_mobile/core/network/api_message_modal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/utils/loading_helper.dart';
import '../../../data/show_room/show_room_repository.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/show_room_model/show_room_model.dart';

class ShowRoomPage extends ConsumerStatefulWidget {
  const ShowRoomPage({super.key});

  @override
  ConsumerState<ShowRoomPage> createState() => _ShowRoomPageState();
}

class _ShowRoomPageState extends ConsumerState<ShowRoomPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadShowRooms());
    });
  }

  Future<void> _loadShowRooms({bool retry = false}) async {
    if (retry) ref.invalidate(showRoomsProvider);
    try {
      await LoadingHelper.runWithLoading(
        () => ref.read(showRoomsProvider.future),
      );
    } catch (error) {
      await showApiMessageModal(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(showRoomsProvider);
    final locale = context.locale.languageCode;

    return AppCurvedScaffold(
      title: Text('home.service_show_room'.tr()),
      showBack: true,
      body: SafeArea(
        top: false,
        child: roomsAsync.when( 
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('common.error'.tr()),
                TextButton(
                  onPressed: () => unawaited(_loadShowRooms(retry: true)),
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
          data: (rooms) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: rooms.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == rooms.length) {
                return const _SocialMediaCard();
              }
              return _ShowRoomCard(room: rooms[index], locale: locale);
            },
          ),
        ),
      )
    );
  }
}

class _ShowRoomCard extends StatelessWidget {
  const _ShowRoomCard({required this.room, required this.locale});

  final ShowRoom room;
  final String locale;

  static const _officeAsset = 'assets/images/services/office.png';
  static const _verifiedAsset = 'assets/images/services/verified.png';
  static const _phoneAsset = 'assets/images/services/phone.png';
  static const _wechatAsset = 'assets/images/services/wechat.png';
  static const _telegramAsset = 'assets/images/services/telegram.png';
  static const _viberAsset = 'assets/images/services/viber.png';

  Future<void> _open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openMap() {
    return _open(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${room.nameFor(locale)} ${room.addressFor(locale)}')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: false,
      bordered: false,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TitlePngChip(asset: _officeAsset),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  room.nameFor(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    height: AppTheme.lineHeightMyanmarSafe,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Image.asset(
                _verifiedAsset,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openMap,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    LucideIcons.map_pin,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.addressFor(locale),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final phone in room.phoneNumbers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _open('tel:$phone'),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Image.asset(
                      _phoneAsset,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      phone,
                      style: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: AppTheme.lineHeightMyanmarSafe,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              _ChatPng(
                asset: _wechatAsset,
                onTap: () => _open(room.socialLinks['wechat'] ?? 'weixin://'),
              ),
              const SizedBox(width: 10),
              _ChatPng(
                asset: _telegramAsset,
                onTap: () =>
                    _open(room.socialLinks['telegram'] ?? 'https://t.me/'),
              ),
              const SizedBox(width: 10),
              _ChatPng(
                asset: _viberAsset,
                onTap: () => _open(room.socialLinks['viber'] ?? 'viber://'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TitlePngChip extends StatelessWidget {
  const _TitlePngChip({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.primary,
          BlendMode.srcIn,
        ),
        child: Image.asset(
          asset,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _ChatPng extends StatelessWidget {
  const _ChatPng({
    required this.asset,
    required this.onTap,
  });

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Image.asset(
            asset,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _SocialMediaCard extends StatelessWidget {
  const _SocialMediaCard();

  static const _facebookAsset = 'assets/images/services/social_facebook.png';
  static const _youtubeAsset = 'assets/images/services/youtube.png';
  static const _tiktokAsset = 'assets/images/services/tiktok.png';
  static const _websiteAsset = 'assets/images/services/website.png';

  Future<void> _open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: false,
      bordered: false,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SocialMediaTile(
                asset: _facebookAsset,
                label: 'Facebook',
                onTap: () => _open('https://www.facebook.com/'),
              ),
              const SizedBox(width: 10),
              _SocialMediaTile(
                asset: _youtubeAsset,
                label: 'YouTube',
                onTap: () => _open('https://www.youtube.com/'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SocialMediaTile(
                asset: _tiktokAsset,
                label: 'TikTok',
                onTap: () => _open('https://www.tiktok.com/'),
              ),
              const SizedBox(width: 10),
              _SocialMediaTile(
                asset: _websiteAsset,
                label: 'home.social_website'.tr(),
                onTap: () => _open('https://www.google.com/search?q=Yaung+Ni+Oo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialMediaTile extends StatelessWidget {
  const _SocialMediaTile({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.primarySoft,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Image.asset(
                  asset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: AppTheme.lineHeightMyanmarSafe,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
