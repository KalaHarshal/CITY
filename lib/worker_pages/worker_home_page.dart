import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'worker_complaint_page.dart';
import 'worker_notifications_page.dart'; // Add this import

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  _WorkerHomePageState createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  String selectedFilter = 'All';
  final filters = ['All', 'Assigned', 'In Progress', 'Resolved'];

  final complaints = <ComplaintItem>[];

  String? _workerId;
  String? _workerStatus; // "Available" or "On Leave"

  /// ✅ Map filter keys to localized labels
  String getFilterLabel(String filterKey, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (filterKey) {
      case 'All':
        return l10n.filterAll;
      case 'Assigned':
        return l10n.assigned;
      case 'In Progress':
        return l10n.inProgress;
      case 'Resolved':
        return l10n.resolved;
      default:
        return filterKey;
    }
  }

  List<ComplaintItem> get filteredComplaints {
    if (selectedFilter == 'All') return complaints;
    return complaints.where((c) => c.status == selectedFilter).toList();
  }

  int get pendingCount => complaints.where((c) => c.status == 'Pending').length;
  int get inProgressCount =>
      complaints.where((c) => c.status == 'In Progress').length;
  int get completedCount =>
      complaints.where((c) => c.status == 'Completed').length;
  int get resolvedCount =>
      complaints.where((c) => c.status == 'Resolved').length;

  @override
  void initState() {
    super.initState();
    _loadWorkerIdAndComplaints();
  }

  Future<void> _loadWorkerIdAndComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    _workerId = prefs.getString('workerId');
    if (_workerId != null) {
      // Fetch worker status
      final workerSnap = await FirebaseDatabase.instance
          .ref('workers/$_workerId')
          .get();
      if (workerSnap.exists && workerSnap.value != null) {
        final data = Map<String, dynamic>.from(workerSnap.value as Map);
        _workerStatus = data['status'] as String? ?? "Available";
      }
      await _fetchAssignedComplaints();
      setState(() {}); // Refresh UI after fetching
    }
  }

  Future<void> _fetchAssignedComplaints() async {
    final dbRef = FirebaseDatabase.instance.ref().child('complaints');
    final snapshot = await dbRef
        .orderByChild('assignedTo')
        .equalTo(_workerId)
        .get();

    final List<ComplaintItem> fetchedComplaints = [];
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        final complaintData = Map<String, dynamic>.from(value);
        fetchedComplaints.add(
          ComplaintItem(
            id: key,
            title:
                "${complaintData['category'] ?? 'Unknown'}"
                "${complaintData['subcategory'] != null ? ' - ${complaintData['subcategory']}' : ''}",
            status: complaintData['status'] ?? 'Pending',
            statusColor: _getStatusColor(complaintData['status']),
            dateTime: complaintData['dateTime'] ?? '',
          ),
        );
      });
    }
    setState(() {
      complaints.clear();
      complaints.addAll(fetchedComplaints);
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryBgColor(String title) {
    final mainCategory = title.split(' - ').first;
    switch (mainCategory) {
      case "Garbage":
        return const Color(0xFFEAF8ED);
      case "Street Light":
        return const Color(0xFFFFF9E5);
      case "Road Damage":
        return const Color(0xFFFFEAEA);
      case "Water":
      case "Drainage & Sewerage":
        return const Color(0xFFEAF4FF);
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getCategoryIcon(String title) {
    final mainCategory = title.split(' - ').first;
    switch (mainCategory) {
      case "Garbage":
        return Icons.delete;
      case "Street Light":
        return Icons.lightbulb_outline;
      case "Road Damage":
        return Icons.traffic;
      case "Water":
        return Icons.water_drop;
      case "Drainage & Sewerage":
        return Icons.water_damage_outlined;
      default:
        return Icons.report_problem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: WorkerDashboardHeader(),
        toolbarHeight: 110.h,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkerIdAndComplaints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 10.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SimpleStatusCard(
                          number: complaints
                              .where((c) => c.status == 'Assigned')
                              .length
                              .toString(),
                          label: loc.assigned,
                        ),
                        _SimpleStatusCard(
                          number: inProgressCount.toString(),
                          label: loc.inProgress,
                        ),
                        _SimpleStatusCard(
                          number: resolvedCount.toString(),
                          label: loc.resolved,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Worker status
              if (_workerStatus != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      color: _workerStatus == "On Leave"
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _workerStatus == "On Leave"
                              ? Icons.beach_access
                              : Icons.work,
                          color: _workerStatus == "On Leave"
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          _workerStatus == "On Leave"
                              ? "On Leave"
                              : "Available",
                          style: TextStyle(
                            color: _workerStatus == "On Leave"
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Filters
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final isSelected = selectedFilter == f;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text(
                            getFilterLabel(f, context),
                            style: TextStyle(fontSize: 13.sp),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.orange.shade700,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() => selectedFilter = f);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.recentComplaints,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.55, // Ensures scrollability
                child: filteredComplaints.isEmpty
                    ? Center(
                        child: Text(
                          "No complaints assigned to you.",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 16.h),
                        itemCount: filteredComplaints.length,
                        itemBuilder: (context, index) =>
                            buildComplaintCard(filteredComplaints[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildComplaintCard(ComplaintItem complaint) {
    final loc = AppLocalizations.of(context)!; // Get localizations
    String formattedDate = '';
    try {
      final dt = DateTime.parse(complaint.dateTime);
      formattedDate = DateFormat.yMMMd().add_jm().format(dt);
    } catch (_) {
      formattedDate = complaint.dateTime;
    }

    // Icon and background color logic
    Color iconBg;
    Color iconColor;
    switch (complaint.title.split(' - ').first) {
      case "Garbage":
        iconBg = const Color(0xFFEAF8ED);
        iconColor = Colors.green;
        break;
      case "Street Light":
        iconBg = const Color(0xFFFFF9E5);
        iconColor = Colors.orange;
        break;
      case "Road Damage":
        iconBg = const Color(0xFFFFEAEA);
        iconColor = Colors.red;
        break;
      case "Water":
        iconBg = const Color(0xFFEAF4FF);
        iconColor = const Color(0xFF1746D1);
        break;
      case "Drainage & Sewerage":
        iconBg = const Color(0xFFEAF4FF);
        iconColor = const Color(0xFF1746D1);
        break;
      default:
        iconBg = Colors.grey.shade100;
        iconColor = Colors.grey;
    }

    // Status chip color logic
    Color chipBg;
    Color chipText;
    switch (complaint.status) {
      case 'Resolved':
        chipBg = Colors.green.shade50;
        chipText = Colors.green.shade700;
        break;
      case 'In Progress':
        chipBg = Colors.blue.shade50;
        chipText = Colors.blue.shade700;
        break;
      case 'Assigned':
        chipBg = Colors.purple.shade50;
        chipText = Colors.purple.shade700;
        break;
      default:
        chipBg = Colors.grey.shade100;
        chipText = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerComplaintPage(complaintId: complaint.id),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon in rounded square
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(complaint.title),
                    color: iconColor,
                    size: 24.sp,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Status chip
              Container(
                margin: EdgeInsets.only(left: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getStatusLabel(
                    complaint.status,
                    loc,
                  ), // Use translated status
                  style: TextStyle(
                    color: chipText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to get translated status labels
  String _getStatusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case "Assigned":
        return loc.assigned;
      case "In Progress":
        return loc.inProgress;
      case "Resolved":
        return loc.resolved;
      default:
        return status;
    }
  }
}

class WorkerDashboardHeader extends StatelessWidget {
  const WorkerDashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      color: const Color(0xFFF57C00),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20.r,
                child: Icon(
                  Icons.account_balance,
                  color: Colors.orange.shade700,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.workerDashboard,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  Text(
                    loc.municipalServices,
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                // Change Icon to IconButton
                icon: Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 22.sp,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkerNotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleStatusCard extends StatelessWidget {
  final String number;
  final String label;

  const _SimpleStatusCard({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class ComplaintItem {
  final String id;
  final String title; // category-subcategory
  final String status;
  final Color statusColor;
  final String dateTime;
  ComplaintItem({
    required this.id,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.dateTime,
  });
}
