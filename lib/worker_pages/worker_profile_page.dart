import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../login_page.dart';
import '../l10n/app_localizations.dart';
import '../locale_provider.dart';
import 'worker_workCompletion_page.dart'; // Add this import at the top

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _workerData = {};
  String _workerId = "";

  // Task stats
  int _tasksCompleted = 0;
  List<String> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _workerId = prefs.getString('workerId') ?? "";

      if (_workerId.isEmpty) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
        return;
      }

      // Fetch worker data from Firebase
      final dbRef = FirebaseDatabase.instance.ref();
      final workerSnapshot = await dbRef
          .child('workers')
          .child(_workerId)
          .get();

      if (!workerSnapshot.exists) {
        if (!mounted) return;
        _handleLogout();
        return;
      }

      final data = Map<String, dynamic>.from(
        workerSnapshot.value as Map<dynamic, dynamic>,
      );

      // Fetch completed tasks count and badges (unchanged)
      final tasksQuery = await dbRef
          .child('complaints')
          .orderByChild('assignedTo')
          .equalTo(_workerId)
          .get();

      int completedCount = 0;
      List<String> earnedBadges = [];

      if (tasksQuery.exists) {
        final tasksData = Map<dynamic, dynamic>.from(
          tasksQuery.value as Map<dynamic, dynamic>,
        );

        for (var task in tasksData.values) {
          if (task['status'] == 'Resolved') {
            completedCount++;
          }
        }

        if (completedCount >= 5) earnedBadges.add('quickResponse');
        if (completedCount >= 10) earnedBadges.add('qualityWork');
        if (completedCount >= 15) earnedBadges.add('onTime');
      }

      if (!mounted) return;
      setState(() {
        _workerData = data;
        _tasksCompleted = completedCount;
        _badges = earnedBadges;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_workerId.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      // Verify current password
      if (_workerData['password'] != currentPassword) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.currentPasswordIncorrect,
            ),
          ),
        );
        return;
      }

      // Update password in Firebase
      await FirebaseDatabase.instance
          .ref()
          .child('workers')
          .child(_workerId)
          .update({'password': newPassword});

      // Update local data
      setState(() {
        _workerData['password'] = newPassword;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordUpdateSuccess),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating password: $e')));
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePassword),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.currentPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              // Validate passwords
              if (newPasswordController.text.isEmpty ||
                  newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.passwordTooShort)));
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.passwordsDoNotMatch)),
                );
                return;
              }

              Navigator.pop(context);
              _changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );
            },
            child: Text(l10n.update),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('workerId');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          title: Text(
            l10n.profile,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.orange.shade700,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkerData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Profile Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 24.h,
                    horizontal: 16.w,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50.r,
                            backgroundColor: Colors.orange.shade700,
                            child: Icon(
                              Icons.person,
                              size: 60.sp,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(4.w),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _workerData['name'] ?? l10n.worker,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "${l10n.workerId}: $_workerId",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _infoTile(
                        Icons.phone,
                        l10n.phoneNumber,
                        _workerData['phone'] ?? l10n.notAvailable,
                      ),
                      SizedBox(height: 10.h),
                      _infoTile(
                        Icons.engineering,
                        l10n.department,
                        _workerData['department'] ?? l10n.notAvailable,
                      ),
                      SizedBox(height: 10.h),
                      _infoTile(
                        Icons.location_on,
                        "Pincode", // Localize if needed
                        _workerData['pincode']?.toString() ?? l10n.notAvailable,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Recognition & Progress
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.orange.shade700,
                            size: 24.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            l10n.recognitionProgress,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.tasksCompleted,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _tasksCompleted.toString(),
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.list_alt,
                              color: Colors.green,
                              size: 32.sp,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l10n.earnedBadges,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _badge(
                            icon: Icons.star,
                            color: Colors.orange.shade700,
                            text: l10n.quickResponse,
                            isEarned: _badges.contains('quickResponse'),
                          ),
                          _badge(
                            icon: Icons.verified,
                            color: Colors.green,
                            text: l10n.qualityWork,
                            isEarned: _badges.contains('qualityWork'),
                          ),
                          _badge(
                            icon: Icons.access_time,
                            color: Colors.blue,
                            text: l10n.onTime,
                            isEarned: _badges.contains('onTime'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Action Tiles
              _actionTile(
                Icons.lock,
                l10n.changePassword,
                Colors.blue,
                _showChangePasswordDialog,
              ),
              SizedBox(height: 12.h),
              _actionTile(Icons.language, l10n.changeLanguage, Colors.teal, () {
                _showLanguageDialog(context);
              }),
              SizedBox(height: 12.h),
              _actionTile(Icons.logout, l10n.logout, Colors.red, _handleLogout),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function for the language change dialog
void _showLanguageDialog(BuildContext context) {
  final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
  final l10n = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(l10n.selectLanguage),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  // Always show "English" in English
                  title: const Text('English'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('en'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  // Always show "हिन्दी" in Hindi
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
                  title: const Text('ᱥᱟᱱᱛᱟᱲᱤ'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('sat'));
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
                ListTile(
                  title: const Text('ಕನ್ನಡ'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('kn'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('ગુજરાતી'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('gu'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('தமிழ்'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('ta'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('অসমীয়া'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('as'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('ਪੰਜਾਬੀ'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('pa'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('বাংলা'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('bn'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('മലയാളം'),
                  onTap: () {
                    localeProvider.setLocale(const Locale('ml'));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Helper widget for info tiles
Widget _infoTile(IconData icon, String title, String subtitle) {
  return Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 24.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Helper widget for badges
Widget _badge({
  required IconData icon,
  required Color color,
  required String text,
  bool isEarned = true,
}) {
  return Column(
    children: [
      CircleAvatar(
        radius: 20.r,
        backgroundColor: isEarned
            ? color.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        child: Icon(
          icon,
          color: isEarned ? color : Colors.grey.shade400,
          size: 20.sp,
        ),
      ),
      SizedBox(height: 6.h),
      Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: isEarned ? Colors.black54 : Colors.grey.shade400,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

// Helper widget for action tiles
Widget _actionTile(
  IconData icon,
  String text,
  Color color,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 12.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 18.sp, color: Colors.black45),
        ],
      ),
    ),
  );
}
