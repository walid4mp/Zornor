import 'package:flutter/material.dart';
import 'gift_catalog.dart';

class GiftShopScreen extends StatelessWidget {
  const GiftShopScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('هدايا ZYNORA')),
    body: GridView.builder(
      padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.86),
      itemCount: zynoraGifts.length,
      itemBuilder: (_,i) { final g=zynoraGifts[i]; return Card(child: InkWell(onTap:()=>showDialog(context:context,builder:(_)=>AlertDialog(title:Text('${g.icon} ${g.name}'),content:Text('السعر: ${g.price} ${g.currency == 'gems' ? '💎 جواهر':'🪙 Gold'}\nتأثير: ${g.animation}'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('شراء'))])),child:Padding(padding:const EdgeInsets.all(14),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(g.icon,style:const TextStyle(fontSize:54)),const SizedBox(height:8),Text(g.name,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),Text('${g.price} ${g.currency == 'gems' ? '💎':'🪙'}')])))); }
    ),
  );
}
