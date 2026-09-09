import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';

class CardEditor extends StatefulWidget { final Deck deck; final FlashCard? card; const CardEditor({super.key,required this.deck,this.card}); @override State<CardEditor> createState()=>_CardEditorState(); }
class _CardEditorState extends State<CardEditor> {
  late final TextEditingController front=TextEditingController(text:widget.card?.front??'');
  late final TextEditingController back=TextEditingController(text:widget.card?.back??'');
  late final TextEditingController tags=TextEditingController(text:widget.card?.tags??'');
  late int box=widget.card?.boxIndex??0;
  @override void dispose(){front.dispose();back.dispose();tags.dispose();super.dispose();}
  void save(){if(front.text.trim().isEmpty||back.text.trim().isEmpty)return;final c=widget.card??FlashCard(id:uid(),front:front.text.trim(),back:back.text.trim());c.front=front.text.trim();c.back=back.text.trim();c.tags=tags.text.trim();c.boxIndex=box;if(widget.card==null)widget.deck.cards.insert(0,c);Navigator.pop(context,true);}
  Future<void> remove() async {if(widget.card==null)return;final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('حذف کارت؟'),content:const Text('این کارت برای همیشه حذف می‌شود.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حذف'))]));if(ok==true){widget.deck.cards.remove(widget.card);Navigator.pop(context,true);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.card==null?'افزودن کارت':'ویرایش کارت'),actions:[if(widget.card!=null)IconButton(onPressed:remove,icon:const Icon(Icons.delete_outline_rounded))]),body:ListView(padding:const EdgeInsets.all(18),children:[TextField(controller:front,maxLines:5,decoration:const InputDecoration(labelText:'روی کارت / سؤال',hintText:'مثلاً: پایتخت فرانسه چیست؟')),const SizedBox(height:14),TextField(controller:back,maxLines:6,decoration:const InputDecoration(labelText:'پشت کارت / پاسخ')),const SizedBox(height:14),TextField(controller:tags,decoration:const InputDecoration(labelText:'برچسب‌ها',hintText:'مثلاً زبان، مهم، امتحان')),const SizedBox(height:14),DropdownButtonFormField<int>(value:box,decoration:const InputDecoration(labelText:'خانه'),items:[for(var i=0;i<widget.deck.boxes.length;i++)DropdownMenuItem(value:i,child:Text(widget.deck.boxes[i].name))],onChanged:(v)=>setState(()=>box=v??0)),const SizedBox(height:26),FilledButton.icon(onPressed:save,icon:const Icon(Icons.save_rounded),label:const Padding(padding:EdgeInsets.all(5),child:Text('ذخیره کارت',style:TextStyle(fontWeight:FontWeight.w800))))]));
}
