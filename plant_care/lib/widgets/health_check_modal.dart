import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show FontFeature;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:plant_care/services/health_check_service.dart';
import 'package:plant_care/utils/cloud_functions.dart';
import 'package:http/http.dart' as http;

import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/utils/web_file_picker.dart';
import 'package:plant_care/utils/care_sections.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/health_result_view.dart';
import 'package:uuid/uuid.dart';

enum HealthCheckAnalysisMode { aiCare, aiAgent }

/// The sheet stays mounted across all three; closing between them would throw
/// away the analysis the user just paid for.
enum _Step { upload, running, result }

class HealthCheckModal extends StatefulWidget {
  final String plantId;
  final String plantName;
  final Function(Map<String, dynamic>) onHealthCheckComplete;
  final HealthCheckAnalysisMode analysisMode;

  /// Whether the result step offers "Ask assistant". The modal has no route to
  /// the chat: it pops with its record, and the host takes it from there, which
  /// is what lets the host bring the user back here afterwards (SPEC 1.4).
  final bool canAskAssistant;

  const HealthCheckModal({
    Key? key,
    required this.plantId,
    required this.plantName,
    required this.onHealthCheckComplete,
    this.analysisMode = HealthCheckAnalysisMode.aiAgent,
    this.canAskAssistant = true,
  }) : super(key: key);

  @override
  State<HealthCheckModal> createState() => _HealthCheckModalState();
}

class _HealthCheckModalState extends State<HealthCheckModal>
    with TickerProviderStateMixin {
  // 3 slots: index 0 = required, 1 & 2 = optional
  final List<Uint8List?> _slots = [null, null, null];

  bool _isAnalyzing = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  _Step _step = _Step.upload;

  /// Built when the analysis returns and written straight away — SPEC 3.4 has no
  /// "save to history" step, so the sheet can be abandoned without losing it.
  HealthCheckRecord? _result;
  Map<String, dynamic>? _rawResult;
  bool _isSaving = false;
  bool _isSaved = false;

  /// Set when the automatic write failed. The analysis is still on screen and
  /// still in memory, so the result step offers a retry rather than swallowing
  /// a check the user has already paid for.
  bool _saveFailed = false;

  // Per-slot fill animations
  late final List<AnimationController> _fillControllers;
  late final List<Animation<double>> _fillAnimations;

  @override
  void initState() {
    super.initState();
    _fillControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );
    _fillAnimations = _fillControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _fillControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  String get _analysisModeKey =>
      widget.analysisMode == HealthCheckAnalysisMode.aiCare ? 'ai_care' : 'ai_agent';

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  int get _filledCount => _slots.where((b) => b != null).length;
  bool get _canAnalyze => _slots[0] != null && !_isAnalyzing;

  // ─── image picking ────────────────────────────────────────────────────────

  void _pickForSlot(int slotIndex) {
    if (_isAnalyzing) return;
    setState(() => _errorMessage = null);
    if (_isMobile) {
      _showNativeSheet(slotIndex);
    } else {
      _pickWebForSlot(slotIndex);
    }
  }

  Future<void> _showNativeSheet(int slotIndex) async {
    final l10n = AppLocalizations.of(context)!;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickFromSource(slotIndex, ImageSource.camera);
            },
            child: Text(l10n.camera),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickFromSource(slotIndex, ImageSource.gallery);
            },
            child: Text(l10n.gallery),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Future<void> _pickWebForSlot(int slotIndex) async {
    final bytes = await pickCenteredImageFromWeb();
    if (bytes != null && mounted) {
      _setSlot(slotIndex, bytes);
    }
  }

  Future<void> _pickFromSource(int slotIndex, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        _setSlot(slotIndex, bytes);
      }
    } catch (e) {
      if (mounted) {
        final message = AppLocalizations.of(context)!.errorPickingImage('$e');
        setState(() => _errorMessage = message);
      }
    }
  }

  void _setSlot(int index, Uint8List bytes) {
    setState(() => _slots[index] = bytes);
    _fillControllers[index].forward(from: 0);
  }

  void _clearSlot(int index) {
    setState(() => _slots[index] = null);
    _fillControllers[index].reverse();
  }

  // ─── analysis ─────────────────────────────────────────────────────────────

  Future<void> _analyzeHealth() async {
    if (!_canAnalyze) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _step = _Step.running;
    });

    try {
      final nonNullSlots = _slots.where((b) => b != null).cast<Uint8List>().toList();
      final base64Images = nonNullSlots.map(base64Encode).toList();

      final response = await _callChatGPT(base64Images);

      if (response != null && response['status'] != 'error') {
        final metadata = <String, dynamic>{
          'analysisTimestamp': DateTime.now().toIso8601String(),
          'analysisMode': response['analysisMode'] ?? _analysisModeKey,
          'photoCount': nonNullSlots.length,
        };
        if (response['agent'] is Map) {
          final agent = Map<String, dynamic>.from(response['agent'] as Map);
          metadata['retryCount'] = agent['attemptsUsed'];
          metadata['previousImagesUsed'] = agent['previousImagesUsed'];
          metadata['agentContext'] = agent['context'];
        }
        if (response['amount_ml'] != null) {
          metadata['recommendedAmountMl'] = response['amount_ml'];
        }
        if (response['watering_amount'] != null) {
          metadata['watering_amount'] = response['watering_amount'];
        }

        final healthCheckRecord = HealthCheckRecord(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          status: response['status'],
          message: response['message'],
          imageBytesList: _slots.toList(),
          metadata: metadata,
          score: _asInt(response['health_score']),
          findings: _parseList(response['findings'], HealthFinding.fromMap),
          recommendations:
              _parseList(response['recommendations'], HealthRecommendation.fromMap),
        );

        if (!mounted) return;
        setState(() {
          _errorMessage = null;
          _result = healthCheckRecord;
          _rawResult = Map<String, dynamic>.from(response);
          _step = _Step.result;
        });
        // "Готово" is the moment of readiness, not a later tap: the check lands
        // in history, the chip flips and the recommendations become plan tasks
        // while the user is still reading the result (SPEC 3.4).
        await _saveResult();
      } else {
        // Show localized error inside modal — photos stay loaded, button re-enables
        if (mounted) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.healthCheckError;
            _step = _Step.upload;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.healthCheckError;
          _step = _Step.upload;
        });
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  static int? _asInt(dynamic v) =>
      v is int ? v : (v == null ? null : int.tryParse(v.toString()));

  static List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) build) {
    if (raw is! List) return const [];
    final out = <T>[];
    for (final item in raw) {
      if (item is Map) out.add(build(Map<String, dynamic>.from(item)));
    }
    return out;
  }

  /// Commits the analysis: uploads the photos, writes the check, then lets the
  /// plant screen fold the result into the plant and its plan.
  ///
  /// Runs by itself the moment the result is ready and stays open afterwards —
  /// the sheet is now a place to read, not a place to confirm.
  Future<void> _saveResult() async {
    final record = _result;
    if (record == null || _isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    try {
      await HealthCheckService().addHealthCheck(widget.plantId, record);
      if (!mounted) return;

      final payload = Map<String, dynamic>.from(_rawResult ?? {});
      payload['imageBytes'] = _slots[0];
      widget.onHealthCheckComplete(payload);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
    }
  }

  Future<Map<String, dynamic>?> _callChatGPT(List<String> base64Images) async {
    try {
      final bool isAgentMode = widget.analysisMode == HealthCheckAnalysisMode.aiAgent;
      final String endpointUrl =
          isAgentMode ? analyzeHealthCheckAgentUrl : analyzePlantPhotoUrl;

      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // Send array for multi-photo; single string for legacy AI Care endpoint
          if (isAgentMode) 'base64Images': base64Images,
          if (!isAgentMode) 'base64Image': base64Images.first,
          'language': LanguageService.localeNotifier.value.languageCode,
          if (isAgentMode) ...{
            'plantId': widget.plantId,
            'plantName': widget.plantName,
            'userId': FirebaseAuth.instance.currentUser?.uid,
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final agentInfo = result['agent'];

        final recommendationsRaw = result['recommendations'];
        final recommendations = recommendationsRaw is Map
            ? Map<String, dynamic>.from(recommendationsRaw as Map)
            : <String, dynamic>{};

        final plantSize = recommendations['plant_size'] ?? result['plant_size'];
        final potSize = recommendations['pot_size'] ?? result['pot_size'];
        final growthStage = recommendations['growth_stage'] ?? result['growth_stage'];
        final moistureLevel = recommendations['moisture_level'] ?? result['moisture_level'];
        final light = recommendations['light'] ?? result['light'];
        final careTips = recommendations['care_tips'];
        final interestingFacts = recommendations['interesting_facts'];
        // The agent re-derives full care guidance on every check, so a plant
        // created before the analyzer returned structured details picks them up
        // here without a full re-analysis.
        final careRecommendations = recommendations['care_recommendations'];
        final careDetails = extractCareDetails(careRecommendations);

        final wateringPlanRaw = recommendations['watering_plan'];
        final wateringPlan = wateringPlanRaw is Map
            ? Map<String, dynamic>.from(wateringPlanRaw as Map)
            : <String, dynamic>{};
        final wateringIntervalDays = wateringPlan['next_watering_in_days'];
        final shouldWaterNow = wateringPlan['should_water_now'] as bool?;
        final reasonShort = wateringPlan['reason_short'] as String?;
        final wateringAmountMl = wateringPlan['amount_ml'] ?? recommendations['amount_ml'];
        final wateringRangeMl = recommendations['range_ml'];
        final nextAfterWateringHours = recommendations['next_after_watering_in_hours'];
        final nextCheckHours = recommendations['next_check_in_hours'];
        final wateringMode = recommendations['mode'];
        final wateringAmountText = recommendations['watering_amount'];
        final rawResponse = result['rawResponse'] ?? result['message'] ?? '';

        // Determine health status
        String status = 'ok';
        final lowerResponse = rawResponse.toLowerCase();
        final plantAssistantRaw = recommendations['plant_assistant'];
        final Map<String, dynamic>? plantAssistant = plantAssistantRaw is Map
            ? Map<String, dynamic>.from(plantAssistantRaw as Map)
            : null;

        if (plantAssistant != null && plantAssistant['status'] != null) {
          final paStatus = plantAssistant['status'].toString().toLowerCase();
          if (paStatus == 'issue_detected') status = 'issue';
          else if (paStatus == 'healthy') status = 'ok';
        } else {
          // Heuristic fallback
          if (lowerResponse.contains('appears healthy') ||
              lowerResponse.contains('no signs of') ||
              lowerResponse.contains('no issues')) {
            status = 'ok';
          } else if (lowerResponse.contains('health issues') ||
              lowerResponse.contains('disease') ||
              lowerResponse.contains('rot')) {
            status = 'issue';
          }
        }

        final String messageForStorage = plantAssistant != null
            ? jsonEncode(plantAssistant)
            : rawResponse;

        return {
          'status': status,
          'message': messageForStorage,
          'health_score': recommendations['health_score'],
          'findings': recommendations['findings'],
          'recommendations': recommendations['recommendations'],
          'analysisMode': _analysisModeKey,
          'plant_assistant': plantAssistant,
          'plant_size': plantSize,
          'pot_size': potSize,
          'growth_stage': growthStage,
          'moisture_level': moistureLevel,
          'light': light,
          'care_tips': careTips,
          'care_recommendations': careRecommendations,
          'care_details': careDetails,
          'interesting_facts': interestingFacts,
          'amount_ml': wateringAmountMl,
          'range_ml': wateringRangeMl,
          'next_after_watering_in_hours': nextAfterWateringHours,
          'next_check_in_hours': nextCheckHours,
          'mode': wateringMode,
          'watering_amount': wateringAmountText,
          'watering_interval_days': wateringIntervalDays,
          'should_water_now': shouldWaterNow,
          'reason_short': reasonShort,
          'agent': agentInfo,
        };
      } else {
        throw Exception('Firebase Function failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Health check CF call failed: $e');
      return null;
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final media = MediaQuery.of(context);

    // Bottom-anchored sheet, not a centred dialog: only `max-height` is set, so
    // short steps hug their content and the CTA stays within thumb reach
    // instead of floating mid-screen. Scrolling starts only once the content
    // genuinely outgrows the cap.
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          // Full-bleed: the sheet spans the whole screen width, as in the mockup.
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: media.size.height * 0.94),
          decoration: const BoxDecoration(
            // Light neutral, not pure white: every card inside is white, and on
            // a white sheet they vanish.
            color: Color(0xFFF6F8F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                color: Color(0x66142010),
                blurRadius: 50,
                spreadRadius: -18,
                offset: Offset(0, -20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── grabber ──
              Container(
                width: 38,
                height: 5,
                margin: const EdgeInsets.only(top: 10, bottom: 2),
                decoration: BoxDecoration(
                  color: const Color(0x29141E0F),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // ── header ──
              _buildHeader(l10n),

              // ── scrollable body ──
              // `Flexible`, not `Expanded`: the sheet must shrink to its content
              // when the step is short, and only scroll once it hits the cap.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      if (_step == _Step.upload) ...[
                        _buildHint(l10n),
                        const SizedBox(height: 14),
                        _buildSlots(l10n),
                      ] else if (_step == _Step.running)
                        _buildRunning(l10n)
                      else ...[
                        if (_saveFailed) _buildSaveRetry(l10n),
                        HealthResultView(
                          record: _result!,
                          onClose: () => Navigator.of(context).pop(),
                          onAsk: widget.canAskAssistant
                              ? () => Navigator.of(context).pop(_result)
                              : null,
                        ),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // ── footer ──
              // The result step carries its own actions inside HealthResultView.
              if (_step != _Step.result) _buildFooter(l10n),
              // The footer brings its own 20 px; the result step has no footer,
              // so its buttons would otherwise sit flush against the sheet edge.
              // The safe-area inset is zero on web, which is where that showed.
              SizedBox(
                height: (_step == _Step.result ? 22.0 : 0.0) + media.padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown on the result step when the automatic write did not go through.
  ///
  /// It says the check is not in history yet rather than pretending otherwise:
  /// closing now really does lose it, and the tap here is the way back.
  Widget _buildSaveRetry(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kGlassWarm.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGlassWarm.withAlpha(66), width: 0.5),
      ),
      child: Row(
        children: [
          const BotanlyGlyph(
            BotanlySvg.warningTriangle,
            size: 17,
            color: kGlassWarm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.healthNotSavedYet,
              style: glassFont(fontSize: 13, color: kGlassWarm),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSaving ? null : _saveResult,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.retry,
                style: glassFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _isSaving ? kGlassWarm.withAlpha(120) : kGlassWarm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2. The step list is cosmetic — it advances on a timer while the real
  /// request runs, and the sheet leaves this step only when the response lands.
  Widget _buildRunning(AppLocalizations l10n) {
    final photoCount = _slots.where((b) => b != null).length;
    final steps = <String>[
      l10n.healthStepPhotos(photoCount),
      l10n.healthStepRecognize,
      l10n.healthStepCompare,
      l10n.healthStepAdvice,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_slots[0] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: _ScanningPreview(image: _slots[0]!),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            l10n.healthAnalyzingTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: kGlassInk,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _AnalysisStepRow(label: steps[i], order: i),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 14, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kGlassLeafBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const BotanlyGlyph(BotanlySvg.scan, size: 21, color: kGlassAccent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.healthAnalyzeCta,
                  style: glassFont(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 21 * -0.03,
                    color: kGlassInk,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGlassAccent.withAlpha(46), // .18
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _step == _Step.result
                        ? l10n.healthResultTitle
                        : l10n.healthUpToThreePhotos,
                    style: glassFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kGlassGreenText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 32 px visual, 44 px hit area.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0x12141E0F), // rgba(20,30,15,.07)
                  shape: BoxShape.circle,
                ),
                child: const BotanlyGlyph(BotanlySvg.close, size: 15, color: kGlassMut),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14141E0F), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BotanlyGlyph(BotanlySvg.bulb, size: 17, color: kGlassAccent),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              l10n.healthCheckPhotoHint,
              style: glassFont(fontSize: 13, height: 1.4, color: kGlassInk2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.healthCheckPhotoCounter(_filledCount),
            style: glassFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: kGlassGreenText,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _buildSlots(AppLocalizations l10n) {
    final slotData = [
      (l10n.healthCheckSlot1Title, l10n.healthCheckSlot1Desc, l10n.healthCheckSlot1Tag, true),
      (l10n.healthCheckSlot2Title, l10n.healthCheckSlot2Desc, l10n.healthCheckSlot2Tag, false),
      (l10n.healthCheckSlot3Title, l10n.healthCheckSlot3Desc, l10n.healthCheckSlot3Tag, false),
    ];

    return Column(
      children: [
        for (var i = 0; i < slotData.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildSlot(i, slotData[i].$1, slotData[i].$2, slotData[i].$3, slotData[i].$4),
        ],
      ],
    );
  }

  Widget _buildSlot(
    int index,
    String title,
    String desc,
    String tag,
    bool required,
  ) {
    final filled = _slots[index] != null;

    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumb(index, filled),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wraps so a long title never squeezes the tag onto one line.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildNumChip(index + 1, filled),
                    Text(
                      title,
                      style: glassFont(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 15.5 * -0.015,
                        color: kGlassInk,
                      ),
                    ),
                    _buildTag(tag, required),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: glassFont(fontSize: 13, height: 1.45, color: kGlassMut),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Empty slots are dashed to read as a drop target; once a photo is in, the
    // border goes solid so the slot reads as done.
    return GestureDetector(
      onTap: filled ? null : () => _pickForSlot(index),
      child: filled
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGlassAccent.withAlpha(97), width: 1.5),
              ),
              child: body,
            )
          : CustomPaint(
              painter: const _DashedRoundedBorder(
                color: Color(0x613E8E3B), // rgba(62,142,59,.38)
                radius: 20,
                strokeWidth: 1.5,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: body,
              ),
            ),
    );
  }

  Widget _buildThumb(int index, bool filled) {
    if (filled) {
      return SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _slots[index]!,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: -6,
              top: -6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _clearSlot(index),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xE6141E0F),
                      shape: BoxShape.circle,
                    ),
                    child: const BotanlyGlyph(
                      BotanlySvg.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    const glyphs = [BotanlySvg.leaf, BotanlySvg.dropOutline, BotanlySvg.warningTriangle];

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: const _DashedRoundedBorder(
              color: Color(0x613E8E3B),
              radius: 16,
              strokeWidth: 1.5,
            ),
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kGlassLeafBg.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: BotanlyGlyph(glyphs[index], size: 26, color: kGlassAccent),
            ),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kGlassAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kGlassAccent.withAlpha(102),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const BotanlyGlyph(
                BotanlySvg.plus,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumChip(int n, bool filled) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? kGlassAccent : const Color(0x1F141E0F),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$n',
        style: glassFont(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : kGlassMut,
        ),
      ),
    );
  }

  Widget _buildTag(String label, bool required) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: required ? kGlassAccent.withAlpha(46) : kGlassWater.withAlpha(41),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: glassFont(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: required ? kGlassGreenText : kGlassBlueText,
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    final enabled = _canAnalyze;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      // Gradient rather than a hairline: the body scrolls under the CTA, and a
      // fade reads as "there is more above" where a border reads as an edge.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FCFDFB), Color(0xF5FCFDFB)],
          stops: [0, 0.34],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: kGlassWarm.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGlassWarm.withAlpha(66), width: 0.5),
              ),
              child: Row(
                children: [
                  const BotanlyGlyph(
                    BotanlySvg.warningTriangle,
                    size: 17,
                    color: kGlassWarm,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: glassFont(fontSize: 13, color: kGlassWarm),
                    ),
                  ),
                ],
              ),
            ),
          ],
          GestureDetector(
            onTap: enabled ? _analyzeHealth : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: enabled ? kGlassAccent : const Color(0xFFE6E9E4),
                borderRadius: BorderRadius.circular(18),
                // Same reasoning as the result actions: a soft lift, not the
                // photo-backdrop glow from the handoff.
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: kGlassAccent.withAlpha(56),
                          blurRadius: 14,
                          spreadRadius: -10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isAnalyzing)
                    const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    BotanlyGlyph(
                      BotanlySvg.scan,
                      size: 17,
                      color: enabled ? Colors.white : kGlassMut2,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isAnalyzing ? l10n.analyzing : l10n.healthAnalyzeCta,
                    style: glassFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : kGlassMut2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo preview with the scanning line sweeping across it.
class _ScanningPreview extends StatefulWidget {
  final Uint8List image;

  const _ScanningPreview({required this.image});

  @override
  State<_ScanningPreview> createState() => _ScanningPreviewState();
}

class _ScanningPreviewState extends State<_ScanningPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(widget.image, fit: BoxFit.cover),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Align(
              // 6% → 92% of the height, matching the prototype's sweep.
              alignment: Alignment(0, -1 + 2 * (0.06 + 0.86 * _ctrl.value)),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x005FE0A0),
                      Color(0xFF5FE0A0),
                      Color(0x005FE0A0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5FE0A0).withAlpha(140),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// One line of the analysis checklist. Each row ticks over 750 ms after the
/// previous one, so the wait reads as progress rather than a frozen spinner.
class _AnalysisStepRow extends StatefulWidget {
  final String label;
  final int order;

  const _AnalysisStepRow({required this.label, required this.order});

  @override
  State<_AnalysisStepRow> createState() => _AnalysisStepRowState();
}

class _AnalysisStepRowState extends State<_AnalysisStepRow> {
  bool _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      Duration(milliseconds: 750 * (widget.order + 1)),
      () {
        if (mounted) setState(() => _done = true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _done ? const Color(0xFF3E8E3B) : const Color(0x14141E0F),
              shape: BoxShape.circle,
            ),
            child: _done
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: _done ? const Color(0xFF1C3318) : const Color(0xFF6A7C5D),
                fontWeight: _done ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded-rect outline. Flutter has no dashed `Border`, and the empty
/// photo slots in the handoff are dashed to read as drop targets.
class _DashedRoundedBorder extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const _DashedRoundedBorder({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dash = 5,
    this.gap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorder old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}
