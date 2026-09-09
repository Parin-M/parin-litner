import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';
import '../../core/i18n/app_strings.dart';

class CardEditor extends StatefulWidget {
  final Deck deck;
  final FlashCard? card;
  const CardEditor({super.key, required this.deck, this.card});
  @override State<CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<CardEditor> {
  late final TextEditingController front = TextEditingController(text: widget.card?.front ?? '');
  late final TextEditingController back = TextEditingController(text: widget.card?.back ?? '');
  late final TextEditingController tags = TextEditingController(text: widget.card?.tags ?? '');
  late int box = widget.card?.boxIndex ?? 0;
  String? frontImage;
  String? backImage;
  bool saving = false;
  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    frontImage = _cleanBase64(widget.card?.frontImage);
    backImage = _cleanBase64(widget.card?.backImage);
    if (widget.deck.boxes.isEmpty || box < 0 || box >= widget.deck.boxes.length) box = 0;
  }

  String? _cleanBase64(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == 'null') return null;
    try { base64Decode(value.trim()); return value.trim(); } catch (_) { return null; }
  }

  Uint8List? _bytes(String? value) => tryDecodeBase64Image(value);

  @override
  void dispose() { front.dispose(); back.dispose(); tags.dispose(); super.dispose(); }

  Future<void> _pickImage(bool isFront) async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !mounted) return;
      final encoded = base64Encode(bytes);
      setState(() => isFront ? frontImage = encoded : backImage = encoded);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('image_error'))));
    }
  }

  void _removeImage(bool isFront) => setState(() => isFront ? frontImage = null : backImage = null);

  Future<void> save() async {
    if (saving) return;
    if (front.text.trim().isEmpty && _bytes(frontImage) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s('card_front')}: ${s('save')}')));
      return;
    }
    if (back.text.trim().isEmpty && _bytes(backImage) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s('card_back')}: ${s('save')}')));
      return;
    }
    setState(() => saving = true);
    final c = widget.card ?? FlashCard(id: uid(), front: '', back: '');
    c.front = front.text.trim();
    c.back = back.text.trim();
    c.tags = tags.text.trim();
    c.boxIndex = widget.deck.boxes.isEmpty ? 0 : box.clamp(0, widget.deck.boxes.length - 1).toInt();
    c.frontImage = frontImage;
    c.backImage = backImage;
    if (widget.card == null) widget.deck.cards.insert(0, c);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> remove() async {
    if (widget.card == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(s('delete_card')), content: Text(s('delete_card_confirm')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(s('delete')))]));
    if (ok == true) { widget.deck.cards.remove(widget.card); if (mounted) Navigator.pop(context, true); }
  }

  Widget _brokenImage() => Container(height: 120, width: double.infinity, alignment: Alignment.center, color: Theme.of(context).dividerColor.withValues(alpha: .12), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.broken_image_outlined), const SizedBox(width: 8), Text(s('image_unavailable'))]));

  Widget _imageEditor({required bool isFront, required String titleKey}) {
    final data = isFront ? frontImage : backImage;
    final bytes = _bytes(data);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(s(titleKey), style: const TextStyle(fontWeight: FontWeight.w700))), if (data != null) IconButton(onPressed: () => _removeImage(isFront), icon: const Icon(Icons.delete_outline), tooltip: s('delete')), OutlinedButton.icon(onPressed: () => _pickImage(isFront), icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(data == null ? s('add_image') : s('change_image')))]),
      if (data != null) ...[const SizedBox(height: 8), SafeMemoryImage(base64: bytes == null ? null : data, height: 150, width: double.infinity, fit: BoxFit.contain, borderRadius: BorderRadius.circular(3), error: _brokenImage())],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final maxBox = widget.deck.boxes.isEmpty ? 0 : widget.deck.boxes.length - 1;
    box = box.clamp(0, maxBox).toInt();
    return Scaffold(
      appBar: AppBar(title: Text(widget.card == null ? s('new_card') : s('edit_card')), actions: [if (widget.card != null) IconButton(onPressed: remove, icon: const Icon(Icons.delete_outline), tooltip: s('delete'))]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: front, maxLines: 5, decoration: InputDecoration(labelText: s('card_front'), hintText: s('front_hint'), alignLabelWithHint: true)),
        const SizedBox(height: 12), _imageEditor(isFront: true, titleKey: 'front_image'),
        const Divider(height: 30),
        TextField(controller: back, maxLines: 6, decoration: InputDecoration(labelText: s('card_back'), hintText: s('back_hint'), alignLabelWithHint: true)),
        const SizedBox(height: 12), _imageEditor(isFront: false, titleKey: 'back_image'),
        const Divider(height: 30),
        TextField(controller: tags, decoration: InputDecoration(labelText: s('tags'), hintText: s('tags_hint'))),
        const SizedBox(height: 12),
        if (widget.deck.boxes.isNotEmpty) DropdownButtonFormField<int>(value: box, isExpanded: true, decoration: InputDecoration(labelText: s('box')), items: [for (var i = 0; i < widget.deck.boxes.length; i++) DropdownMenuItem(value: i, child: Text(widget.deck.boxes[i].name))], onChanged: (v) => setState(() => box = v ?? 0)),
        const SizedBox(height: 24),
        SizedBox(height: 48, child: ElevatedButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save_outlined), label: Text(s('save_card')))),
      ])),
    );
  }
}
