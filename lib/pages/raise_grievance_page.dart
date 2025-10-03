import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
        title: Text(loc.raiseGrievance),
        backgroundColor: Colors.redAccent,
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
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: [
                  ..._photos.map(
                    (photo) => SizedBox(
                      width: 80.w,
                      height: 80.h,
                      child: Image.file(photo, fit: BoxFit.cover),
                    ),
                  ),
                  if (_photos.length < 3)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.add_a_photo,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.h),

              // --- Voice Note Section ---
              Text(
                loc.recordVoiceNote,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isRecording)
                      Text(
                        loc.recording,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!_isRecording && _audioPath == null)
                      Text(loc.addNotesHint),
                    if (!_isRecording && _audioPath != null)
                      Text(loc.voiceNoteRecorded),
                    if (_isRecording)
                      IconButton(
                        icon: Icon(Icons.stop, color: Colors.red),
                        onPressed: _stopRecording,
                      ),
                    if (!_isRecording && _audioPath == null)
                      IconButton(
                        icon: Icon(Icons.mic, color: Colors.blue),
                        onPressed: _startRecording,
                      ),
                    if (!_isRecording && _audioPath != null)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.blue,
                            ),
                            onPressed: _isPlaying ? _stopAudio : _playAudio,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: _deleteVoiceNote,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),

              // --- Submit Button ---
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitGrievance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        loc.submit,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
