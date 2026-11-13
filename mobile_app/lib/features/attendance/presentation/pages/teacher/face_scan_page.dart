import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'face_embedding_helper.dart';
import 'mobile_facenet_service.dart'; // 🟢 Import Service AI MobileFaceNet

enum _NoticeType { success, warning, error, info }

class _ScanNotice {
  final _NoticeType type;
  final String title;
  final String? subtitle;
  final double? percent;

  const _ScanNotice({
    required this.type,
    required this.title,
    this.subtitle,
    this.percent,
  });
}

class FaceScanPage extends StatefulWidget {
  final String tripId;
  final String routeName;
  final String stopName;
  final ValueNotifier<String>? directionNotifier;

  const FaceScanPage({
    super.key,
    this.tripId = 'd8db7cc2-4dc4-448d-ad6b-7b8dddd48270',
    this.routeName = 'Tuyến 05',
    this.stopName = '12 Lê Duẩn',
    this.directionNotifier,
  });

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = true;
  bool _isProcessingAI = false;
  _ScanNotice? _notice;
  Timer? _noticeTimer;  
  bool _busy = false;


  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: true,
      enableClassification: false,
    ),
  );

  // 🟢 Service AI MobileFaceNet
  final MobileFaceNetService _faceNetService = MobileFaceNetService();

  Map<String, dynamic>? _scannedStudent;
  int _boardedCount = 0;
  int _totalCount = 0;

  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initCamera();
    _fetchTripStats();
    _direction.addListener(_onDirectionChanged);
    _faceNetService.loadModel().catchError((e) => debugPrint('🔴 Lỗi nạp model: $e'));
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Widget _modeButton(String value, String label, Color color) {
    final selected = _direction.value == value;
    final locked = _isProcessingAI || _scannedStudent != null;
    return Expanded(
      child: GestureDetector(
        onTap: locked ? null : () => _direction.value = value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
  late final ValueNotifier<String> _direction =
      widget.directionNotifier ?? ValueNotifier<String>('PICKUP');
  bool get _isDropoff => _direction.value == 'DROPOFF';

  void _onDirectionChanged() {
    if (!mounted) return;
    setState(() {});
    _fetchTripStats(); // đổi chế độ thì đếm lại cho đúng
  }
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final camera = _cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
          _startLiveFaceDetection();
        }
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo Camera: $e');
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameraController!.description.sensorOrientation;
    final InputImageRotation? rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final InputImageFormat? format =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _startLiveFaceDetection() {
    final cam = _cameraController;
    if (cam == null || !cam.value.isInitialized) return;
    if (cam.value.isStreamingImages) return;
    _busy = false;

    cam.startImageStream((CameraImage image) async {
      if (!_isScanning || _busy || !mounted) return;
      _busy = true; // khóa ngay trước mọi await

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) { _busy = false; return; }

        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isEmpty || !mounted) { _busy = false; return; }

        setState(() => _isProcessingAI = true);
        await _stopLiveFaceDetection();
        if (!mounted) return;

        final XFile pic = await _cameraController!.takePicture();
        await _processMobileFaceNetMatching(pic.path, faces.first);
      } catch (e) {
        debugPrint('Lỗi ML Kit: $e');
        _busy = false;
        if (mounted) {
          setState(() => _isProcessingAI = false);
          _startLiveFaceDetection();
        }
      }
    });
  }

  Future<void> _processMobileFaceNetMatching(String imagePath, Face face) async {
    try {
      // 🟢 1. Trích xuất Vector Embedding 192 chiều từ mô hình AI MobileFaceNet
      final List<double> liveEmbedding = await _faceNetService.extractEmbedding(imagePath, face);
      final String mode = _isDropoff ? 'DROPOFF' : 'PICKUP';

      if (liveEmbedding.isEmpty) {
        debugPrint('❌ Không trích xuất được vector AI từ khuôn mặt quét.');
        if (mounted) setState(() => _isProcessingAI = false);
        _startLiveFaceDetection();
        return;
      }

      // 2. Truy vấn tất cả học sinh trong chuyến xe
      final allStudentsInTrip = await _supabase
          .from('attendance')
          .select('''
            attendance_id,
            status,
            students!inner (
              student_id,
              student_code,
              full_name,
              class_name,
              avatar_url,
              face_embeddings (
                embedding_data,
                is_active
              )
            )
          ''')
          .eq('trip_id', widget.tripId);

      final List listData = allStudentsInTrip as List;

      if (!mounted || _scannedStudent != null) return;
      
      if (listData.isEmpty) {
        _showNotice(const _ScanNotice(
          type: _NoticeType.info,
          title: 'Chưa có danh sách học sinh',
          subtitle: 'Chuyến xe này chưa có dữ liệu điểm danh',
        ));
        if (mounted) setState(() { _isScanning = false; _isProcessingAI = false; });
        return;
      }

      Map<String, dynamic>? bestMatch;
      double highestSimilarity = -1.0;

      debugPrint('=== 🔍 BẮT ĐẦU SO KHỚP MÔ HÌNH AI MOBILEFACENET (192 CHIỀU) ===');

      for (var record in listData) {
        final studentData = record['students'] as Map<String, dynamic>;
        final String studentName = studentData['full_name'] ?? 'Học sinh';
        final embeddingsList = studentData['face_embeddings'] as List<dynamic>?;

        if (embeddingsList != null && embeddingsList.isNotEmpty) {
          final dbEmbeddingRaw = embeddingsList.first['embedding_data'];

          if (dbEmbeddingRaw != null) {
            try {
              final List<double> dbEmbedding = FaceEmbeddingHelper.bytesToFloat32List(dbEmbeddingRaw);
              
              // Tính độ tương đồng Cosine
              double similarity = FaceEmbeddingHelper.calculateCosineSimilarity(liveEmbedding, dbEmbedding);

              final double percentScore = (similarity * 100).clamp(0.0, 100.0);
              debugPrint('👤 Học sinh: $studentName | AI Similarity: ${similarity.toStringAsFixed(4)} (${percentScore.toStringAsFixed(1)}%)');

              if (similarity > highestSimilarity) {
                highestSimilarity = similarity;
                bestMatch = {
                  'attendance_id': record['attendance_id'],
                  'status': record['status'],
                  'student_data': studentData,
                  'similarity': similarity,
                };
              }
            } catch (e) {
              debugPrint('❌ Lỗi giải mã vector của $studentName: $e');
            }
          }
        } else {
          debugPrint('⚠️ Học sinh $studentName chưa đăng ký khuôn mặt AI.');
        }
      }

      final double matchPercent = (highestSimilarity * 100).clamp(0.0, 100.0);
      debugPrint('🏆 KẾT QUẢ TỐT NHẤT: ${bestMatch?['student_data']['full_name']} với điểm AI ${highestSimilarity.toStringAsFixed(4)} (${matchPercent.toStringAsFixed(1)}%)');
      debugPrint('====================================================');

      // 🟢 3. Ngưỡng chấp nhận khớp chuẩn mô hình MobileFaceNet AI (Đặt 0.65 = 65%)
      const double matchingThreshold = 0.65;

      if (bestMatch != null && highestSimilarity >= matchingThreshold) {
        final String currentStatus = bestMatch['status'];
        final studentData = bestMatch['student_data'] as Map<String, dynamic>;
        final String studentName = studentData['full_name'] ?? 'Học sinh';

        String? blockMsg;
        if (mode == 'DROPOFF') {
          if (currentStatus == 'ALIGHTED') {
            blockMsg = 'Đã xuống xe trước đó';
          } else if (currentStatus == 'ABSENT') {
            blockMsg = 'Học sinh nghỉ phép, không có trên xe';
          } else if (currentStatus != 'BOARDED') {
            blockMsg = 'Chưa lên xe, không thể điểm danh xuống xe';
          }
        } else {
          if (currentStatus == 'BOARDED') {
            blockMsg = 'Đã lên xe trước đó';
          } else if (currentStatus == 'ALIGHTED') {
            blockMsg = 'Đã xuống xe, chuyến của em đã hoàn tất';
          } else if (currentStatus == 'ABSENT') {
            blockMsg = 'Học sinh nghỉ phép hôm nay';
          }
        }

        if (blockMsg != null) {
          _showNotice(_ScanNotice(
            type: _NoticeType.warning,
            title: studentName,
            subtitle: blockMsg,
            percent: matchPercent,
          ));
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            setState(() => _isProcessingAI = false);
            _startLiveFaceDetection();
          }
          return;
        }

        final checkInTime = DateTime.now();
        if (mounted) {
          setState(() {
            _noticeTimer?.cancel();
            _notice = null;

            _isScanning = false;
            _isProcessingAI = false;
            _scannedStudent = {
              'attendance_id': bestMatch!['attendance_id'],
              'name': studentName,
              'class': studentData['class_name'] ?? '',
              'avatar_url': studentData['avatar_url'],
              'time': "${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}",
              'confidence': "${matchPercent.toStringAsFixed(1)}%",
              'similarity_score': highestSimilarity,
              'stop': widget.stopName,
              'mode': mode,
              'check_in_time_raw': checkInTime.toIso8601String(),
            };
          });
          _showSuccessBottomSheet();
        }
      } else {
        _showNotice(_ScanNotice(
          type: _NoticeType.error,
          title: 'Không nhận diện được',
          subtitle: 'Khuôn mặt chưa khớp với học sinh nào trong chuyến',
          percent: highestSimilarity > 0 ? matchPercent : null,
        ));
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessingAI = false);
          _startLiveFaceDetection();
        }
      }
    } catch (e) {
      debugPrint('Lỗi so sánh AI: $e');
      if (mounted) setState(() => _isProcessingAI = false);
    } finally {
      // Xóa file ảnh tạm sau khi trích xuất
      try {
        final file = File(imagePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
  void _showNotice(
    _ScanNotice n, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    _noticeTimer?.cancel();
    setState(() => _notice = n);
    _noticeTimer = Timer(duration, () {
      if (mounted) setState(() => _notice = null);
    });
  }

  Widget _buildNoticeCard(_ScanNotice n) {
    final (Color main, Color soft, IconData icon) = switch (n.type) {
      _NoticeType.success => (
          const Color(0xFF15803D), const Color(0xFFDCFCE7), Icons.check_circle_rounded),
      _NoticeType.warning => (
          const Color(0xFFB45309), const Color(0xFFFEF3C7), Icons.info_rounded),
      _NoticeType.error => (
          const Color(0xFFB91C1C), const Color(0xFFFEE2E2), Icons.cancel_rounded),
      _NoticeType.info => (
          const Color(0xFF1D4ED8), const Color(0xFFDBEAFE), Icons.info_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
            child: Icon(icon, color: main, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  n.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (n.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    n.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
          if (n.percent != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${n.percent!.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: main,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _fetchTripStats() async {
    try {
      final res = await _supabase
          .from('attendance')
          .select('status')
          .eq('trip_id', widget.tripId);

      final total = res.length;
      final boarded = res.where((e) => e['status'] == 'BOARDED').length;
      final alighted = res.where((e) => e['status'] == 'ALIGHTED').length;

      if (mounted) {
        setState(() {
          _totalCount = total;
          _boardedCount = _isDropoff ? alighted : boarded + alighted;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thống kê: $e');
    }
  }

  Future<void> _confirmAndScanNext() async {
    if (_scannedStudent == null) return;

    try {
      final String attendanceId = _scannedStudent!['attendance_id'];
      final String checkInTimeRaw = _scannedStudent!['check_in_time_raw'];
      final double confidenceScore = _scannedStudent!['similarity_score'] ?? 0.95;

      final bool dropoff = _scannedStudent!['mode'] == 'DROPOFF';
      final double conf = double.parse(
        confidenceScore.clamp(0.0, 1.0).toStringAsFixed(4),
      );

      await _supabase.from('attendance').update({
        'status': dropoff ? 'ALIGHTED' : 'BOARDED',
        'detection_method': 'AI',
        'ai_confidence': conf,
        if (dropoff) 'check_out_time': checkInTimeRaw else 'check_in_time': checkInTimeRaw,
        'recorded_by': _supabase.auth.currentUser?.id,
      }).eq('attendance_id', attendanceId);

      await _fetchTripStats();

      setState(() {
        _scannedStudent = null;
        _isScanning = true;
        _isProcessingAI = false;
      });

      _startLiveFaceDetection();
    } catch (e) {
      debugPrint('Lỗi ghi nhận điểm danh: $e');
    }
  }

  Future<void> _stopLiveFaceDetection() async {
    if (_cameraController != null && 
        _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (e) {
        debugPrint('Lỗi ngắt camera stream: $e');
      }
    }
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFDBEAFE),
                    backgroundImage: _scannedStudent!['avatar_url'] != null
                        ? NetworkImage(_scannedStudent!['avatar_url'])
                        : null,
                    child: _scannedStudent!['avatar_url'] == null
                        ? Text(
                            _getInitials(_scannedStudent!['name']),
                            style: const TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scannedStudent!['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_scannedStudent!['class']} · điểm đón ${_scannedStudent!['stop']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Khớp ${_scannedStudent!['confidence']}',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF166534), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_scannedStudent!['mode'] == 'DROPOFF' ? 'Xác nhận xuống xe' : 'Xác nhận lên xe'} lúc ${_scannedStudent!['time']}',
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmAndScanNext();
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  label: const Text(
                    'Quét học sinh tiếp theo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.front_hand, size: 16, color: Colors.black87),
                  label: const Text(
                    'Không đúng? Chọn thủ công',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _faceNetService.close(); // 🟢 Giải phóng bộ nhớ mô hình AI
    _faceDetector.close();
    _animationController.dispose();
    _cameraController?.dispose();
    _direction.removeListener(_onDirectionChanged);
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final cameraAreaHeight = screenHeight * 0.58;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isDropoff
                            ? 'Điểm danh xuống xe (AI MobileFaceNet)'
                            : 'Điểm danh lên xe (AI MobileFaceNet)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.stopName} · ${widget.routeName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_boardedCount/$_totalCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _modeButton('PICKUP', 'LÊN XE', const Color(0xFF2563EB)),
                  _modeButton('DROPOFF', 'XUỐNG XE', const Color(0xFFDC2626)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: cameraAreaHeight,
              width: screenWidth - 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF1E293B),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _isCameraInitialized && _cameraController != null
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize?.height ?? screenWidth,
                              height: _cameraController!.value.previewSize?.width ?? cameraAreaHeight,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(color: Colors.blueAccent),
                          ),

                    CustomPaint(
                      painter: ScannerOverlayPainter(
                        isSuccess: _scannedStudent != null,
                        scanProgress: _scanAnimation.value,
                        isScanning: _isScanning,
                      ),
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _notice == null
                            ? const SizedBox.shrink(key: ValueKey('no-notice'))
                            : KeyedSubtree(
                                key: ValueKey(identityHashCode(_notice)),
                                child: _buildNoticeCard(_notice!),
                              ),
                      ),
                    ),

                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.psychology, color: Colors.greenAccent, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'AI MobileFaceNet · Offline',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.black.withOpacity(0.65),
                            child: const Icon(Icons.flash_on, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return 'HS';
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final bool isSuccess;
  final double scanProgress;
  final bool isScanning;

  ScannerOverlayPainter({
    required this.isSuccess,
    required this.scanProgress,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.48);
    final ovalWidth = size.width * 0.58;
    final ovalHeight = size.height * 0.52;
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path ovalPath = Path()..addOval(ovalRect);

    final Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      ovalPath,
    );

    final paintOverlay = Paint()
      ..color = Colors.black.withOpacity(0.40)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, paintOverlay);

    final paintBorder = Paint()
      ..color = isSuccess ? const Color(0xFF22C55E) : const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawOval(ovalRect, paintBorder);

    if (isScanning && !isSuccess) {
      final laserY = ovalRect.top + (ovalRect.height * scanProgress);
      final laserPaint = Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 3.0;

      canvas.drawLine(
        Offset(ovalRect.left + 15, laserY),
        Offset(ovalRect.right - 15, laserY),
        laserPaint,
      );
    }

    final paintCorner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final marginX = ovalWidth * 0.72;
    final marginY = ovalHeight * 0.62;
    const cornerLength = 24.0;

    // Top-Left
    canvas.drawLine(
      Offset(center.dx - marginX, center.dy - marginY + cornerLength),
      Offset(center.dx - marginX, center.dy - marginY),
      paintCorner,
    );
    canvas.drawLine(
      Offset(center.dx - marginX, center.dy - marginY),
      Offset(center.dx - marginX + cornerLength, center.dy - marginY),
      paintCorner,
    );

    // Top-Right
    canvas.drawLine(
      Offset(center.dx + marginX - cornerLength, center.dy - marginY),
      Offset(center.dx + marginX, center.dy - marginY),
      paintCorner,
    );
    canvas.drawLine(
      Offset(center.dx + marginX, center.dy - marginY),
      Offset(center.dx + marginX, center.dy - marginY + cornerLength),
      paintCorner,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(center.dx - marginX, center.dy + marginY - cornerLength),
      Offset(center.dx - marginX, center.dy + marginY),
      paintCorner,
    );
    canvas.drawLine(
      Offset(center.dx - marginX, center.dy + marginY),
      Offset(center.dx - marginX + cornerLength, center.dy + marginY),
      paintCorner,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(center.dx + marginX - cornerLength, center.dy + marginY),
      Offset(center.dx + marginX, center.dy + marginY),
      paintCorner,
    );
    canvas.drawLine(
      Offset(center.dx + marginX, center.dy + marginY),
      Offset(center.dx + marginX, center.dy + marginY - cornerLength),
      paintCorner,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.isSuccess != isSuccess;
  }
}