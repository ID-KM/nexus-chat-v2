# Nexus Chat v2 🚀

محادثة فورية — خياران: **Node.js + WebSocket** (يحتاج سيرفر) أو **Supabase + GitHub Pages** (مجاني بالكامل).

---

## 🅰️ الإصدار الأول: Node.js Server (لـ Render/Railway/Fly)

```
📂 node-server/
├── server.js         # خادم WebSocket + JSON
├── public/
│   └── index.html    # واجهة المحادثة
├── package.json
└── README.md
```

**التشغيل المحلي:**
```bash
cd node-server
npm install
npm start
# → http://localhost:3000
```

**النشر على Render:**
1. ادفع الكود إلى GitHub
2. افتح [Render](https://dashboard.render.com) → New Web Service
3. Build: `npm install` — Start: `node server.js`

---

## 🅱️ الإصدار الثاني: Supabase + GitHub Pages (مجاني 100%)

```
📂 supabase/
├── index.html    # تطبيق كامل — شغال من المتصفح فقط
├── schema.sql    # كود SQL لإعداد الجدول في Supabase
└── README.md
```

**ما تحتاجه:** فقط حساب Supabase مجاني (بريد إلكتروني) → يشتغل على GitHub Pages بدون أي سيرفر.

---

## خطوات إعداد Supabase (v2-Supabase)

### 1. إنشاء مشروع Supabase

1. افتح [supabase.com](https://supabase.com) ← Start your project
2. سجل بحساب GitHub (مجاني، ما يحتاج بطاقة)
3. Create a new project
   - **Name:** `nexus-chat` (أو أي اسم)
   - **Database Password:** خليها قوية واحفظها
4. انتظر ~2 دقيقة حتى ينتهي الإعداد

### 2. إنشاء جدول الرسائل

1. اذهب إلى **SQL Editor** في Supabase Dashboard
2. الصق محتوى ملف [`supabase/schema.sql`](supabase/schema.sql)
3. Run — هيشتغل ويخلق الجدول Policies

### 3. تفعيل Realtime

1. Supabase Dashboard → **Database** → **Replication**
2. تحت **Source** تأكد أن `Realtime` مفعّل
3. في جدول `messages`، شغّل التبديل عشان يظهر تحت `supabase_realtime`

### 4. نسخ المفاتيح

1. Supabase Dashboard → **Project Settings** → **API**
2. انسخ **Project URL** و **anon/public key**
3. افتح `supabase/index.html`
4. غير هذين السطرين:
```js
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key-here';
```

### 5. رفع على GitHub Pages

```bash
# ادفع الكود إلى GitHub
git add -A
git commit -m "Add Supabase version"
git push

# شغّل GitHub Pages:
# Settings → Pages → Source: GitHub Actions
# أو استخدم docs/ folder
```

---

## 🆚 مقارنة الإصدارات

| الميزة | v1 (Firebase) | v2 Node.js | v2 Supabase |
|--------|:-------------:|:----------:|:-----------:|
| **الثبات** | ❌ صلاحية منتهية | ✅ JSON | ✅ PostgreSQL |
| **مؤشر الكتابة** | ❌ | ✅ | ❌ (قريباً) |
| **عدد المتصلين** | ❌ | ✅ | ❌ |
| **استضافة مجانية** | GitHub Pages | Render/Railway | **GitHub Pages** ✅ |
| **بطاقة بنكية** | ❌ | ✅ (لتوثيق Render) | ❌ |
| **حجم المشروع** | Firebase SDK | Node.js | Supabase SDK |

> 💡 **الخلاصة:** اذا ما عندك بطاقة بنكية → **Supabase + GitHub Pages** هو الحل الأمثل.
> إذا تقدر توثق Render → **Node.js Server** يعطيك ميزات إضافية (typing, online count).
