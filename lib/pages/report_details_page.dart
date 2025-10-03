import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reports_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import 'raise_grievance_page.dart';

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
  final String url;
  const VoiceNotePlayer({super.key, required this.url});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
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
      setState(() => _isPlaying = false);
    } else {
      await _player.play(UrlSource(widget.url));
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      icon: Icon(
        _isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.blue,
        size: 20.sp,
      ),
      label: Text(
        _isPlaying ? loc.pauseVoiceNote : loc.playVoiceNote,
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.08),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
  static const bgGrey = Color(0xFFF6F6F6);

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  bool _isGrievanceButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
  }

  Future<void> _fetchReportDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('complaints')
          .child(widget.complaintId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            _reportData = data;
            _isGrievanceButtonEnabled = _shouldShowGrievanceButton(data);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _shouldShowGrievanceButton(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    final submissionDateStr = data['dateTime'] as String?;
    final hasGrievance = data['grievance'] != null;

    if (hasGrievance) return false;
    if (status == 'Resolved') return true;

    if (submissionDateStr != null &&
        (status == 'Pending' || status == 'In Progress')) {
      final submissionDate = DateTime.tryParse(submissionDateStr);
      if (submissionDate != null &&
          DateTime.now().difference(submissionDate).inDays > 7) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: ReportDetailsPage.bgGrey,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_reportData == null) {
      return Scaffold(
        backgroundColor: ReportDetailsPage.bgGrey,
        appBar: AppBar(title: Text(loc.reportDetails)),
        body: Center(child: Text(loc.complaintNotFound)),
      );
    }

    final voiceNoteUrl = _reportData!['voiceNote'];
    final mediaList = (_reportData!['media'] as List<dynamic>? ?? []);
    final grievanceData = _reportData!['grievance'] as Map<dynamic, dynamic>?;

    return Scaffold(
      backgroundColor: ReportDetailsPage.bgGrey,
      appBar: AppBar(
        backgroundColor: ReportDetailsPage.mainBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyReportsPage()),
            (route) => false,
          ),
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
        onRefresh: _fetchReportDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Card
              _buildTopCard(loc),

              // Submitted Media
              if (mediaList.isNotEmpty)
                _buildMediaCard(loc, 'photosSubmitted', mediaList),

              // Issue Description & Voice Note
              _buildDescriptionCard(
                loc,
                'issueDescription',
                _reportData!['description'],
                voiceNoteUrl,
              ),

              // Status Timeline
              _buildTimelineCard(loc),

              // Resolution Details
              if (_reportData!['status'] == 'Resolved')
                _buildResolutionCard(loc),

              // Grievance Details
              if (grievanceData != null) _buildGrievanceDetailsCard(loc),

              SizedBox(height: 10.h),

              // --- Grievance Button ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.report_problem_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      loc.raiseGrievance,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isGrievanceButtonEnabled
                          ? Colors.redAccent
                          : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    onPressed: _isGrievanceButtonEnabled
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RaiseGrievancePage(
                                complaintId: widget.complaintId,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildTopCard(AppLocalizations loc) {
    return Container(
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
                  getCategoryIcon(_reportData!['category'] ?? ''),
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
                      "${_reportData!['category'] ?? ''} - ${_reportData!['subcategory'] ?? ''}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "${DateFormat('dd MMM yyyy').format(DateTime.parse(_reportData!['dateTime']))}, ${DateFormat('hh:mm a').format(DateTime.parse(_reportData!['dateTime']))}",
                      style: TextStyle(color: Colors.black54, fontSize: 13.sp),
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
                  _reportData!['location'] ?? '',
                  style: TextStyle(color: Colors.black87, fontSize: 14.sp),
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
                child: Text(
                  loc.refId(_reportData!['complaintId'] ?? ''),
                  style: TextStyle(color: Colors.black54, fontSize: 13.sp),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Chip(
                label: Text(
                  _getStatusLabel(_reportData!['status'] ?? '', loc),
                  style: TextStyle(
                    color: _getStatusColor(_reportData!['status']?.trim()),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                backgroundColor: _getStatusBgColor(
                  _reportData!['status']?.trim(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0.h),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(
    AppLocalizations loc,
    String titleKey,
    List<dynamic> media,
  ) {
    return Container(
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
            titleKey == 'Grievance Photos' ? loc.photos : loc.photosSubmitted,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 90.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, i) {
                // --- ERROR FIX STARTS HERE ---
                final dynamic rawItem = media[i];
                bool isVideo = false;
                String url;
                String? timestamp;

                if (rawItem is Map) {
                  // Handles citizen-submitted media {url, type, timestamp}
                  isVideo = rawItem['type'] == 'video';
                  url = rawItem['url'] as String;
                  timestamp = rawItem['timestamp'] as String?;
                } else {
                  // Handles worker-submitted media (just a URL string)
                  url = rawItem as String;
                  // For worker photos, we can use the main completion timestamp
                  timestamp = _reportData!['completionTimestamp'] as String?;
                }
                // --- ERROR FIX ENDS HERE ---

                String timeLabel = '';
                if (timestamp != null) {
                  try {
                    timeLabel = DateFormat(
                      'dd MMM, hh:mm a',
                    ).format(DateTime.parse(timestamp));
                  } catch (_) {}
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
                                onPressed: () => Navigator.of(context).pop(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(
    AppLocalizations loc,
    String titleKey,
    String? description,
    String? voiceUrl,
  ) {
    return Container(
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
            loc.issueDescription, // Assuming titleKey maps to this
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            description ?? loc.notAvailable,
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
          if (voiceUrl != null && voiceUrl.isNotEmpty) ...[
            SizedBox(height: 12.h),
            VoiceNotePlayer(url: voiceUrl),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard(AppLocalizations loc) {
    return Container(
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
          ),
          SizedBox(height: 12.h),
          _buildStatusTimeline(),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(AppLocalizations loc) {
    final photos = _reportData!['completionPhotos'] as List<dynamic>? ?? [];
    return Container(
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
          if (photos.isNotEmpty)
            _buildMediaCard(loc, 'Resolution Photos', photos),
          SizedBox(height: 18.h),
          Text(
            _reportData!['completionNotes'] ?? 'No description provided.',
            style: TextStyle(color: Colors.black, fontSize: 14.sp),
          ),
          if (_reportData!['completionVoiceNote'] != null &&
              _reportData!['completionVoiceNote'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: VoiceNotePlayer(url: _reportData!['completionVoiceNote']),
            ),
        ],
      ),
    );
  }

  Widget _buildGrievanceDetailsCard(AppLocalizations loc) {
    final grievanceData = _reportData!['grievance'] as Map<dynamic, dynamic>;
    final photos = grievanceData['photos'] as List<dynamic>? ?? [];
    final voiceNote = grievanceData['voiceNote'] as String?;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.grievanceReason,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: Colors.red.shade800,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            grievanceData['reason'] ?? 'No reason provided.',
            style: TextStyle(color: Colors.black, fontSize: 14.sp),
          ),
          if (photos.isNotEmpty) ...[
            SizedBox(height: 14.h),
            _buildMediaCard(loc, 'Grievance Photos', photos),
          ],
          if (voiceNote != null && voiceNote.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: VoiceNotePlayer(url: voiceNote),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final loc = AppLocalizations.of(context)!;

    int currentStage = 0;
    if (_reportData!['status'] == 'Resolved') {
      currentStage = 4;
    } else if (_reportData!['status'] == 'In Progress') {
      currentStage = 3;
    } else if (_reportData!['assignedTo'] != null) {
      currentStage = 2;
    } else {
      currentStage = 1;
    }

    final steps = [
      {
        "icon": Icons.check_circle,
        "color": Colors.green,
        "title": loc.submitted,
        "date":
            "${DateFormat('dd MMM yyyy').format(DateTime.parse(_reportData!['dateTime']))}, ${DateFormat('hh:mm a').format(DateTime.parse(_reportData!['dateTime']))}",
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
        "date": (_reportData!['assignedDate'] != null)
            ? DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(DateTime.parse(_reportData!['assignedDate']).toLocal())
            : (currentStage == 2 ? loc.currentStage : loc.notYet),
        "desc": loc.assignedToMunicipalWorker,
      },
      {
        "icon": Icons.construction,
        "color": Colors.blue,
        "title": loc.inProgress,
        "date": (_reportData!['inProgressTimestamp'] != null)
            ? DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(DateTime.parse(_reportData!['inProgressTimestamp']))
            : (currentStage == 3 ? loc.currentStage : loc.notYet),
        "desc": loc.workHasStarted,
      },
      {
        "icon": Icons.verified,
        "color": Colors.green,
        "title": loc.resolved,
        "date": (_reportData!['completionTimestamp'] != null)
            ? DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(DateTime.parse(_reportData!['completionTimestamp']))
            : (currentStage == 4 ? loc.currentStage : loc.notYet),
        "desc": loc.issueResolved,
      },
    ];

    final stepHeight = 95.0.h;

    return SizedBox(
      height: steps.length * stepHeight,
      child: Stack(
        children: [
          for (int i = 0; i < steps.length - 1; i++)
            Positioned(
              left: 16.w,
              top: 30.h + (i * stepHeight),
              height: stepHeight,
              width: 2.w,
              child: Container(
                color: currentStage > i
                    ? steps[i]["color"] as Color
                    : Colors.grey.shade300,
              ),
            ),
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
                    Container(
                      width: 32.w,
                      height: stepHeight,
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: EdgeInsets.only(top: 10.h),
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
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

  String _getStatusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case 'Pending':
        return loc.pending;
      case 'Assigned':
        return loc.assigned;
      case 'In Progress':
        return loc.inProgress;
      case 'Resolved':
        return loc.resolved;
      case 'Grievance Raised':
        return loc.grievanceRaised;
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Resolved':
        return Colors.green.shade700;
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Assigned':
        return Colors.purple.shade700;
      case 'Pending':
        return Colors.orange.shade700;
      case 'Grievance Raised':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status) {
      case 'Resolved':
        return Colors.green.shade50;
      case 'In Progress':
        return Colors.blue.shade50;
      case 'Assigned':
        return Colors.purple.shade50;
      case 'Pending':
        return Colors.orange.shade50;
      case 'Grievance Raised':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade200;
    }
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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.setLooping(true);
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
                  child: const Center(child: CircularProgressIndicator()),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.timestamp,
            style: const TextStyle(color: Colors.white, fontSize: 15),
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
              onPressed: () => setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              }),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.close,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
