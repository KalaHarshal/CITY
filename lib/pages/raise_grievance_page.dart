import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'report_details_page.dart'; // Import the report details page

class RaiseGrievancePage extends StatefulWidget {
  final String complaintId;
  const RaiseGrievancePage({super.key, required this.complaintId});

  @override
  State<RaiseGrievancePage> createState() => _RaiseGrievancePageState();
}

class _RaiseGrievancePageState extends State<RaiseGrievancePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  // Media and Audio State
  List<File> _photos = [];
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_photos.length >= 3) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );
    if (pickedFile != null) {
      setState(() {
        _photos.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final tempDir = await getTemporaryDirectory();
    _audioPath = '${tempDir.path}/grievance_audio.aac';
    await _recorder!.startRecorder(toFile: _audioPath);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() => _isRecording = false);
  }

  Future<void> _playAudio() async {
    if (_audioPath == null) return;
    await _player!.startPlayer(
      fromURI: _audioPath,
      whenFinished: () {
        setState(() => _isPlaying = false);
      },
    );
    setState(() => _isPlaying = true);
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
      _isRecording = false;
      _isPlaying = false;
    });
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitGrievance() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // 1. Upload Photos
      List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        final url = await _uploadFile(
          _photos[i],
          'grievances/${widget.complaintId}/photo_$i.jpg',
        );
        if (url != null) photoUrls.add(url);
      }

      // 2. Upload Voice Note
      String? voiceNoteUrl;
      if (_audioPath != null) {
        voiceNoteUrl = await _uploadFile(
          File(_audioPath!),
          'grievances/${widget.complaintId}/voice_note.aac',
        );
      }

      // 3. Prepare data for Realtime Database
      final grievanceData = {
        'reason': _reasonController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Pending',
        if (photoUrls.isNotEmpty) 'photos': photoUrls,
        if (voiceNoteUrl != null) 'voiceNote': voiceNoteUrl,
      };

      // 4. Update Database
      await FirebaseDatabase.instance
          .ref()
          .child('complaints')
          .child(widget.complaintId)
          .update({
            'grievance': grievanceData,
            // The 'status' field is no longer changed
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.grievanceSubmittedSuccess,
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to the report details page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ReportDetailsPage(complaintId: widget.complaintId),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit grievance: $e')));
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          loc.raiseGrievance,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Reason Text Field ---
              Text(
                loc.grievanceReason,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: loc.grievanceHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                maxLines: 5,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? loc.reasonRequired : null,
              ),
              SizedBox(height: 20.h),

              // --- Photo Upload Section ---
              Text(
                loc.photos,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 90.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 1,
                  separatorBuilder: (_, __) => SizedBox(width: 10.w),
                  itemBuilder: (context, i) {
                    if (_photos.isNotEmpty) {
                      final photo = _photos.first;
                      final photoTimestamp = File(
                        photo.path,
                      ).lastModifiedSync();
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.black,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.file(photo),
                                  Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: Text(
                                      DateFormat(
                                        'dd MMM yyyy, hh:mm a',
                                      ).format(photoTimestamp),
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
                                      AppLocalizations.of(context)!.close,
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
                              child: Image.file(
                                photo,
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
                                  ).format(photoTimestamp),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2.h,
                              right: 2.w,
                              child: GestureDetector(
                                onTap: () => setState(() => _photos.clear()),
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
                        onTap: _pickImage,
                        child: Container(
                          width: 90.w,
                          height: 90.w,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.grey.shade100,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                            size: 32.sp,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 6.h),

              SizedBox(height: 20.h),

              // --- Voice Note Section ---
              Text(
                loc.recordVoiceNote,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
              ),
              SizedBox(height: 8.h),
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
                                    color: Colors.redAccent,
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
                                  color: Colors.redAccent,
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
                      icon: Icon(
                        Icons.mic,
                        color: Colors.redAccent,
                        size: 22.sp,
                      ),
                      onPressed: _startRecording,
                    ),
                  if (_isRecording)
                    IconButton(
                      icon: Icon(Icons.stop, color: Colors.red, size: 22.sp),
                      onPressed: _stopRecording,
                    ),
                  if (!_isRecording && _audioPath != null)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.redAccent,
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

              // --- Submit Button ---
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitGrievance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            loc.submit,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
