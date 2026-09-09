import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';

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
    frontImage = widget.card?.frontImage;
    backImage = widget.card?.backImage;
  }

  @override void dispose() { front.dispose(); back.dispose(); tags.dispose(); super.dispose(); }

  Future<void> _pickImage(bool isFront) async {
    final files = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    if (!mounted) return;
    setState(() => isFront ? frontImage = encoded : backImage = encoded);
  }

  void _removeImage(bool isFront) => setState(() => isFront ? frontImage = null : backImage = null);

  void save() {
    if (front.text.trim().isEmpty && frontImage == null) return;
    if (back.text.trim().isEmpty && backImage == null) return;
    final c = widget.card ?? FlashCard(id: uid(), front: '', back: '');
    c.front = front.text.trim(); c.back = back.text.trim(); c.tags = tags.text.trim(); c.boxIndex = box;
    c.frontImage = frontImage; c.backImage = backImage;
    if (widget.card == null) widget.deck.cards.insert(0, c);
    Navigator.pop(context, true);
  }

  Future<void> remove() async {
    if (widget.card == null) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('حذف کارت؟'), content: const Text('این کارت برای همیشه حذف می‌شود.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))],
    ));
    if (ok == true) { widget.deck.cards.remove(widget.card); if (mounted) Navigator.pop(context, true); }
  }

  Widget _imageEditor({required bool isFront, required String title}) {
    final data = isFront ? frontImage : backImage;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(),
        if (data != null) IconButton(onPressed: () => _removeImage(isFront), icon: const Icon(Icons.delete_outline_rounded)),
        OutlinedButton.icon(onPressed: () => _pickImage(isFront), icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(data == null ? 'افزودن عکس' : 'تغییر عکس')),
      ]),
      if (data != null) ...[
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(base64Decode(data), height: 150, width: double.infinity, fit: BoxFit.cover)),
      ],
    ]);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.card == null ? 'افزودن کارت' : 'ویرایش کارت'), actions: [if (widget.card != null) IconButton(onPressed: remove, icon: const Icon(Icons.delete_outline_rounded))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      TextField(controller: front, maxLines: 5, decoration: const InputDecoration(labelText: 'روی کارت / سؤال', hintText: 'مثلاً: پایتخت فرانسه چیست؟')),
      const SizedBox(height: 10), _imageEditor(isFront: true, title: 'تصویر روی کارت'),
      const Divider(height: 30),
      TextField(controller: back, maxLines: 6, decoration: const InputDecoration(labelText: 'پشت کارت / پاسخ')),
      const SizedBox(height: 10), _imageEditor(isFront: false, title: 'تصویر پشت کارت'),
      const Divider(height: 30),
      TextField(controller: tags, decoration: const InputDecoration(labelText: 'برچسب‌ها', hintText: 'مثلاً زبان، مهم، امتحان')),
      const SizedBox(height: 14),
      DropdownButtonFormField<int>(value: box.clamp(0, widget.deck.boxes.length - 1), decoration: const InputDecoration(labelText: 'خانه'), items: [for (var i = 0; i < widget.deck.boxes.length; i++) DropdownMenuItem(value: i, child: Text(widget.deck.boxes[i].name))], onChanged: (v) => setState(() => box = v ?? 0)),
      const SizedBox(height: 26),
      FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Padding(padding: EdgeInsets.all(5), child: Text('ذخیره کارت', style: TextStyle(fontWeight: FontWeight.w800)))),
    ]),
  );
}
