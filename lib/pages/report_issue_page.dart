import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import '../l10n/app_localizations.dart';
import 'home_page.dart';
import 'reports_page.dart';
import 'user_profile_page.dart';
import 'submitted_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:video_player/video_player.dart'; // Add this import

class _MediaWithTimestamp {
  final File file;
  final DateTime timestamp;
  final bool isVideo;
  _MediaWithTimestamp({
    required this.file,
    required this.timestamp,
    required this.isVideo,
  });
}

class ReportIssuePage extends StatefulWidget {
  final String? prefilledCategory;

  const ReportIssuePage({super.key, this.prefilledCategory});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String? selectedCategory;
  String? selectedSubcategory;
  String? customSubcategory;
  List<_MediaWithTimestamp> mediaSlots = [];
  String? location;
  String? gps;
  String? address;
  TextEditingController detailsController = TextEditingController();
  TextEditingController customSubcategoryController = TextEditingController();

  static const mainBlue = Color(0xFF1746D1);
  static const navBg = Color(0xFFF0F4FF);

  // Audio
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSubmitting = false;

  final Map<String, List<String>> categoryMap = {
    'Garbage': [
      'Uncollected / Overflowing Garbage Bin',
      'Garbage Dumping in Open Area',
      'Damaged / Missing Garbage Bin',
      'Dead Animal Disposal',
    ],
    'Street Light': [
      'Light not working at night',
      'Light flickering',
      'Light glowing in daytime',
      'Pole damaged / wire issue',
    ],
    'Road Damage': [
      'Pothole',
      'Broken Manhole / Drain',
      'Cracks in Road Surface',
      'Damaged Speed Breaker',
    ],
    'Water': ['Water Leakage', 'Water Contamination'],
    'Drainage & Sewerage': [
      'Blocked Drain',
      'Flooding / Waterlogging',
      'Open Sewer / Foul Smell',
      'Broken Drain Cover',
    ],
  };

  final Map<String, String> categoryShortCodes = {
    'Garbage': 'GBG',
    'Street Light': 'SLT',
    'Road Damage': 'RDG',
    'Water': 'WTR',
    'Drainage & Sewerage': 'DRN',
  };

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCategory != null &&
        categoryMap.keys.contains(widget.prefilledCategory)) {
      selectedCategory = widget.prefilledCategory;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAndFetchLocation();
    });
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    Future.microtask(() async {
      await _recorder!.openRecorder();
      await _player!.openPlayer();
    });
  }

  @override
  void dispose() {
    detailsController.dispose();
    customSubcategoryController.dispose();
    Future.microtask(() async {
      await _recorder?.closeRecorder();
      await _player?.closePlayer();
    });
    super.dispose();
  }

  Future<void> _requestAndFetchLocation() async {
    final loc = AppLocalizations.of(context)!;
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.permissionRequired),
          content: Text(loc.locationPermissionPermanentlyDenied),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: Text(loc.openSettings),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.cancel),
            ),
          ],
        ),
      );
      setState(() {
        location = loc.locationPermissionDenied;
        gps = "";
        address = null;
      });
      return;
    }
    if (!status.isGranted) {
      setState(() {
        location = loc.locationPermissionDenied;
        gps = "";
        address = null;
      });
      return;
    }
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final loc = AppLocalizations.of(context)!;
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        gps = "${pos.latitude}, ${pos.longitude}";
        location = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
      });
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          address = [
            if (p.name != null && p.name!.isNotEmpty) p.name,
            if (p.street != null && p.street!.isNotEmpty) p.street,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
            if (p.subAdministrativeArea != null &&
                p.subAdministrativeArea!.isNotEmpty)
              p.subAdministrativeArea,
            if (p.administrativeArea != null &&
                p.administrativeArea!.isNotEmpty)
              p.administrativeArea,
            if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode,
            if (p.country != null && p.country!.isNotEmpty) p.country,
          ].whereType<String>().join(', ');
        });
      } else {
        setState(() {
          address = loc.addressNotFound;
        });
      }
    } catch (e) {
      setState(() {
        location = loc.unableToFetchLocation;
        gps = "";
        address = null;
      });
    }
  }

  Future<void> _pickMedia(int slot) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Choose Option'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'photo'),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blue),
                SizedBox(width: 8),
                Text('Capture Photo'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'video'),
            child: Row(
              children: [
                Icon(Icons.videocam, color: Colors.red),
                SizedBox(width: 8),
                Text('Capture Video'),
              ],
            ),
          ),
        ],
      ),
    );
    if (action == 'photo') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
      );
      if (picked != null) {
        File? compressed = await _compressImage(File(picked.path));
        if (compressed != null) {
          setState(() {
            if (mediaSlots.length < 3) {
              mediaSlots.add(
                _MediaWithTimestamp(
                  file: compressed,
                  timestamp: DateTime.now(),
                  isVideo: false,
                ),
              );
            }
          });
        }
      }
    } else if (action == 'video') {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );
      if (picked != null) {
        setState(() {
          if (mediaSlots.length < 3) {
            mediaSlots.add(
              _MediaWithTimestamp(
                file: File(picked.path),
                timestamp: DateTime.now(),
                isVideo: true,
              ),
            );
          }
        });
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return file;
      if (image.width > 1024) {
        image = img.copyResize(image, width: 1024);
      }
      final compressedBytes = img.encodeJpg(image, quality: 60);
      final dir = await getTemporaryDirectory();
      final target = File(
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );
      await target.writeAsBytes(compressedBytes);
      return target;
    } catch (e) {
      return file;
    }
  }

  Future<void> _startRecording() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) return;
    Directory tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/voice_note.aac';
    await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
    setState(() {
      _audioPath = path;
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playAudio() async {
    if (_audioPath == null) return;
    setState(() => _isPlaying = true);
    await _player!.startPlayer(
      fromURI: _audioPath,
      whenFinished: () => setState(() => _isPlaying = false),
    );
  }

  Future<void> _stopAudio() async {
    await _player!.stopPlayer();
    setState(() => _isPlaying = false);
  }

  void _deleteVoiceNote() {
    if (_audioPath != null) {
      File(_audioPath!).delete().catchError((_) {});
    }
    setState(() {
      _audioPath = null;
      _isPlaying = false;
      _isRecording = false;
    });
  }

  void _showMediaPreview(_MediaWithTimestamp media) {
    if (media.isVideo) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          child: _VideoPreviewDialog(
            file: media.file,
            timestamp: media.timestamp,
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
              Image.file(media.file),
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(media.timestamp),
                  style: TextStyle(color: Colors.white, fontSize: 15.sp),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  bool get _isCategoryRequired => widget.prefilledCategory == null;
  bool get _isOtherSelected => selectedSubcategory == 'Other';
  bool get _isFormValid =>
      (selectedCategory != null || !_isCategoryRequired) &&
      selectedSubcategory != null &&
      selectedSubcategory!.isNotEmpty &&
      (!_isOtherSelected ||
          (customSubcategoryController.text.trim().isNotEmpty)) &&
      mediaSlots.isNotEmpty &&
      address != null &&
      address!.isNotEmpty &&
      address != AppLocalizations.of(context)!.addressNotFound;

  // Upload media (photo/video) to Firebase Storage
  Future<List<Map<String, dynamic>>> _uploadMediaToStorage(
    String complaintId,
  ) async {
    final storageRef = FirebaseStorage.instance.ref();
    List<Map<String, dynamic>> mediaUrls = [];
    for (var i = 0; i < mediaSlots.length; i++) {
      final media = mediaSlots[i];
      final timestampStr = media.timestamp.toIso8601String().replaceAll(
        ':',
        '-',
      );
      final ext = media.isVideo ? 'mp4' : 'jpg';
      final type = media.isVideo ? 'video' : 'photo';
      final fileName = '${type}_${i + 1}_$timestampStr.$ext';
      final ref = storageRef.child('complaints/$complaintId/$fileName');
      final uploadTask = await ref.putFile(media.file);
      final url = await uploadTask.ref.getDownloadURL();
      mediaUrls.add({
        'type': type,
        'url': url,
        'timestamp': media.timestamp.toIso8601String(),
      });
    }
    return mediaUrls;
  }

  // Upload audio to Firebase Storage (optional)
  Future<String?> _uploadAudioToStorage(String complaintId) async {
    if (_audioPath == null) return null;
    final storageRef = FirebaseStorage.instance.ref();
    final fileName =
        'voice_note_${DateTime.now().toIso8601String().replaceAll(':', '-')}.aac';
    final ref = storageRef.child('complaints/$complaintId/$fileName');
    final uploadTask = await ref.putFile(File(_audioPath!));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> _generateComplaintId(String category) async {
    final dbRef = FirebaseDatabase.instance.ref();
    final now = DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(now); // Short date: yyMMdd
    final catShort =
        categoryShortCodes[category] ?? category.substring(0, 3).toUpperCase();

    // Query all complaints for this category and date
    final snapshot = await dbRef
        .child('complaints')
        .orderByChild('category_date')
        .equalTo('$catShort-$dateStr')
        .get();

    int count = 1;
    if (snapshot.exists) {
      count = snapshot.children.length + 1;
    }

    // Format: GBG-250905-001
    return '$catShort-$dateStr-${count.toString().padLeft(3, '0')}';
  }

  Future<void> _submitReport() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      final phoneNumber =
          FirebaseAuth.instance.currentUser?.phoneNumber ?? "unknown";
      final complaintId = await _generateComplaintId(selectedCategory!);

      // Upload media and audio
      final mediaInfo = await _uploadMediaToStorage(complaintId);
      final audioUrl = await _uploadAudioToStorage(complaintId);

      // Prepare complaint data
      final catShort =
          categoryShortCodes[selectedCategory!] ??
          selectedCategory!.substring(0, 3).toUpperCase();
      final dateStr = DateFormat('yyMMdd').format(DateTime.now());
      final complaintData = {
        "complaintId": complaintId,
        "userId": phoneNumber,
        "category": selectedCategory,
        "subcategory": _isOtherSelected
            ? customSubcategoryController.text.trim()
            : selectedSubcategory,
        "description": detailsController.text.trim(),
        "media": mediaInfo,
        "voiceNote": audioUrl,
        "location": address,
        "gps": gps,
        "dateTime": DateTime.now().toIso8601String(),
        "status": "Pending",
        "assignedTo": null,
        "assignedTimestamp": null,
        "category_date": "$catShort-$dateStr",
      };

      // Store only the complaint ID under the user node
      await dbRef
          .child('users')
          .child(phoneNumber)
          .child('complaints')
          .child(complaintId)
          .set(true);

      // Store the full complaint data under the global complaints node
      await dbRef.child('complaints').child(complaintId).set(complaintData);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SubmittedPage(complaintId: complaintId),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.submitFailed(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    List<String> subcategories = selectedCategory != null
        ? [...categoryMap[selectedCategory!]!, 'Other']
        : [];

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomePage()),
          (route) => false,
        );
        return false; // Prevent default pop
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: mainBlue,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            loc.reportIssue,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.selectCategory,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 55.h,
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        hint: Text(
                          loc.selectCategoryHint,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        items: categoryMap.keys
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: widget.prefilledCategory != null
                            ? null
                            : (v) {
                                setState(() {
                                  selectedCategory = v;
                                  selectedSubcategory = null;
                                });
                              },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 14.h,
                          ),
                          filled: widget.prefilledCategory != null,
                          fillColor: widget.prefilledCategory != null
                              ? Colors.grey.shade100
                              : null,
                        ),
                        disabledHint: widget.prefilledCategory != null
                            ? Text(
                                widget.prefilledCategory!,
                                style: TextStyle(fontSize: 14.sp),
                              )
                            : null,
                        isExpanded: true,
                      ),
                    ),
                    if (_isCategoryRequired && selectedCategory == null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h, left: 4.w),
                        child: Text(
                          loc.categoryRequired,
                          style: TextStyle(color: Colors.red, fontSize: 12.sp),
                        ),
                      ),
                    SizedBox(height: 20.h),

                    Text(
                      loc.subcategory,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 55.h,
                      child: DropdownButtonFormField<String>(
                        value: selectedSubcategory,
                        hint: Text(
                          loc.subcategoryHint,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        items: subcategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedSubcategory = v;
                            if (v != 'Other') {
                              customSubcategoryController.clear();
                            }
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ),
                    if (selectedSubcategory == null ||
                        selectedSubcategory!.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h, left: 4.w),
                        child: Text(
                          loc.subcategoryRequired,
                          style: TextStyle(color: Colors.red, fontSize: 12.sp),
                        ),
                      ),
                    if (_isOtherSelected)
                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: TextField(
                          controller: customSubcategoryController,
                          decoration: InputDecoration(
                            labelText: loc.pleaseSpecify,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    if (_isOtherSelected &&
                        customSubcategoryController.text.trim().isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h, left: 4.w),
                        child: Text(
                          loc.pleaseSpecifyIssue,
                          style: TextStyle(color: Colors.red, fontSize: 12.sp),
                        ),
                      ),
                    SizedBox(height: 20.h),

                    Row(
                      children: [
                        Text(
                          loc.capturePhotos,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        Text(
                          ' *',
                          style: TextStyle(color: Colors.red, fontSize: 15.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 90.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, __) => SizedBox(width: 10.w),
                        itemBuilder: (context, i) {
                          if (i < mediaSlots.length) {
                            final media = mediaSlots[i];
                            return GestureDetector(
                              onTap: () => _showMediaPreview(media),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: media.isVideo
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
                                        : Image.file(
                                            media.file,
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
                                        DateFormat(
                                          'dd MMM, hh:mm a',
                                        ).format(media.timestamp),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2.h,
                                    right: 2.w,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => mediaSlots.removeAt(i),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return GestureDetector(
                              onTap: () => _pickMedia(i),
                              child: Container(
                                width: 90.w,
                                height: 90.w,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  color: Colors.grey.shade100,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey,
                                      size: 28.sp,
                                    ),
                                    SizedBox(height: 8.h),
                                    Icon(
                                      Icons.videocam,
                                      color: Colors.red,
                                      size: 24.sp,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      loc.photoNote,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 20.h),

                    Text(
                      loc.location,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10.r),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 20.sp,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  loc.autoDetectedLocation,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              address ??
                                  ((location == null ||
                                          location!.contains("Lat:"))
                                      ? loc.fetchingAddress
                                      : location!),
                              style: TextStyle(fontSize: 15.sp),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Icon(
                                  Icons.gps_fixed,
                                  size: 16.sp,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  gps != null && gps!.isNotEmpty
                                      ? loc.gpsCoordinates(gps!)
                                      : loc.fetchingGps,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: Icon(Icons.refresh, size: 16.sp),
                              label: Text(
                                loc.refresh,
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: _requestAndFetchLocation,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    Text(
                      loc.additionalDetails,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: detailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: loc.enterDetails,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        contentPadding: EdgeInsets.all(12.w),
                      ),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),

                    Row(
                      children: [
                        Icon(Icons.mic, color: Colors.grey, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _isRecording
                              ? Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        loc.recording,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: CircularProgressIndicator(
                                        color: Colors.red,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ],
                                )
                              : _isPlaying
                              ? Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        loc.playing,
                                        style: TextStyle(
                                          color: mainBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: CircularProgressIndicator(
                                        color: mainBlue,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _audioPath == null
                                      ? loc.recordVoiceNote
                                      : loc.voiceNoteRecorded,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13.sp,
                                  ),
                                ),
                        ),
                        if (!_isRecording && _audioPath == null)
                          IconButton(
                            icon: Icon(Icons.mic, color: mainBlue, size: 22.sp),
                            onPressed: _startRecording,
                          ),
                        if (_isRecording)
                          IconButton(
                            icon: Icon(
                              Icons.stop,
                              color: Colors.red,
                              size: 22.sp,
                            ),
                            onPressed: _stopRecording,
                          ),
                        if (!_isRecording && _audioPath != null)
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: mainBlue,
                                  size: 22.sp,
                                ),
                                onPressed: _isPlaying ? _stopAudio : _playAudio,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 22.sp,
                                ),
                                onPressed: _deleteVoiceNote,
                                tooltip: loc.deleteVoiceNote,
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 28.h),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid
                              ? mainBlue
                              : Colors.grey.shade300,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                        onPressed: _isFormValid && !_isSubmitting
                            ? _submitReport
                            : null,
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    loc.submitReport,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: navBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8.r,
                    offset: Offset(0, -2.h),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: navBg,
                currentIndex: 1,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: mainBlue,
                unselectedItemColor: Colors.grey,
                iconSize: 24.sp,
                selectedFontSize: 14.sp,
                unselectedFontSize: 13.sp,
                elevation: 0,
                showUnselectedLabels: true,
                onTap: (index) {
                  if (index == 0) {
                    final fullName = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).fullName;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  } else if (index == 2) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => MyReportsPage()),
                    );
                  } else if (index == 3) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(),
                      ),
                    );
                  }
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: 1 == 0 ? mainBlue.withOpacity(0.12) : null,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.home, color: Colors.grey, size: 24.sp),
                    ),
                    label: loc.home,
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: mainBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: mainBlue,
                        size: 24.sp,
                      ),
                    ),
                    label: loc.report,
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: 1 == 2 ? mainBlue.withOpacity(0.12) : null,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.list_alt,
                        color: Colors.grey,
                        size: 24.sp,
                      ),
                    ),
                    label: loc.complaints,
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: 1 == 3 ? mainBlue.withOpacity(0.12) : null,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 24.sp,
                      ),
                    ),
                    label: loc.profile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreviewDialog extends StatefulWidget {
  final File file;
  final DateTime timestamp;
  const _VideoPreviewDialog({required this.file, required this.timestamp});

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
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
          padding: EdgeInsets.all(8.w),
          child: Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(widget.timestamp),
            style: TextStyle(color: Colors.white, fontSize: 15.sp),
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
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
