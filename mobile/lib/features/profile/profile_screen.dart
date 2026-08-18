import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_controller.dart';
import '../../core/translations.dart';
import '../../core/widgets.dart';
import '../gifts/gift_shop_screen.dart';
import '../live/live_room_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override Widget build(BuildContext context) {
    final app=context.watch<AppController>(); final s=ZStrings.of(context); final u=app.user??{};
    final matches=(u['matches']??0) as num, wins=(u['wins']??0) as num; final rate=matches==0?0:(wins/matches*100).round();
    return ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.fromLTRB(18,22,18,18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:const LinearGradient(colors:[Color(0xff5d2b9d),Color(0xff17112a)])),child:Column(children:[
        Stack(alignment:Alignment.bottomRight,children:[const CircleAvatar(radius:48,child:Icon(Icons.person,size:52)),Container(padding:const EdgeInsets.all(5),decoration:const BoxDecoration(color:Colors.amber,shape:BoxShape.circle),child:const Icon(Icons.verified,size:18))]),const SizedBox(height:10),Text(u['username']?.toString()??'Player',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900,color:Colors.white)),Text('@${u['username']??'player'} • Level ${u['level']??1}',style:const TextStyle(color:Colors.white70)),const SizedBox(height:14),Wrap(spacing:8,children:[_Stat('🏆','Wins','${u['wins']??0}'),_Stat('🎮','Games','${u['matches']??0}'),_Stat('🔥','Rate','$rate%'),_Stat('💎','Gems','${u['gems']??0}')])
      ])),const SizedBox(height:14),
      Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const GiftShopScreen())),icon:const Icon(Icons.storefront),label:const Text('المتجر'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const LiveRoomScreen(roomId:'demo-live',title:'ZYNORA LIVE'))),icon:const Icon(Icons.live_tv),label:const Text('LIVE')))]),
      const SizedBox(height:18), SectionHeader(title:s.achievements),const SizedBox(height:10),...app.achievements.take(6).map((a)=>Padding(padding:const EdgeInsets.only(bottom:8),child:ZCard(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.workspace_premium)),title:Text(a['name'].toString(),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(a['description'].toString()))))),
    ]);
  }
}
class _Stat extends StatelessWidget{const _Stat(this.i,this.l,this.v);final String i,l,v;@override Widget build(BuildContext c)=>Container(width:78,padding:const EdgeInsets.symmetric(vertical:8),decoration:BoxDecoration(color:Colors.white12,borderRadius:BorderRadius.circular(16)),child:Column(children:[Text(i),Text(v,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),Text(l,style:const TextStyle(color:Colors.white60,fontSize:11))]));}
