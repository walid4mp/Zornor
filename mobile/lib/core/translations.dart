import 'package:flutter/widgets.dart';

class ZStrings {
  ZStrings(this.locale);
  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  static ZStrings of(BuildContext context) => ZStrings(Localizations.localeOf(context));

  String get appName => 'ZYNORA';
  String get slogan => isArabic ? 'العب. تواصل. اربح.' : 'Play. Connect. Win.';
  String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  String get register => isArabic ? 'إنشاء حساب' : 'Register';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get username => isArabic ? 'اسم المستخدم' : 'Username';
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get games => isArabic ? 'الألعاب' : 'Games';
  String get friends => isArabic ? 'الأصدقاء' : 'Friends';
  String get shop => isArabic ? 'المتجر' : 'Shop';
  String get profile => isArabic ? 'حسابي' : 'Profile';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get quickMatch => isArabic ? 'لعب سريع' : 'Quick Match';
  String get createRoom => isArabic ? 'إنشاء غرفة' : 'Create Room';
  String get publicRooms => isArabic ? 'الغرف العامة' : 'Public Rooms';
  String get privateRoom => isArabic ? 'غرفة خاصة' : 'Private Room';
  String get searchingOpponent => isArabic ? 'جارٍ البحث عن خصم...' : 'Searching for opponent...';
  String get opponentFound => isArabic ? 'تم العثور على خصم!' : 'Opponent Found!';
  String get playNow => isArabic ? 'العب الآن' : 'Play Now';
  String get contactUs => isArabic ? 'تواصل معنا' : 'Contact Us';
  String get darkMode => isArabic ? 'الوضع الداكن' : 'Dark Mode';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get send => isArabic ? 'إرسال' : 'Send';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get missions => isArabic ? 'المهام اليومية' : 'Daily Missions';
  String get leaderboards => isArabic ? 'لوحة الصدارة' : 'Leaderboards';
  String get premiumGaming => isArabic ? 'منصة ألعاب اجتماعية بريميوم' : 'Premium social gaming platform';
  String get startNow => isArabic ? 'ابدأ الآن' : 'Start Now';
  String get playWithFriends => isArabic ? 'العب مع أصدقائك' : 'Play with your friends';
  String get enjoyMultipleGames => isArabic ? 'استمتع بألعاب متعددة' : 'Enjoy multiple games';
  String get competeAndWin => isArabic ? 'نافس واربح الجوائز' : 'Compete and win rewards';
  String get forgotPassword => isArabic ? 'نسيت كلمة المرور' : 'Forgot Password';
  String get resetPassword => isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset Password';
  String get chooseGame => isArabic ? 'اختر لعبتك 🎮' : 'Choose your game 🎮';
  String get mostPlayed => isArabic ? '🔥 الأكثر لعبًا' : '🔥 Most Played';
  String get dailyRewards => isArabic ? '🎁 المكافآت اليومية' : '🎁 Daily Rewards';
  String get onlinePlayers => isArabic ? 'اللاعبون المتصلون' : 'Online Players';
  String get coins => isArabic ? 'العملات' : 'Coins';
  String get xp => 'XP';
  String get level => isArabic ? 'المستوى' : 'Level';
  String get wins => isArabic ? 'الانتصارات' : 'Wins';
  String get matches => isArabic ? 'المباريات' : 'Matches';
  String get winRate => isArabic ? 'نسبة الفوز' : 'Win Rate';
  String get achievements => isArabic ? 'الإنجازات' : 'Achievements';
  String get apiServer => isArabic ? 'خادم API' : 'API Server';
  String get sound => isArabic ? 'المؤثرات' : 'Sound';
  String get music => isArabic ? 'الموسيقى' : 'Music';
  String get about => isArabic ? 'حول التطبيق' : 'About';
  String get terms => isArabic ? 'الشروط' : 'Terms';
  String get privacy => isArabic ? 'الخصوصية' : 'Privacy';
  String get loading => isArabic ? 'جارٍ التحميل...' : 'Loading...';
  String get join => isArabic ? 'انضمام' : 'Join';
}
