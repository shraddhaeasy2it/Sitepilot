import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';

List<Widget> buildNotificationActions({
  required BuildContext context,
  required String? selectedSiteId,
  required List<Site> sites,
  required String? currentCompany,
  required int? workspaceId,
}) {
  return [
    // Notification Icon
    GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationScreen()),
        );
        // Refresh count on return
        if (context.mounted) {
           Provider.of<CompanySiteProvider>(context, listen: false).fetchUnreadNotificationCount();
        }
      },
      child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: FaIcon(FontAwesomeIcons.bell, size: 22, color: Colors.white),
            ),
            Consumer<CompanySiteProvider>(
              builder: (context, provider, child) {
                if (provider.unreadNotificationCount > 0) {
                  return Positioned(
                    right: -5,
                    top: -12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Center(
                        child: Text(
                          provider.unreadNotificationCount > 99
                              ? '99+'
                              : '${provider.unreadNotificationCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
    ),
    const SizedBox(width: 1),
    // Chat Icon
    IconButton(
      tooltip: 'Chat',
      onPressed: () async {
        final provider = Provider.of<CompanySiteProvider>(context, listen: false);
        final effectiveWorkspaceId =
          int.tryParse(provider.selectedCompanyId ?? '') ?? workspaceId ?? 1;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              selectedSiteId: selectedSiteId,
              onSiteChanged: (String siteId) {
                debugPrint('Site changed to: $siteId');
              },
              sites: sites,
              currentCompany: currentCompany,
              workspaceId: effectiveWorkspaceId,
            ),
          ),
        );
        
        // Refresh chat count on return
        if (context.mounted) {
           provider.fetchUnreadChatCount();
        }
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const FaIcon(
            FontAwesomeIcons.commentDots,
            size: 22,
          ),
          Consumer<CompanySiteProvider>(
            builder: (context, provider, child) {
              if (provider.unreadChatCount > 0) {
                return Positioned(
                  right: -5,
                  top: -12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    child: Center(
                      child: Text(
                        provider.unreadChatCount > 99
                            ? '99+'
                            : '${provider.unreadChatCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      color: Colors.white,
    ),
  ];
}
