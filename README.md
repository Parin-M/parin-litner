# Parin Litner v2

یک اپلیکیشن Flutter برای سیستم لایتنر با UI مینیمال، حرفه‌ای و Glassmorphism.

## امکانات نسخه 2
- جعبه‌های واقعی لایتنر 1 تا 5 و زمان‌بندی مرور
- الگوریتم فاصله‌گذاری برای Again / Hard / Good / Easy
- افزودن و حذف دسته
- افزودن و حذف کارت
- تگ برای کارت‌ها
- جستجوی دسته و کارت
- مرور فقط کارت‌های Due و fallback به کل دسته
- Flip سه‌بعدی کارت
- انیمیشن‌های Ambient، Fade/Slide و Glow
- XP و Streak
- آمار کلی و نمودار
- آمار جعبه‌های 1 تا 5
- Dark / Light
- زمان یادآوری و فعال/غیرفعال کردن Reminder (تنظیمات آماده؛ برای Push واقعی باید notification plugin اضافه شود)
- Import / Export با JSON
- ذخیره آفلاین با SharedPreferences
- RTL فارسی

## اجرا

```bash
flutter pub get
flutter run
```

## ساخت APK

```bash
flutter build apk --release
```

خروجی:

`build/app/outputs/flutter-apk/app-release.apk`

## توجه

این محیط Flutter SDK و Android SDK فعال ندارد، بنابراین APK نهایی در این محیط کامپایل نشده است. سورس برای Flutter 3.22+ آماده شده است.
