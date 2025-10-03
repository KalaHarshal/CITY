import 'package:flutter/material.dart';
import 'worker_completionProof_page.dart';
import 'worker_reportIssue_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart'; // Add this
import '../l10n/app_localizations.dart'; // Add this
import 'package:video_player/video_player.dart';

// Voice note player widget (copied from report_details_page.dart)
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
    } else {
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
        size: 20.sp,
      ),
      label: Text(
        _isPlaying ? loc.pauseVoiceNote : loc.playVoiceNote,
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: isNonLatinScript ? 12.sp : 14.sp,
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

class WorkerComplaintPage extends StatefulWidget {
  final String complaintId;
  const WorkerComplaintPage({super.key, required this.complaintId});

  @override
  State<WorkerComplaintPage> createState() => _WorkerComplaintPageState();
}

class _WorkerComplaintPageState extends State<WorkerComplaintPage> {
  Map<String, dynamic>? complaintData;
  bool _loading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchComplaint();
  }

  Future<void> _fetchComplaint() async {
    final dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef
        .child('complaints')
        .child(widget.complaintId)
        .get();
    if (snapshot.exists) {
      setState(() {
        complaintData = Map<String, dynamic>.from(snapshot.value as Map);
        _loading = false;
      });
    } else {
      setState(() {
        complaintData = null;
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    final loc = AppLocalizations.of(context)!;

    final dbRef = FirebaseDatabase.instance
        .ref()
        .child('complaints')
        .child(widget.complaintId);

    try {
      await dbRef.update({'status': newStatus});
      if (mounted) {
        setState(() {
          complaintData!['status'] = newStatus;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.statusUpdated(newStatus)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.failedToUpdateStatus(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6), // Same as WorkerHomePage
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange.shade700, // Same as WorkerHomePage
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.complaintDetails,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : complaintData == null
          ? Center(
              child: Text(
                loc.complaintNotFound,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Complaint Info Card
                  Card(
                    elevation: 3,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(18.w),
                      child: Stack(
                        children: [
                          // Status chip at top right
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 11.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(
                                  complaintData!['status'] ?? '',
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Text(
                                _getStatusLabel(
                                  complaintData!['status'] ?? '',
                                  loc,
                                ),
                                style: TextStyle(
                                  color: _getStatusTextColor(
                                    complaintData!['status'] ?? '',
                                  ),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.complaintId,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Text(
                                complaintData!['complaintId'] ??
                                    widget.complaintId,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19.sp,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22.r,
                                    backgroundColor: _getCategoryBgColor(
                                      complaintData!['category'] ?? '',
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(
                                        complaintData!['category'] ?? '',
                                      ),
                                      color: _getCategoryIconColor(
                                        complaintData!['category'] ?? '',
                                      ),
                                      size: 28.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  // Expanded text for category-subcategory and address
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${complaintData!['category'] ?? ''}${complaintData!['subcategory'] != null ? ' - ${complaintData!['subcategory']}' : ''}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16.sp,
                                            color: Colors.black,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          complaintData!['location'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13.sp,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // REMOVE the navigation icon here!
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  // Date/time at bottom left
                                  Text(
                                    _formatDateTime(complaintData!['dateTime']),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  Spacer(),
                                  // Navigate button at bottom right
                                  if (complaintData!['gps'] != null &&
                                      complaintData!['gps']
                                          .toString()
                                          .isNotEmpty)
                                    SizedBox(
                                      width: 140.w,
                                      child: OutlinedButton.icon(
                                        icon: Icon(
                                          Icons.navigation,
                                          color: Colors.blue,
                                          size: 20.sp,
                                        ),
                                        label: Text(
                                          loc.navigate,
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.blue,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10.h,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final gps = complaintData!['gps']
                                              .toString();
                                          final coords = gps.split(',');
                                          if (coords.length == 2) {
                                            final lat = coords[0].trim();
                                            final lng = coords[1].trim();

                                            // Try the geo: URI scheme first (works better on Android)
                                            Uri geoUri = Uri.parse(
                                              'geo:$lat,$lng?q=$lat,$lng',
                                            );

                                            if (await canLaunchUrl(geoUri)) {
                                              await launchUrl(geoUri);
                                            } else {
                                              // Fallback to web URL
                                              final webUrl =
                                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                              final webUri = Uri.parse(webUrl);

                                              if (await canLaunchUrl(webUri)) {
                                                await launchUrl(
                                                  webUri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      loc.couldNotOpenMaps,
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  // Citizen Submission Card
                  Card(
                    elevation: 3,
                    color:
                        Colors.white, // Match top card and report details page
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.citizenSubmission,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: Colors.black, // Changed to black
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            loc.photos,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: Colors.black, // Changed to black
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Builder(
                            builder: (context) {
                              final mediaList =
                                  (complaintData!['media'] as List<dynamic>? ??
                                  []);
                              if (mediaList.isEmpty) {
                                return Container(
                                  width: 90.w,
                                  height: 90.w,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey.shade500,
                                    size: 32.sp,
                                  ),
                                );
                              }
                              return SizedBox(
                                height: 90.h,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: mediaList.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: 10.w),
                                  itemBuilder: (context, i) {
                                    final media = mediaList[i] as Map;
                                    final isVideo = media['type'] == 'video';
                                    final url = media['url'] as String;
                                    final timestamp =
                                        media['timestamp'] as String?;
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
                                                    padding: EdgeInsets.all(
                                                      8.w,
                                                    ),
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
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
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
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
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
                              );
                            },
                          ),
                          SizedBox(height: 18.h),
                          Text(
                            loc.description,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: Colors.black, // Changed to black
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: Colors
                                  .grey
                                  .shade100, // Changed to match completion proof
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              complaintData!['description'] ?? loc.notAvailable,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          if (complaintData!['voiceNote'] != null &&
                              complaintData!['voiceNote'].toString().isNotEmpty)
                            // --- REPLACE THIS SECTION ---
                            VoiceNotePlayer(url: complaintData!['voiceNote']),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // --- UPDATED COMPLETION PROOF CARD ---
                  if (complaintData!['status'] == 'Resolved')
                    Card(
                      elevation: 3,
                      color: Colors.white, // Match the card style above
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(18.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.completionProof,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              loc.photos,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Display Completion Photos with Preview and Watermark
                            if (complaintData!['completionPhotos'] != null &&
                                (complaintData!['completionPhotos'] as List)
                                    .isNotEmpty)
                              SizedBox(
                                height: 90.h,
                                child: ListView.separated(
                                  // Changed to ListView.separated
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      (complaintData!['completionPhotos']
                                              as List)
                                          .length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: 10.w), // Added gap
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
                                        timeLabel =
                                            ''; // Don't show if parsing fails
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
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
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
                                      },
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
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
                                loc.noCompletionPhotos,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            SizedBox(height: 18.h),
                            Text(
                              loc.description,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors
                                    .grey
                                    .shade100, // Light grey background for description
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                complaintData!['completionNotes'] ??
                                    loc.noDescriptionProvided,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            // --- ADDED COMPLETION VOICE NOTE PLAYER ---
                            if (complaintData!['completionVoiceNote'] != null &&
                                complaintData!['completionVoiceNote']
                                    .toString()
                                    .isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 18.h),
                                child: VoiceNotePlayer(
                                  url: complaintData!['completionVoiceNote'],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 18.h),
                  // Buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    onPressed: complaintData!['status'] == 'In Progress'
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkerCompletionProofPage(
                                  complaintId: widget.complaintId,
                                ),
                              ),
                            );
                          }
                        : null, // Disable if status is not 'In Progress'
                    icon: Icon(Icons.camera_alt, size: 20.sp),
                    label: Text(
                      loc.uploadCompletionPhotos,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade100,
                      foregroundColor: Colors.orange.shade900,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    onPressed:
                        _isUpdating || complaintData!['status'] != 'Assigned'
                        ? null // Disable if not 'Assigned' or if updating
                        : () => _updateStatus('In Progress'),
                    icon: _isUpdating
                        ? SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange.shade900,
                            ),
                          )
                        : Icon(Icons.build, size: 20.sp),
                    label: Text(
                      loc.markAsInProgress,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade400,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    onPressed: complaintData!['status'] == 'Resolved'
                        ? null // Disable if resolved
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkerReportIssuePage(),
                              ),
                            );
                          },
                    icon: Icon(Icons.report_problem, size: 20.sp),
                    label: Text(
                      loc.reportIssue,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
    );
  }

  Widget _imagePreview(String url) {
    return Container(
      width: 55.w,
      height: 55.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: Colors.grey.shade300,
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

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

  Color _getCategoryBgColor(String category) {
    switch (category) {
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
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

  Color _getCategoryIconColor(String category) {
    switch (category) {
      case "Garbage":
        return Colors.green;
      case "Street Light":
        return Colors.orange;
      case "Road Damage":
        return Colors.red;
      case "Water":
      case "Drainage & Sewerage":
        return const Color(0xFF1746D1);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case "Assigned":
        return Colors.purple.shade50;
      case "In Progress":
        return Colors.blue.shade50;
      case "Resolved":
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case "Assigned":
        return Colors.purple.shade700;
      case "In Progress":
        return Colors.blue.shade700;
      case "Resolved":
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null || dateTime.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return DateFormat.yMMMd().add_jm().format(dt);
    } catch (_) {
      return dateTime.toString();
    }
  }
}

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
