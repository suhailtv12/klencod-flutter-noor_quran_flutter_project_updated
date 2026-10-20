# نور القرآن — ملفات المشروع المحدثة

هذه الملفات تتضمن واجهة Flutter الأساسية، وملف إعداد الحزم، وملف Android Manifest متوافقًا مع Android embedding v2، و`MainActivity.kt` الخاص بتشغيل الصوت بالخلفية، وWorkflow لبناء APK على GitHub Actions.

## بناء التطبيق على GitHub Actions
1. ارفع محتويات المجلد إلى مستودع GitHub جديد، وتأكد أن `pubspec.yaml` و`lib/main.dart` في جذر المستودع.
2. ارفع مجلد `.github/workflows/build-android.yml` كما هو.
3. افتح تبويب **Actions** في GitHub.
4. اختر **Build Noor Quran APK** ثم **Run workflow**، أو ادفع commit إلى فرع `main` أو `master`.
5. بعد نجاح المهمة، افتح تشغيل الـ Workflow، ثم قسم **Artifacts** ونزّل `noor-quran-release-apk`.

## البناء محليًا
أنشئ مشروع Flutter حديثًا أو استخدم Flutter SDK حديثًا، ثم من مجلد المشروع نفّذ:

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

## ملاحظات مهمة
- يقوم الـ Workflow بحذف مجلد Android القديم وإعادة إنشائه بواسطة نسخة Flutter الحالية قبل البناء؛ وهذا يستهدف الخطأ `Build failed due to use of deleted Android v1 embedding`.
- يلزم اتصال إنترنت أثناء البناء لأن Flutter يجلب الحزم وGradle dependencies.
- هذا لا يضمن أن كل أخطاء Dart أو Gradle الأخرى غير موجودة؛ راجع سجل Actions إذا ظهر خطأ جديد.
- التطبيق يجلب بيانات القرآن والتلاوات من خدمة خارجية؛ يلزم الإنترنت لتحميل المحتوى الذي لم يُخزّن محليًا.
