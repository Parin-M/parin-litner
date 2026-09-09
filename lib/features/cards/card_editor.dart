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

  @override
  void initState() {
    super.initState();
    frontImage = _cleanBase64(widget.card?.frontImage);
    backImage = _cleanBase64(widget.card?.backImage);
    if (widget.deck.boxes.isEmpty) box = 0;
    else if (box < 0 || box >= widget.deck.boxes.length) box = 0;
  }

  String? _cleanBase64(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty || v == 'null') return null;
    try {
      base64Decode(v);
      return v;
    } catch (_) {
      return null;
    }
  }

  Uint8List? _decodeImage(String? value) {
    if (value == null) return null;
    try { return base64Decode(value); } catch (_) { return null; }
  }

  String s(String key) => AppStrings.t(context, key);

  @override
  void dispose() { front.dispose(); back.dispose(); tags.dispose(); super.dispose(); }

  Future<void> _pickImage(bool isFront) async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image, withData: true);
      if (files.isEmpty) return;
      final bytes = await files.first.readAsBytes();
      if (bytes.isEmpty) return;
      final encoded = base64Encode(bytes);
      if (!mounted) return;
      setState(() => isFront ? frontImage = encoded : backImage = encoded);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this image.')));
    }
  }

  void _removeImage(bool isFront) => setState(() => isFront ? frontImage = null : backImage = null);

  void save() {
    if (front.text.trim().isEmpty && frontImage == null) return;
    if (back.text.trim().isEmpty && backImage == null) return;
    final c = widget.card ?? FlashCard(id: uid(), front: '', back: '');
    c.front = front.text.trim();
    c.back = back.text.trim();
    c.tags = tags.text.trim();
    c.boxIndex = widget.deck.boxes.isEmpty ? 0 : box.clamp(0, widget.deck.boxes.length - 1);
    c.frontImage = frontImage;
    c.backImage = backImage;
    if (widget.card == null) widget.deck.cards.insert(0, c);
    Navigator.pop(context, true);
  }

  Future<void> remove() async {
    if (widget.card == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${s('delete')}?'),
        content: Text(s('delete_card_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s('delete'))),
        ],
      ),
    );
    if (ok == true) {
      widget.deck.cards.remove(widget.card);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _imageEditor({required bool isFront, required String titleKey}) {
    final data = isFront ? frontImage : backImage;
    final bytes = _decodeImage(data);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(s(titleKey), style: const TextStyle(fontWeight: FontWeight.w800))),
            if (data != null) IconButton(onPressed: () => _removeImage(isFront), icon: const Icon(Icons.delete_outline_rounded)),
            OutlinedButton.icon(
              onPressed: () => _pickImage(isFront),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(data == null ? s('add_image') : s('change_image')),
            ),
          ],
        ),
        if (data != null && bytes != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(bytes, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _brokenImage()),
          ),
        ] else if (data != null) ...[
          const SizedBox(height: 8),
          _brokenImage(),
        ],
      ],
    );
  }

  Widget _brokenImage() => Container(
    height: 110,
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image_outlined),
        const SizedBox(width: 8),
        Text(s('image_unavailable')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.card == null ? s('new_card') : s('edit_card'), style: const TextStyle(fontWeight: FontWeight.w900)),
      actions: [if (widget.card != null) IconButton(onPressed: remove, icon: const Icon(Icons.delete_outline_rounded))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(controller: front, maxLines: 5, decoration: InputDecoration(labelText: s('card_front'), hintText: s('front_hint'))),
        const SizedBox(height: 10),
        _imageEditor(isFront: true, titleKey: 'front_image'),
        const Divider(height: 30),
        TextField(controller: back, maxLines: 6, decoration: InputDecoration(labelText: s('card_back'), hintText: s('back_hint'))),
        const SizedBox(height: 10),
        _imageEditor(isFront: false, titleKey: 'back_image'),
        const Divider(height: 30),
        TextField(controller: tags, decoration: InputDecoration(labelText: s('tags'), hintText: s('tags_hint'))),
        const SizedBox(height: 14),
        if (widget.deck.boxes.isNotEmpty)
          DropdownButtonFormField<int>(
            key: ValueKey('box-${widget.deck.boxes.length}-$box'),
            initialValue: box.clamp(0, widget.deck.boxes.length - 1),
            decoration: InputDecoration(labelText: s('box')),
            items: [for (var i = 0; i < widget.deck.boxes.length; i++) DropdownMenuItem(value: i, child: Text(widget.deck.boxes[i].name))],
            onChanged: (v) => setState(() => box = v ?? 0),
          ),
        const SizedBox(height: 26),
        FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: Padding(padding: const EdgeInsets.all(5), child: Text(s('save_card'), style: const TextStyle(fontWeight: FontWeight.w800)))),
      ],
    ),
  );
}
