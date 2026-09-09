import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../cards/card_editor.dart';
import '../study/study_page.dart';

class DeckPage extends StatefulWidget {
  final Deck deck; final VoidCallback onChanged;
  const DeckPage({super.key, required this.deck, required this.onChanged});
  @override State<DeckPage> createState() => _DeckPageState();
}
class _DeckPageState extends State<DeckPage> {
  String query = '';
  @override Widget build(BuildContext context) {
    final d = widget.deck;
    final cards = d.cards.where((c) => '${c.front} ${c.back} ${c.tags}'.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: Text(d.name), actions: [IconButton(onPressed: () => _editDeck(), icon: const Icon(Icons.edit_rounded)), IconButton(onPressed: () => _boxes(), icon: const Icon(Icons.view_module_rounded))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editCard(), icon: const Icon(Icons.add_rounded), label: const Text('کارت جدید')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        Row(children: [Expanded(child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'جستجوی کارت...'))), const SizedBox(width: 10), FilledButton.tonalIcon(onPressed: () => _study(), icon: const Icon(Icons.play_arrow_rounded), label: const Text('مرور'))]),
        const SizedBox(height: 16),
        SizedBox(height: 104, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: d.boxes.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) { final b=d.boxes[i]; final count=d.cards.where((c)=>c.boxIndex==i).length; return SizedBox(width: 120, child: AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.inventory_2_rounded, color: boxColor(b)), const Spacer(), Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), Text('$count کارت', style: const TextStyle(color: Colors.white60))]))); })),
        const SizedBox(height: 16),
        if (cards.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('کارت پیدا نشد'))),
        ...cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: AnimatedGlassCard(onTap: () => _editCard(c), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.front, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(c.back, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 7), Text('${d.boxes[min(c.boxIndex, d.boxes.length - 1)].name} • ${c.tags}', style: const TextStyle(fontSize: 12, color: Colors.white38))])), IconButton(onPressed: () { c.favorite=!c.favorite; setState(() {}); widget.onChanged(); }, icon: Icon(c.favorite ? Icons.star_rounded : Icons.star_border_rounded, color: c.favorite ? Colors.amber : Colors.white38))])))),
      ]),
    );
  }
  Future<void> _editDeck() async { final name=TextEditingController(text:widget.deck.name); final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('ویرایش دسته'),content:TextField(controller:name,decoration:const InputDecoration(labelText:'نام')),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ذخیره'))])); if(ok==true&&name.text.trim().isNotEmpty){widget.deck.name=name.text.trim();setState((){});widget.onChanged();}}
  Future<void> _editCard([FlashCard? card]) async { final changed=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>CardEditor(deck:widget.deck,card:card))); if(changed==true){setState((){});widget.onChanged();}}
  void _study(){Navigator.push(context,MaterialPageRoute(builder:(_)=>StudyPage(deck:widget.deck,onChanged:(){setState((){});widget.onChanged();})));}
  Future<void> _boxes() async { await showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>BoxManager(deck:widget.deck,onChanged:(){setState((){});widget.onChanged();})); }
}

class BoxManager extends StatefulWidget { final Deck deck; final VoidCallback onChanged; const BoxManager({super.key,required this.deck,required this.onChanged}); @override State<BoxManager> createState()=>_BoxManagerState(); }
class _BoxManagerState extends State<BoxManager> {
  Future<void> _rename(int i) async { final c=TextEditingController(text:widget.deck.boxes[i].name); final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('نام خانه'),content:TextField(controller:c),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ذخیره'))])); if(ok==true&&c.text.trim().isNotEmpty){widget.deck.boxes[i].name=c.text.trim();setState((){});widget.onChanged();}}
  void _add(){widget.deck.boxes.add(LeitnerBox(id:uid(),name:'خانه ${widget.deck.boxes.length+1}',colorValue:Colors.primaries[widget.deck.boxes.length%Colors.primaries.length].value));setState((){});widget.onChanged();}
  Future<void> _delete(int i) async { if(widget.deck.boxes.length<=1)return; final removed=widget.deck.boxes.removeAt(i); for(final c in widget.deck.cards){if(c.boxIndex==i)c.boxIndex=0;else if(c.boxIndex>i)c.boxIndex--; } setState((){});widget.onChanged(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${removed.name} حذف شد'))); }
  @override Widget build(BuildContext context)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,children:[Row(children:[const Expanded(child:Text('مدیریت خانه‌ها',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900))),IconButton(onPressed:_add,icon:const Icon(Icons.add_circle_rounded))]),const SizedBox(height:10),Flexible(child:ListView.builder(shrinkWrap:true,itemCount:widget.deck.boxes.length,itemBuilder:(_,i){final b=widget.deck.boxes[i];return ListTile(leading:CircleAvatar(backgroundColor:boxColor(b),child:Text('${i+1}')),title:Text(b.name),subtitle:Text('${widget.deck.cards.where((c)=>c.boxIndex==i).length} کارت'),trailing:Wrap(children:[IconButton(onPressed:()=>_rename(i),icon:const Icon(Icons.edit_rounded)),IconButton(onPressed:()=>_delete(i),icon:const Icon(Icons.delete_outline_rounded))]));}))])));
}
