import 'package:CiTY/models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reports_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

// Icon selection based on complaint category
IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Garbage':
      return Icons.delete;
    case 'Street Light':
      return Icons.lightbulb_outline;
    case 'Road Damage':
      return Icons.construction;
    case 'Water':
      return Icons.water_drop;
    case 'Drainage & Sewerage':
      return Icons.water_damage_outlined;
    default:
      return Icons.report_problem;
  }
}

// Voice note player widget
class VoiceNotePlayer extends StatefulWidget {
  final String url; // Changed from path to url
  const VoiceNotePlayer({super.key, required this.url});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      // ✅ Use UrlSource for Firebase URLs
      await _player.play(UrlSource(widget.url));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final bool isNonLatinScript =
        (currentLocale == 'sat' || currentLocale == 'hi');

    return ElevatedButton.icon(
      icon: Icon(
        _isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.blue,
        size: 20.sp, // Slightly smaller icon
      ),
      label: Text(
        _isPlaying ? loc.pauseVoiceNote : loc.playVoiceNote,
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: isNonLatinScript
              ? 12.sp
              : 14.sp, // Smaller font for Hindi/Santali
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.08),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 8.h,
        ), // Reduced horizontal padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      onPressed: _togglePlay,
    );
  }
}

class ReportDetailsPage extends StatefulWidget {
  final String complaintId;
  const ReportDetailsPage({super.key, required this.complaintId});

  static const mainBlue = Color(0xFF1746D1);
  static const navBg = Color(0xFFF0F4FF);
  static const bgGrey = Color(0xFFF6F6F6); // Add this for home page grey

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  Map<String, dynamic>? complaintData;
  bool _loading = true;
  String formattedDate = '';
  String formattedTime = '';
  String effectiveStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _loadComplaint();
  }

  Future<void> _loadComplaint() async {
    // First, try to load from Hive cache for instant display
    final box = Hive.box<Report>('reportsBox');
    final cachedReport = box.get(widget.complaintId);
    if (cachedReport != null) {
      // Use cached data to build a temporary map for display
      setState(() {
        complaintData = {
          'complaintId': cachedReport.complaintId,
          'category': cachedReport.title.split(' - ')[0],
          'subcategory': cachedReport.title.split(' - ')[1],
          'status': cachedReport.status,
          // We need to fetch the rest from Firebase
        };
        effectiveStatus = cachedReport.status;
        _loading = false; // Stop loading, show cached data
      });
    }
    // Always fetch from Firebase for the latest details
    await _fetchComplaintFromFirebase();
  }

  Future<void> _fetchComplaintFromFirebase() async {
    final dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef
        .child('complaints')
        .child(widget.complaintId)
        .get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Always use the status from the global complaint data
      String status = data['status'] ?? 'Pending';

      DateTime? dt = DateTime.tryParse(data['dateTime'] ?? '');
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(dt);
        formattedTime = DateFormat('hh:mm a').format(dt);
      }

      if (mounted) {
        setState(() {
          complaintData = data;
          effectiveStatus = status; // Always use status from global node
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ✅ Helper to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFB26A00); // Dark Orange
      case "Assigned":
        return Colors.purple;
      case "In Progress":
        return Colors.blue;
      case "Resolved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ Helper to get status background color
  Color _getStatusBgColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFFFF6E0); // Light Orange
      case "Assigned":
        return Colors.purple.withOpacity(0.1);
      case "In Progress":
        return Colors.blue.withOpacity(0.1);
      case "Resolved":
        return Colors.green.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  String _getStatusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case "Pending":
        return loc.pending;
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;

    if (_loading) {
      return Scaffold(
        backgroundColor: ReportDetailsPage.bgGrey,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (complaintData == null) {
      return Scaffold(
        backgroundColor: ReportDetailsPage.bgGrey,
        body: Center(child: Text(loc.complaintNotFound)),
      );
    }

    final voiceNoteUrl = complaintData!['voiceNote'];
    // Media Submitted (photos & videos)
    final mediaList = (complaintData!['media'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: ReportDetailsPage.bgGrey,
      appBar: AppBar(
        backgroundColor: ReportDetailsPage.mainBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MyReportsPage()),
              (route) => false,
            );
          },
        ),
        title: Text(
          loc.reportDetails,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchComplaintFromFirebase,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Card
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: ReportDetailsPage.mainBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.all(8.w),
                          child: Icon(
                            getCategoryIcon(complaintData!['category'] ?? ''),
                            color: ReportDetailsPage.mainBlue,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${complaintData!['category'] ?? ''} - ${complaintData!['subcategory'] ?? ''}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "$formattedDate, $formattedTime",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: ReportDetailsPage.mainBlue,
                          size: 18.sp,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            complaintData!['location'] ?? '',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.tag, color: Colors.grey, size: 18.sp),
                        SizedBox(width: 4.w),
                        Expanded(
                          // Add this to allow text to wrap if needed
                          child: Text(
                            loc.refId(complaintData!['complaintId'] ?? ''),
                            //loc.refId("", complaintData!['complaintId'] ?? ''),
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13.sp,
                            ),
                            maxLines: 2, // Allow two lines
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w), // Add space before the chip
                        // ✅ DYNAMIC STATUS CHIP
                        Chip(
                          label: Text(
                            _getStatusLabel(effectiveStatus, loc),
                            style: TextStyle(
                              color: _getStatusColor(effectiveStatus.trim()),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          backgroundColor: _getStatusBgColor(
                            effectiveStatus.trim(),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 0.h,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (mediaList.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.photosSubmitted,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        height: 90.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: mediaList.length,
                          separatorBuilder: (_, __) => SizedBox(width: 10.w),
                          itemBuilder: (context, i) {
                            final media = mediaList[i] as Map;
                            final isVideo = media['type'] == 'video';
                            final url = media['url'] as String;
                            final timestamp = media['timestamp'] as String?;
                            String timeLabel = '';
                            if (timestamp != null) {
                              try {
                                final dt = DateTime.parse(timestamp);
                                timeLabel = DateFormat(
                                  'dd MMM, hh:mm a',
                                ).format(dt);
                              } catch (_) {
                                timeLabel = timestamp;
                              }
                            }
                            return GestureDetector(
                              onTap: () {
                                if (isVideo) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.black,
                                      child: _VideoPreviewDialog(
                                        url: url,
                                        timestamp: timeLabel,
                                      ),
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.black,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.network(
                                            url,
                                            width: 300.w,
                                            fit: BoxFit.contain,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.w),
                                            child: Text(
                                              timeLabel,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.sp,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text(
                                              loc.close,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: isVideo
                                        ? Container(
                                            width: 90.w,
                                            height: 90.w,
                                            color: Colors.black12,
                                            child: Center(
                                              child: Icon(
                                                Icons.videocam,
                                                color: Colors.red,
                                                size: 40.sp,
                                              ),
                                            ),
                                          )
                                        : Image.network(
                                            url,
                                            width: 90.w,
                                            height: 90.w,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 2.h,
                                    left: 2.w,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                        vertical: 2.h,
                                      ),
                                      child: Text(
                                        timeLabel,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Issue Description & Voice Note
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.issueDescription,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      complaintData!['description'] ?? '',
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                    ),
                    if (voiceNoteUrl != null && voiceNoteUrl != "") ...[
                      SizedBox(height: 12.h),
                      // ✅ Pass URL to the player
                      VoiceNotePlayer(url: voiceNoteUrl),
                    ],
                  ],
                ),
              ),

              // Status Timeline
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.statusTimeline,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildStatusTimeline(),
                  ],
                ),
              ),

              if (complaintData!['status'] == 'Resolved')
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resolution Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      if (complaintData!['completionPhotos'] != null &&
                          (complaintData!['completionPhotos'] as List)
                              .isNotEmpty)
                        SizedBox(
                          height: 90.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                (complaintData!['completionPhotos'] as List)
                                    .length,
                            separatorBuilder: (_, __) => SizedBox(width: 10.w),
                            itemBuilder: (context, i) {
                              final photoUrl =
                                  (complaintData!['completionPhotos']
                                      as List)[i];
                              final completionTimestamp =
                                  complaintData!['completionTimestamp'];
                              String timeLabel = '';
                              if (completionTimestamp != null &&
                                  completionTimestamp is String) {
                                try {
                                  final dt = DateTime.parse(
                                    completionTimestamp,
                                  );
                                  timeLabel = DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format(dt);
                                } catch (_) {
                                  timeLabel = '';
                                }
                              }
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.black,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.network(
                                            photoUrl,
                                            fit: BoxFit.contain,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.w),
                                            child: Text(
                                              timeLabel,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.sp,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text(
                                              'Close',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Image.network(
                                        photoUrl,
                                        width: 90.w,
                                        height: 90.w,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (timeLabel.isNotEmpty)
                                      Positioned(
                                        bottom: 2.h,
                                        left: 2.w,
                                        child: Container(
                                          color: Colors.black54,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4.w,
                                            vertical: 2.h,
                                          ),
                                          child: Text(
                                            timeLabel,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Text(
                          'No completion photos available.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      SizedBox(height: 18.h),
                      Text(
                        complaintData!['completionNotes'] ??
                            'No description provided.',
                        style: TextStyle(color: Colors.black, fontSize: 14.sp),
                      ),
                      if (complaintData!['completionVoiceNote'] != null &&
                          complaintData!['completionVoiceNote']
                              .toString()
                              .isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: VoiceNotePlayer(
                            url: complaintData!['completionVoiceNote'],
                          ),
                        ),
                    ],
                  ),
                ),

              SizedBox(height: 10.h), // Bottom padding

              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.report_problem,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                    label: Text(
                      loc.raiseGrievance,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: 0,
                      ), // Remove extra vertical padding
                    ),
                    onPressed: () {
                      // TODO: Implement grievance raising logic or navigation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Raise Grievance pressed!')),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 10.h), // Extra bottom padding if needed
            ],
          ),
        ),
      ),
    );
  }

  // --- Connect status lines ---
  Widget _buildStatusTimeline() {
    final loc = AppLocalizations.of(context)!;

    int currentStage = 0;
    if (complaintData!['status'] == 'Resolved') {
      currentStage = 4;
    } else if (complaintData!['status'] == 'In Progress') {
      currentStage = 3;
    } else if (complaintData!['assignedTo'] != null) {
      currentStage = 2;
    } else {
      currentStage = 1;
    }

    final steps = [
      {
        "icon": Icons.check_circle,
        "color": Colors.green,
        "title": loc.submitted,
        "date": "$formattedDate, $formattedTime",
        "desc": loc.reportSubmittedByCitizen,
      },
      {
        "icon": Icons.hourglass_empty,
        "color": const Color(0xFFB26A00),
        "title": loc.pendingReview,
        "date": currentStage > 1 ? loc.completed : loc.currentStage,
        "desc": loc.waitingForAssignment,
      },
      {
        "icon": Icons.person_search,
        "color": Colors.purple,
        "title": loc.assigned,
        "date": (complaintData!['assignedDate'] != null)
            ? DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(DateTime.parse(complaintData!['assignedDate']).toLocal())
            : (currentStage == 2 ? loc.currentStage : loc.notYet),
        "desc": loc.assignedToMunicipalWorker,
      },
      {
        "icon": Icons.construction,
        "color": Colors.blue,
        "title": loc.inProgress,
        "date": (complaintData!['inProgressTimestamp'] != null)
            ? DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(DateTime.parse(complaintData!['inProgressTimestamp']))
            : (currentStage == 3 ? loc.currentStage : loc.notYet),
        "desc": loc.workHasStarted,
      },
      {
        "icon": Icons.verified,
        "color": Colors.green,
        "title": loc.resolved,
        "date": (complaintData!['completionTimestamp'] != null)
            ? DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(DateTime.parse(complaintData!['completionTimestamp']))
            : (currentStage == 4 ? loc.currentStage : loc.notYet),
        "desc": loc.issueResolved,
      },
    ];

    // Height per step (adjust as needed)
    final stepHeight = 95.0.h;

    return SizedBox(
      height: steps.length * stepHeight,
      child: Stack(
        children: [
          // Draw multiple line segments colored according to progress
          for (int i = 0; i < steps.length - 1; i++)
            Positioned(
              left: 16.w, // Center of the icon column
              top:
                  30.h +
                  (i * stepHeight), // Start position (first icon's center)
              height: stepHeight, // One segment height
              width: 2.w,
              child: Container(
                color: currentStage > i
                    ? steps[i]["color"]
                          as Color // Completed segment: use that step's color
                    : Colors.grey.shade300, // Future segment: gray
              ),
            ),

          // Place all steps on top of the line
          Column(
            children: List.generate(steps.length, (i) {
              final isActive = currentStage >= i;
              final stepColor = isActive
                  ? steps[i]["color"] as Color
                  : Colors.grey.shade400;

              return SizedBox(
                height: stepHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon column - centered on the vertical line
                    Container(
                      width: 32.w,
                      height: stepHeight,
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: EdgeInsets.only(top: 10.h),
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors
                              .white, // White background to cover the line
                          border: Border.all(
                            color: isActive ? stepColor : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          steps[i]["icon"] as IconData,
                          color: isActive ? stepColor : Colors.grey.shade400,
                          size: 18.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Step content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i]["title"] as String,
                              style: TextStyle(
                                color: isActive
                                    ? stepColor
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                              maxLines: 2,
                            ),
                            Text(
                              steps[i]["date"] as String,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11.sp,
                                fontWeight:
                                    (steps[i]["date"] == loc.currentStage)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              steps[i]["desc"] as String,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                                fontSize: 12.sp,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Video preview dialog
class _VideoPreviewDialog extends StatefulWidget {
  final String url;
  final String timestamp;
  const _VideoPreviewDialog({required this.url, required this.timestamp});

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: _initialized ? _controller.value.aspectRatio : 16 / 9,
          child: _initialized
              ? VideoPlayer(_controller)
              : Container(
                  color: Colors.black,
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            widget.timestamp,
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.close,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
