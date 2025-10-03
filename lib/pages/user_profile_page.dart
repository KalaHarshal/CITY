import 'package:CiTY/models/report_model.dart';
import 'package:CiTY/models/user_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../locale_provider.dart';
import '../login_page.dart';
import 'package:CiTY/pages/profile_page.dart';
import 'home_page.dart';
import 'report_issue_page.dart';
import 'reports_page.dart';
import 'faq_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool notificationsEnabled = true;
  bool _isLoading = true;

  late Box<UserProfile> _userProfileBox;
  late Box<Report> _reportsBox;

  @override
  void initState() {
    super.initState();
    _userProfileBox = Hive.box<UserProfile>('userProfileBox');
    _reportsBox = Hive.box<Report>('reportsBox');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // If cache exists, load immediately. Otherwise, show loading.
    if (_userProfileBox.isNotEmpty) {
      setState(() => _isLoading = false);
    }
    // Always fetch fresh data from network in the background.
    await _fetchUserDataFromFirebase();
  }

  Future<void> _fetchUserDataFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.phoneNumber == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final phone = user.phoneNumber!;
    final userRef = FirebaseDatabase.instance.ref('users/$phone');

    try {
      final userSnapshot = await userRef.get();

      if (userSnapshot.exists && userSnapshot.value != null) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        final civicData = userData['civicProfile'] != null
            ? Map<String, dynamic>.from(userData['civicProfile'])
            : {'badge': 'Civic Newcomer', 'points': 0};

        final userProfile = UserProfile()
          ..fullName = userData['fullName'] ?? 'No Name'
          ..email = userData['email'] ?? 'No Email'
          ..phoneNumber = userData['phoneNumber'] ?? phone
          ..badge = civicData['badge'] ?? 'Civic Newcomer'
          ..points = civicData['points'] ?? 0;

        // Store the single user profile object using a known key, e.g., 'currentUser'
        await _userProfileBox.put('currentUser', userProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to refresh profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const mainBlue = Color(0xFF1746D1);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.profile,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Box<UserProfile>>(
              valueListenable: _userProfileBox.listenable(),
              builder: (context, profileBox, _) {
                final userProfile = profileBox.get('currentUser');

                if (userProfile == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Could not load user profile."),
                        SizedBox(height: 10.h),
                        ElevatedButton(
                          onPressed: _fetchUserDataFromFirebase,
                          child: Text("Try Again"),
                        ),
                      ],
                    ),
                  );
                }

                return ValueListenableBuilder<Box<Report>>(
                  valueListenable: _reportsBox.listenable(),
                  builder: (context, reportsBox, _) {
                    final reports = reportsBox.values.toList();
                    final totalReports = reports.length;
                    final resolvedReports = reports
                        .where((r) => r.status == 'Resolved')
                        .length;
                    final pendingReports = totalReports - resolvedReports;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _profileCard(loc, mainBlue, userProfile),
                          SizedBox(height: 18.h),
                          _badgeCard(loc, userProfile, resolvedReports),
                          SizedBox(height: 18.h),
                          _reportsSummary(
                            loc,
                            mainBlue,
                            totalReports,
                            resolvedReports,
                            pendingReports,
                          ),
                          SizedBox(height: 18.h),
                          _settingsCard(loc, mainBlue, localeProvider),
                          SizedBox(height: 18.h),
                          _supportCard(loc),
                          SizedBox(height: 18.h),
                          _logoutButton(loc),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8.r,
              offset: Offset(0, -2.h),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFFF0F4FF),
          currentIndex: 3,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportIssuePage(),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyReportsPage()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1746D1),
          unselectedItemColor: Colors.grey,
          iconSize: 24.sp,
          selectedFontSize: 14.sp,
          unselectedFontSize: 13.sp,
          elevation: 0,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: 3 == 0
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1746D1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.home,
                        color: const Color(0xFF1746D1),
                        size: 24.sp,
                      ),
                    )
                  : Icon(Icons.home, size: 24.sp),
              label: loc.home,
            ),
            BottomNavigationBarItem(
              icon: 3 == 1
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1746D1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: const Color(0xFF1746D1),
                        size: 24.sp,
                      ),
                    )
                  : Icon(Icons.add_circle_outline, size: 24.sp),
              label: loc.report,
            ),
            BottomNavigationBarItem(
              icon: 3 == 2
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1746D1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.list_alt,
                        color: const Color(0xFF1746D1),
                        size: 24.sp,
                      ),
                    )
                  : Icon(Icons.list_alt, size: 24.sp),
              label: loc.complaints,
            ),
            BottomNavigationBarItem(
              icon: 3 == 3
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1746D1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF1746D1),
                        size: 24.sp,
                      ),
                    )
                  : Icon(Icons.person, size: 24.sp),
              label: loc.profile,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _profileCard(
    AppLocalizations loc,
    Color mainBlue,
    UserProfile profile,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: mainBlue.withOpacity(0.1),
            child: Text(
              profile.fullName.isNotEmpty
                  ? profile.fullName[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: mainBlue,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          phoneNumber: profile.phoneNumber,
                          initialName: profile.fullName,
                          initialEmail: profile.email,
                        ),
                      ),
                    ).then((_) {
                      // Refresh data when returning from the edit page
                      _fetchUserDataFromFirebase();
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        profile.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.edit, color: mainBlue, size: 18.sp),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      profile.phoneNumber,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.verified, color: Colors.green, size: 16.sp),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.email, size: 16.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(profile.email, style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeCard(
    AppLocalizations loc,
    UserProfile profile,
    int resolvedCount,
  ) {
    int points = resolvedCount; // Use resolved complaints as points
    int nextLevelPoints = 15;
    String nextLevelName = "Neighborhood Guardian 🦸‍♂️";
    if (points >= 15) {
      nextLevelPoints = 30;
      nextLevelName = "City Champion 🏆";
    }
    double progress = points / nextLevelPoints;
    int reportsToNextLevel = (nextLevelPoints - points).clamp(0, 100);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB16CEA), Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 28.sp),
              SizedBox(width: 8.w),
              Text(
                profile.badge, // Dynamic badge name
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    points
                        .toString(), // <-- Use the local resolved complaints count
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                    ),
                  ),
                  Text(
                    loc.report,
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            loc.currentBadge,
            style: TextStyle(color: Colors.white70, fontSize: 13.sp),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                "Progress to $nextLevelName",
                style: TextStyle(color: Colors.white, fontSize: 13.sp),
              ),
              const Spacer(),
              Text(
                "$points/$nextLevelPoints",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 7.h,
          ),
          SizedBox(height: 8.h),
          Text(
            reportsToNextLevel == 0
                ? "You've reached the highest level!"
                : "$reportsToNextLevel more reports to reach next level!",
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _reportsSummary(
    AppLocalizations loc,
    Color mainBlue,
    int total,
    int resolved,
    int pending,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.w, bottom: 14.h),
            child: Text(
              loc.reportsSummary,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryIconBox(
                Icons.assignment,
                total.toString(),
                loc.total,
                Colors.blue.shade100,
                mainBlue,
              ),
              _summaryIconBox(
                Icons.check_circle,
                resolved.toString(),
                loc.resolved,
                Colors.green.shade100,
                Colors.green,
              ),
              _summaryIconBox(
                Icons.access_time,
                pending.toString(),
                loc.pending,
                Colors.yellow.shade100,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryIconBox(
    IconData icon,
    String value,
    String label,
    Color bg,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 26.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: iconColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _settingsCard(
    AppLocalizations loc,
    Color mainBlue,
    LocaleProvider localeProvider,
  ) {
    // START: CORRECTED LOGIC
    // This function correctly determines which language name to show.
    String getCurrentLanguageName() {
      switch (localeProvider.locale?.languageCode) {
        case 'hi':
          return loc.hindi;
        case 'sat':
          return loc.santhali;
        case 'te':
          return loc.telugu;
        case 'mr':
          return loc.marathi;
        case 'en':
        default:
          return loc.english;
      }
    }
    // END: CORRECTED LOGIC

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
            child: Text(
              loc.settings,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications,
              size: 22.sp,
              color: Colors.grey[700],
            ),
            title: Text(loc.notifications, style: TextStyle(fontSize: 15.sp)),
            trailing: Switch(
              value: notificationsEnabled,
              activeThumbColor: mainBlue,
              onChanged: (val) => setState(() => notificationsEnabled = val),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.language, size: 22.sp, color: Colors.grey[700]),
            title: Text(loc.select_language, style: TextStyle(fontSize: 15.sp)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getCurrentLanguageName(), // Using the corrected function here
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20.sp, color: Colors.grey),
              ],
            ),
            onTap: () => _showLanguageDialog(localeProvider),
          ),
        ],
      ),
    );
  }

  Widget _supportCard(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
            child: Text(
              loc.support,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.help_outline,
              size: 22.sp,
              color: Colors.grey[700],
            ),
            title: Text(loc.faq, style: TextStyle(fontSize: 15.sp)),
            trailing: Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: Colors.grey,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FaqPage()),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.headset_mic_outlined,
              size: 22.sp,
              color: Colors.grey[700],
            ),
            title: Text(loc.contactSupport, style: TextStyle(fontSize: 15.sp)),
            trailing: Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: Colors.grey,
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.logout, color: Colors.white, size: 20.sp),
        label: Text(
          loc.logout,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16.sp,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
          shadowColor: Colors.red.withOpacity(0.4),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  void _showLanguageDialog(LocaleProvider localeProvider) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.select_language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('हिन्दी'),
              onTap: () {
                localeProvider.setLocale(const Locale('hi'));
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('मराठी'),
              onTap: () {
                localeProvider.setLocale(const Locale('mr'));
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('తెలుగు'),
              onTap: () {
                localeProvider.setLocale(const Locale('te'));
                Navigator.of(context).pop();
              },
            ),
            // START: ADDED SANTALI OPTION
            ListTile(
              title: const Text('ᱥᱟᱱᱛᱟᱲᱤ'),
              onTap: () {
                localeProvider.setLocale(const Locale('sat'));
                Navigator.of(context).pop();
              },
            ),
            // END: ADDED SANTALI OPTION
          ],
        ),
      ),
    );
  }
}
