import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/HR_Admin/announcements_tab.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/HR_Admin/events_tab.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/HR_Admin/holidays_tab.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/chat_screen.dart';
import 'package:ecoteam_app/contractor/view/contractor_dashboard/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../models/site_model.dart';


class HrAdminPage extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final String? currentCompany;
  final int? workspaceId;
  final int userId;

  const HrAdminPage({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    this.currentCompany,
    this.workspaceId,
    required this.userId,
  });

  @override
  State<HrAdminPage> createState() => _HrAdminPageState();
}

class _HrAdminPageState extends State<HrAdminPage> {

  static const Color primaryColor = Color(0xFF4a63c0);
  static const Color primaryDark = Color(0xFF2a43a0);
  static const Color backgroundColor = Color(0xFFf8f9fa);

  String _getCurrentSiteName() {
    if (widget.selectedSiteId == null) {
      return 'All Sites';
    }
    final site = widget.sites.firstWhere(
      (site) => site.id == widget.selectedSiteId,
      orElse: () => Site(id: '', name: 'Unknown Site', companyId: ''),
    );
    return site.name;
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Tabs Logic
    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    // Events Tab based on permission
    final hasManageEvent = Provider.of<CompanySiteProvider>(context).hasPermission('event manage');
    if (hasManageEvent) {
        tabs.add(const Tab(text: 'Events'));
        tabViews.add(EventsTab(
          workspaceId: widget.workspaceId,
          selectedSiteId: widget.selectedSiteId,
          userId: widget.userId,
        ));
    }

    // Announcements Tab based on permission
    final hasManageAnnouncement = Provider.of<CompanySiteProvider>(context).hasPermission('announcement manage');
    if (hasManageAnnouncement) {
      tabs.add(const Tab(text: 'Announcements'));
      tabViews.add(AnnouncementsTab(
        workspaceId: widget.workspaceId,
        selectedSiteId: widget.selectedSiteId,
        userId: widget.userId,
      ));
    }
    
    tabs.add(const Tab(text: 'Holidays'));
    tabViews.add(HolidaysTab(
        workspaceId: widget.workspaceId,
        selectedSiteId: widget.selectedSiteId,
        userId: widget.userId,
    ));

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HR Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Site: ${_getCurrentSiteName()}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          toolbarHeight: 74.h,
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, const Color(0xFF3a53b0), primaryDark],
              ),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const FaIcon(FontAwesomeIcons.bell, size: 22, color: Colors.white),
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
            const SizedBox(width: 5),
            IconButton(
              tooltip: 'Chat',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      selectedSiteId: widget.selectedSiteId,
                      onSiteChanged: (String siteId) {},
                      sites: widget.sites,
                      currentCompany: widget.currentCompany,
                      workspaceId: widget.workspaceId,
                    ),
                  ),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const FaIcon(FontAwesomeIcons.commentDots, size: 22),
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
            const SizedBox(width: 10),
          ],
            bottom: PreferredSize(
            preferredSize: Size.fromHeight(45.h),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
              ),
              color: Colors.transparent,
              child: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                labelPadding: EdgeInsets.symmetric(horizontal: 7.w),
                tabs: tabs,
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: tabViews,
        ),
    ),
   );
  }
}
