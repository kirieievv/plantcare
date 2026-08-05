import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/image_upload_service.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// Edit plant — Liquid Glass, from the `edit_plant_flow` handoff.
///
/// The screen owns exactly two things: the plant's name and its photo. Species,
/// watering plan and notes are produced by the analyzer, so the species is shown
/// behind a padlock and the other two are not on this screen at all — a hand
/// edit there would desync the plant from its last analysis.
class EditPlantScreen extends StatefulWidget {
  final Plant plant;

  const EditPlantScreen({super.key, required this.plant});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _nameController = TextEditingController();

  /// Snapshot taken when the screen opened; `dirty` is measured against it.
  late final String _origName;

  /// Picked but not uploaded. The upload happens on save, so backing out costs
  /// nothing and a picked photo never lands on a plant the user didn't save.
  Uint8List? _newPhoto;

  bool _isLoading = false;
  bool _isImageLoading = false;
  ScaffoldMessengerState? _messenger;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String get _name => _nameController.text.trim();
  bool get _photoChanged => _newPhoto != null;
  bool get _dirty => _name != _origName || _photoChanged;
  bool get _valid => _name.isNotEmpty;
  bool get _canSave => _dirty && _valid && !_isLoading;

  @override
  void initState() {
    super.initState();
    _origName = widget.plant.name.trim();
    _nameController
      ..text = widget.plant.name
      ..addListener(_onNameChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      setState(() => _isImageLoading = true);

      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (image == null) return;

      // Bytes rather than a File: the same path then works on web, and the
      // upload service takes bytes anyway.
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => _newPhoto = bytes);
    } catch (e) {
      _toast(l10n.errorPickingImage(e.toString()), kGlassWarm);
    } finally {
      if (mounted) setState(() => _isImageLoading = false);
    }
  }

  void _revertPhoto() => setState(() => _newPhoto = null);

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final name = _name;
      String? imageUrl;
      if (_newPhoto != null) {
        imageUrl = await ImageUploadService().uploadPlantImageFromBytes(
          _newPhoto!,
          name,
        );
      }

      await PlantService().updatePlantNameAndImage(
        widget.plant.id,
        name: name,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      _toast(l10n.plantUpdatedSuccessfully, kGlassAccent);
      Navigator.pop(
        context,
        widget.plant.copyWith(
          name: name,
          imageUrl: imageUrl ?? widget.plant.imageUrl,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast(l10n.errorUpdatingPlant(e.toString()), kGlassWarm);
    }
  }

  void _toast(String message, Color background) {
    _messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── images ────────────────────────────────────────────────────────────────

  /// Http URLs for anything saved since the storage migration, `data:image`
  /// base64 for the older rows that still carry the photo inline.
  ImageProvider? _providerFor(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(url.split(',')[1]));
      } catch (_) {
        return null;
      }
    }
    if (url.startsWith('http')) return NetworkImage(url);
    return null;
  }

  ImageProvider? get _previewImage => _newPhoto != null
      ? MemoryImage(_newPhoto!)
      : _providerFor(widget.plant.imageUrl);

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The photo sits under a wash that starts at 34% base — dark glyphs.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: kGlassBase,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            _buildScrollContent(media),
            _buildTopNav(media),
          ],
        ),
      ),
    );
  }

  // ─── Layer 1: this plant's photo, so the user sees what they are editing ──
  // background: url(photo) center 28% / cover; transform: scale(1.06)
  // `center 28%` for a cover fit maps to Alignment(0, 2 * 0.28 - 1).

  Widget _buildBackground() {
    final image = _providerFor(widget.plant.imageUrl);
    if (image == null) return const BotanlyBackground();

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1.06,
          child: Image(
            image: image,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.44),
            errorBuilder: (_, __, ___) => const BotanlyBackground(),
          ),
        ),
        // rgba(237,240,236,.34) 0% → .62 26% → .9 62% → #EDF0EC 100%
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.26, 0.62, 1.0],
              colors: [
                Color(0x57EDF0EC),
                Color(0x9EEDF0EC),
                Color(0xE6EDF0EC),
                Color(0xFFEDF0EC),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),
      ],
    );
  }

  // ─── Layer 3: nav ─────────────────────────────────────────────────────────
  // Back only. Saving lives at the foot of the form; two save affordances on
  // one screen is what the handoff removes.

  Widget _buildTopNav(MediaQueryData media) {
    return Positioned(
      top: media.padding.top + 5,
      left: 16,
      right: 16,
      child: _phoneWidth(
        child: SizedBox(
          height: 44,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BotanlyPress(
                  scale: 0.92,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const GlassSurface(
                    blur: 18,
                    shape: BoxShape.circle,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: BotanlyGlyph(
                          BotanlySvg.chevronLeft,
                          size: 19,
                          color: kGlassInk2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: Text(
                    l10n.editPlantTitle,
                    style: glassFont(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.31,
                      color: kGlassInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The handoff is a phone layout, and the photo card is `4/5` of whatever
  /// width it gets — on a desktop browser that alone would be ~1800 px tall.
  /// Cap the column at a phone's width and centre it; on a phone this is a
  /// no-op.
  Widget _phoneWidth({required Widget child}) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: child,
    ),
  );

  // ─── Layer 2: the form ────────────────────────────────────────────────────
  // Content clears the 44 pt nav by 16, matching the prototype's 112 px top.

  Widget _buildScrollContent(MediaQueryData media) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        media.padding.top + 5 + 44 + 16,
        16,
        28 + media.padding.bottom,
      ),
      children: [
        _phoneWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhotoCard(),
              const SizedBox(height: 14),
              _buildNameLabel(),
              _buildNameCard(),
              const SizedBox(height: 14),
              _buildAiNote(),
              const SizedBox(height: 16),
              _buildReadOnlyCard(),
              const SizedBox(height: 14),
              _buildSaveButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Photo ────────────────────────────────────────────────────────────────

  Widget _buildPhotoCard() {
    final image = _previewImage;

    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0x99FFFFFF)),
                  if (image != null)
                    Image(
                      image: image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoEmptyState(),
                    )
                  else
                    _photoEmptyState(),
                  if (_photoChanged)
                    Positioned(top: 12, left: 12, child: _newPhotoBadge()),
                  if (_isImageLoading)
                    const ColoredBox(
                      color: Color(0x8EFFFFFF),
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: kGlassAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _photoButton(
            glyph: BotanlySvg.upload,
            label: l10n.changeImage,
            onTap: _isImageLoading || _isLoading ? null : _pickImage,
          ),
          if (_photoChanged) ...[const SizedBox(height: 9), _revertButton()],
        ],
      ),
    );
  }

  Widget _photoEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BotanlyGlyph(
            BotanlySvg.gallery,
            size: 36,
            color: Color(0x803E8E3B),
          ),
          const SizedBox(height: 9),
          Text(
            l10n.noPhotoYet,
            style: glassFont(fontSize: 13, color: kGlassMut),
          ),
        ],
      ),
    );
  }

  Widget _newPhotoBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE63E8E3B),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB3141E0F),
            blurRadius: 14,
            spreadRadius: -6,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BotanlyGlyph(BotanlySvg.check, size: 11, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              l10n.newPhotoBadge.toUpperCase(),
              style: glassFont(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.35,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoButton({
    required String glyph,
    required String label,
    required VoidCallback? onTap,
  }) {
    return BotanlyPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0x1C3E8E3B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x3D3E8E3B), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BotanlyGlyph(glyph, size: 16, color: kGlassGreenText),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: glassFont(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: kGlassGreenText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revertButton() {
    return BotanlyPress(
      scale: 0.985,
      onTap: _isLoading ? null : _revertPhoto,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0x0F141E0F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BotanlyGlyph(BotanlySvg.revert, size: 14, color: kGlassInk2),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                l10n.revertPhoto,
                textAlign: TextAlign.center,
                style: glassFont(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: kGlassInk2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Name ─────────────────────────────────────────────────────────────────

  Widget _buildNameLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text.rich(
        TextSpan(
          text: l10n.plantName.toUpperCase(),
          children: [
            TextSpan(
              text: ' *',
              style: glassFont(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.04,
                color: kGlassWarm,
              ),
            ),
          ],
        ),
        style: glassFont(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.04,
          color: kGlassMut,
        ),
      ),
    );
  }

  Widget _buildNameCard() {
    final empty = !_valid;
    final filled = _nameController.text.isNotEmpty;

    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Focus(
            // Rebuild on focus so the accent ring can follow the field, exactly
            // as `:focus-within` does in the prototype.
            onFocusChange: (_) => setState(() {}),
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xDBFFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      width: 0.5,
                      color: empty
                          ? const Color(0x80C65644)
                          : focused
                          ? const Color(0x733E8E3B)
                          : const Color(0xF2FFFFFF),
                    ),
                    boxShadow: empty
                        ? const [
                            BoxShadow(
                              color: Color(0x1FC65644),
                              spreadRadius: 3,
                            ),
                          ]
                        : focused
                        ? const [
                            BoxShadow(
                              color: Color(0x1F3E8E3B),
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x1F3E8E3B),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Center(
                          child: BotanlyGlyph(
                            BotanlySvg.leafPair,
                            size: 16,
                            color: kGlassAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(child: _nameInput()),
                      if (filled) ...[const SizedBox(width: 8), _clearButton()],
                    ],
                  ),
                );
              },
            ),
          ),
          _buildNameHint(),
        ],
      ),
    );
  }

  Widget _nameInput() {
    return TextField(
      controller: _nameController,
      enabled: !_isLoading,
      maxLength: 40,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: (_) => _save(),
      cursorColor: kGlassAccent,
      style: glassFont(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.34,
        color: kGlassInk,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: l10n.plantName,
        hintStyle: glassFont(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.34,
          color: kGlassMut2,
        ),
      ),
    );
  }

  /// 28 pt of visuals inside a 44 pt target — the overflow box keeps the extra
  /// 16 pt out of the layout, the way the prototype's `::after` pad does.
  Widget _clearButton() {
    return SizedBox(
      width: 28,
      height: 28,
      child: OverflowBox(
        maxWidth: 44,
        maxHeight: 44,
        child: BotanlyPress(
          scale: 0.9,
          onTap: () {
            _nameController.clear();
          },
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x0F141E0F),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: BotanlyGlyph(
                      BotanlySvg.close,
                      size: 12,
                      color: kGlassMut,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameHint() {
    final empty = !_valid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              empty ? l10n.pleaseEnterPlantName : l10n.editPlantNameHint,
              style: glassFont(
                fontSize: 12.5,
                fontWeight: empty ? FontWeight.w600 : FontWeight.w400,
                height: 1.4,
                color: empty ? kGlassAlert : kGlassMut,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_nameController.text.characters.length}/40',
            style: glassFont(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: kGlassMut2,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  // ─── AI note + read-only species ──────────────────────────────────────────
  // The note comes before the padlock so the lock is already explained when the
  // eye reaches it.

  Widget _buildAiNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1A2E86C8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x332E86C8), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: BotanlyGlyph(
              BotanlySvg.infoCircle,
              size: 16,
              color: kGlassBlueText,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.aiManagedNote,
              style: glassFont(
                fontSize: 12.5,
                height: 1.45,
                color: kGlassBlueText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyCard() {
    final species = widget.plant.species.trim();
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0x1F3E8E3B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: BotanlyGlyph(
                  BotanlySvg.speciesSun,
                  size: 16,
                  color: kGlassAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.species.toUpperCase(),
                    style: glassFont(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.58,
                      color: kGlassMut2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    species.isEmpty ? '—' : species,
                    style: glassFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.23,
                      color: kGlassInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0x0D141E0F),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: BotanlyGlyph(
                  BotanlySvg.lock,
                  size: 13,
                  color: kGlassChevron,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Save ─────────────────────────────────────────────────────────────────
  // The only save affordance on the screen, and it stays dead until there is
  // both a change to save and a name to save it under.

  Widget _buildSaveButton() {
    final enabled = _canSave;

    return BotanlyPress(
      scale: 0.98,
      onTap: enabled ? _save : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: enabled ? kGlassAccent : const Color(0x17141E0F),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0xE63E8E3B),
                    blurRadius: 26,
                    spreadRadius: -12,
                    offset: Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 21,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BotanlyGlyph(
                    BotanlySvg.floppy,
                    size: 17,
                    color: enabled ? Colors.white : kGlassMut2,
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      l10n.save,
                      textAlign: TextAlign.center,
                      style: glassFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.white : kGlassMut2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
