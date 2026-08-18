class ZynoraGift {
  const ZynoraGift({required this.id, required this.name, required this.icon, required this.price, required this.currency, required this.animation});
  final String id, name, icon, currency, animation;
  final int price;
}

const zynoraGifts = <ZynoraGift>[
  ZynoraGift(id:'rose',name:'وردة نيون',icon:'🌹',price:10,currency:'gold',animation:'sparkle'),
  ZynoraGift(id:'heart',name:'قلب مضيء',icon:'💖',price:50,currency:'gold',animation:'hearts'),
  ZynoraGift(id:'car',name:'سيارة فاخرة',icon:'🏎️',price:500,currency:'gold',animation:'drive'),
  ZynoraGift(id:'jet',name:'طائرة خاصة',icon:'✈️',price:1500,currency:'gold',animation:'fly'),
  ZynoraGift(id:'dragon',name:'تنين ناري',icon:'🐉',price:2500,currency:'gems',animation:'dragon'),
  ZynoraGift(id:'crown',name:'تاج الملوك',icon:'👑',price:5000,currency:'gems',animation:'crown'),
  ZynoraGift(id:'galaxy',name:'مجرة ZYNORA',icon:'🌌',price:10000,currency:'gems',animation:'galaxy'),
  ZynoraGift(id:'rocket',name:'صاروخ VIP',icon:'🚀',price:25000,currency:'gems',animation:'rocket'),
];
