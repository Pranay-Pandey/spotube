import 'package:flutter/material.dart' show Badge;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:spotube/collections/assets.gen.dart';
import 'package:spotube/collections/side_bar_tiles.dart';
import 'package:spotube/collections/spotube_icons.dart';
import 'package:spotube/components/image/universal_image.dart';
import 'package:spotube/extensions/image.dart';
import 'package:spotube/models/database/database.dart';
import 'package:spotube/extensions/constrains.dart';
import 'package:spotube/extensions/context.dart';
import 'package:spotube/modules/connect/connect_device.dart';
import 'package:spotube/pages/library/user_downloads.dart';
import 'package:spotube/pages/profile/profile.dart';
import 'package:spotube/pages/settings/settings.dart';
import 'package:spotube/provider/authentication/authentication.dart';
import 'package:spotube/provider/download_manager_provider.dart';
import 'package:spotube/provider/spotify/spotify.dart';

import 'package:spotube/provider/user_preferences/user_preferences_provider.dart';

import 'package:spotube/utils/service_utils.dart';

class Sidebar extends HookConsumerWidget {
  final Widget child;

  const Sidebar({
    required this.child,
    super.key,
  });

  static Widget brandLogo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Assets.spotubeLogoPng.image(height: 50),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = GoRouterState.of(context);
    final mediaQuery = MediaQuery.of(context);

    final layoutMode =
        ref.watch(userPreferencesProvider.select((s) => s.layoutMode));

    final sidebarTileList = useMemoized(
      () => getSidebarTileList(context.l10n),
      [context.l10n],
    );

    final sidebarLibraryTileList = useMemoized(
      () => getSidebarLibraryTileList(context.l10n),
      [context.l10n],
    );

    final tileList = [...sidebarTileList, ...sidebarLibraryTileList];

    final selectedIndex = tileList.indexWhere(
      (e) => routerState.namedLocation(e.name) == routerState.matchedLocation,
    );

    if (layoutMode == LayoutMode.compact ||
        (mediaQuery.smAndDown && layoutMode == LayoutMode.adaptive)) {
      return Scaffold(child: child);
    }

    final navigationButtons = [
      NavigationLabel(
        child: mediaQuery.lgAndUp ? const Text("Spotube") : const Text(""),
      ),
      for (final tile in sidebarTileList)
        NavigationButton(
          label: mediaQuery.lgAndUp ? Text(tile.title) : null,
          child: Tooltip(
            tooltip: TooltipContainer(child: Text(tile.title)),
            child: Icon(tile.icon),
          ),
          onChanged: (value) {
            if (value) {
              context.goNamed(tile.name);
            }
          },
        ),
      const NavigationDivider(),
      if (mediaQuery.lgAndUp)
        NavigationLabel(child: Text(context.l10n.library)),
      for (final tile in sidebarLibraryTileList)
        NavigationButton(
          label: mediaQuery.lgAndUp ? Text(tile.title) : null,
          onChanged: (value) {
            if (value) {
              context.goNamed(tile.name);
            }
          },
          child: Tooltip(
            tooltip: TooltipContainer(child: Text(tile.title)),
            child: Icon(tile.icon),
          ),
        ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Expanded(
              child: mediaQuery.lgAndUp
                  ? NavigationSidebar(
                      index: selectedIndex,
                      onSelected: (index) {
                        final tile = tileList[index];
                        context.goNamed(tile.name);
                      },
                      children: navigationButtons,
                    )
                  : NavigationRail(
                      alignment: NavigationRailAlignment.start,
                      index: selectedIndex,
                      onSelected: (index) {
                        final tile = tileList[index];
                        context.goNamed(tile.name);
                      },
                      children: navigationButtons,
                    ),
            ),
            const SidebarFooter(),
            if (mediaQuery.lgAndUp) const Gap(130) else const Gap(65),
          ],
        ),
        const VerticalDivider(),
        Expanded(child: child),
      ],
    );
  }
}

class SidebarFooter extends HookConsumerWidget implements NavigationBarItem {
  const SidebarFooter({
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final routerState = GoRouterState.of(context);
    final downloadCount = ref.watch(downloadManagerProvider).$downloadCount;
    final userSnapshot = ref.watch(meProvider);
    final data = userSnapshot.asData?.value;

    final avatarImg = (data?.images).asUrlString(
      index: (data?.images?.length ?? 1) - 1,
      placeholder: ImagePlaceholder.artist,
    );

    final auth = ref.watch(authenticationProvider);

    if (mediaQuery.mdAndDown) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Badge(
            isLabelVisible: downloadCount > 0,
            label: Text(downloadCount.toString()),
            child: IconButton(
              variance: routerState.topRoute?.name == UserDownloadsPage.name
                  ? ButtonVariance.secondary
                  : ButtonVariance.ghost,
              icon: const Icon(SpotubeIcons.download),
              onPressed: () =>
                  ServiceUtils.navigateNamed(context, UserDownloadsPage.name),
            ),
          ),
          const ConnectDeviceButton.sidebar(),
          IconButton(
            variance: ButtonVariance.ghost,
            icon: const Icon(SpotubeIcons.settings),
            onPressed: () =>
                ServiceUtils.navigateNamed(context, SettingsPage.name),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 12),
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          SizedBox(
            width: double.infinity,
            child: Button(
              style: routerState.topRoute?.name == UserDownloadsPage.name
                  ? ButtonVariance.secondary
                  : ButtonVariance.outline,
              onPressed: () {
                ServiceUtils.navigateNamed(context, UserDownloadsPage.name);
              },
              leading: const Icon(SpotubeIcons.download),
              trailing: downloadCount > 0
                  ? PrimaryBadge(
                      child: Text(downloadCount.toString()),
                    )
                  : null,
              child: Text(context.l10n.downloads),
            ),
          ),
          const ConnectDeviceButton.sidebar(),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (auth.asData?.value != null && data == null)
                const CircularProgressIndicator()
              else if (data != null)
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      ServiceUtils.pushNamed(context, ProfilePage.name);
                    },
                    child: Row(
                      children: [
                        Avatar(
                          initials:
                              Avatar.getInitials(data.displayName ?? "User"),
                          provider: UniversalImage.imageProvider(avatarImg),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            data.displayName ?? context.l10n.guest,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: theme.typography.normal
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              IconButton(
                variance: ButtonVariance.ghost,
                icon: const Icon(SpotubeIcons.settings),
                onPressed: () {
                  ServiceUtils.pushNamed(context, SettingsPage.name);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get selectable => false;
}
