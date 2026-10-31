extends RefCounted
## Bundled navigation is available immediately, including without internet.
const TEXT := [
  [
    "PLAY",
    "MAIN",
    "开始游戏",
    "விளையாடு"
  ],
  [
    "CREATE ROOM",
    "CIPTA BILIK",
    "创建房间",
    "அறையை உருவாக்கு"
  ],
  [
    "JOIN ROOM",
    "SERTAI BILIK",
    "加入房间",
    "அறையில் சேர்"
  ],
  [
    "HOW TO PLAY",
    "CARA BERMAIN",
    "玩法说明",
    "விளையாடுவது எப்படி"
  ],
  [
    "EXIT",
    "KELUAR",
    "退出",
    "வெளியேறு"
  ],
  [
    "SETTINGS",
    "TETAPAN",
    "设置",
    "அமைப்புகள்"
  ],
  [
    "LANGUAGE",
    "BAHASA",
    "语言",
    "மொழி"
  ],
  [
    "MUTE AUDIO",
    "SENYAPKAN AUDIO",
    "静音",
    "ஒலியை அணை"
  ],
  [
    "TURN AUDIO ON",
    "HIDUPKAN AUDIO",
    "开启声音",
    "ஒலியை இயக்கு"
  ],
  [
    "TEST SOUND",
    "UJI BUNYI",
    "测试声音",
    "ஒலியைச் சோதி"
  ],
  [
    "OFFLINE PRACTICE",
    "LATIHAN LUAR TALIAN",
    "离线练习",
    "இணையமில்லாப் பயிற்சி"
  ],
  [
    "SIGN OUT",
    "LOG KELUAR",
    "退出登录",
    "வெளியேறு"
  ],
  [
    "< BACK",
    "< KEMBALI",
    "< 返回",
    "< பின்செல்"
  ],
  [
    "Welcome, Player!",
    "Selamat datang, Pemain!",
    "欢迎，玩家！",
    "வீரரே, வரவேற்கிறோம்!"
  ],
  [
    "Sign in, create an account, or join as a guest.",
    "Log masuk, cipta akaun atau sertai sebagai tetamu.",
    "登录、创建账号或以访客身份加入。",
    "உள்நுழையவும், கணக்கை உருவாக்கவும் அல்லது விருந்தினராகச் சேரவும்."
  ],
  [
    "Continue with Google",
    "Teruskan dengan Google",
    "使用 Google 继续",
    "Google மூலம் தொடரவும்"
  ],
  [
    "Continue with Huawei ID",
    "Teruskan dengan Huawei ID",
    "使用华为账号继续",
    "Huawei ID மூலம் தொடரவும்"
  ],
  [
    "Sign in with Email",
    "Log masuk dengan E-mel",
    "使用电子邮件登录",
    "மின்னஞ்சல் மூலம் உள்நுழை"
  ],
  [
    "Create Account",
    "Cipta Akaun",
    "创建账号",
    "கணக்கை உருவாக்கு"
  ],
  [
    "▷  Play as Guest",
    "▷  Main sebagai Tetamu",
    "▷  以访客身份游戏",
    "▷  விருந்தினராக விளையாடு"
  ],
  [
    "Step into the village. Play your part.",
    "Masuk ke kampung. Mainkan perananmu.",
    "走进村庄，扮演你的角色。",
    "கிராமத்திற்குள் நுழைந்து உங்கள் பங்கை ஆற்றுங்கள்."
  ],
  [
    "CANCEL",
    "BATAL",
    "取消",
    "ரத்து செய்"
  ],
  [
    "CONFIRM",
    "SAHKAN",
    "确认",
    "உறுதி செய்"
  ],
  [
    "CLOSE",
    "TUTUP",
    "关闭",
    "மூடு"
  ],
  [
    "BACK",
    "KEMBALI",
    "返回",
    "பின்செல்"
  ],
  [
    "CONTINUE",
    "TERUSKAN",
    "继续",
    "தொடரவும்"
  ],
  [
    "START",
    "MULA",
    "开始",
    "தொடங்கு"
  ],
  [
    "READY",
    "SEDIA",
    "准备",
    "தயார்"
  ],
  [
    "ARE YOU READY?",
    "ANDA SUDAH SEDIA?",
    "准备好了吗？",
    "நீங்கள் தயாரா?"
  ],
  [
    "WAITING FOR PLAYERS",
    "MENUNGGU PEMAIN",
    "等待玩家",
    "வீரர்களுக்காகக் காத்திருக்கிறது"
  ],
  [
    "PLAYERS IN ROOM",
    "PEMAIN DALAM BILIK",
    "房间内的玩家",
    "அறையிலுள்ள வீரர்கள்"
  ],
  [
    "LEAVE GAME",
    "TINGGALKAN GAME",
    "离开游戏",
    "விளையாட்டை விட்டு வெளியேறு"
  ],
  [
    "EXIT GAME?",
    "KELUAR GAME?",
    "退出游戏？",
    "விளையாட்டிலிருந்து வெளியேறவா?"
  ],
  [
    "Close Nenek Kebayan?",
    "Tutup Nenek Kebayan?",
    "关闭 Nenek Kebayan？",
    "Nenek Kebayan-ஐ மூடவா?"
  ],
  [
    "SCAN QR",
    "IMBAS QR",
    "扫描二维码",
    "QR குறியீட்டை ஸ்கேன் செய்"
  ],
  [
    "SHOW ROOM QR",
    "PAPAR QR BILIK",
    "显示房间二维码",
    "அறையின் QR குறியீட்டைக் காட்டு"
  ],
  [
    "SCAN TO JOIN MY ROOM",
    "IMBAS UNTUK SERTAI BILIK",
    "扫码加入我的房间",
    "என் அறையில் சேர ஸ்கேன் செய்"
  ],
  [
    "VOTE FOR A PLAYER",
    "UNDI SEORANG PEMAIN",
    "投票选择玩家",
    "ஒரு வீரருக்கு வாக்களி"
  ],
  [
    "SKIP",
    "LANGKAU",
    "跳过",
    "தவிர்"
  ],
  [
    "INTERACT",
    "INTERAKSI",
    "互动",
    "செயல்படு"
  ],
  [
    "TASKS",
    "TUGAS",
    "任务",
    "பணிகள்"
  ],
  [
    "MAP",
    "PETA",
    "地图",
    "வரைபடம்"
  ],
  [
    "TRANSLATE",
    "TERJEMAH",
    "翻译",
    "மொழிபெயர்"
  ],
  [
    "TRANSLATE GUIDE",
    "TERJEMAH PANDUAN",
    "翻译指南",
    "வழிகாட்டியை மொழிபெயர்"
  ],
  [
    "Original (English)",
    "Asal (Bahasa Inggeris)",
    "原文（英语）",
    "மூலம் (ஆங்கிலம்)"
  ],
  [
    "The translation will appear here.",
    "Terjemahan akan dipaparkan di sini.",
    "翻译将在此显示。",
    "மொழிபெயர்ப்பு இங்கே தோன்றும்."
  ],
  [
    "WASD / arrow keys or the touch pad to move.",
    "Gunakan WASD / kekunci anak panah atau pad sentuh untuk bergerak.",
    "使用 WASD、方向键或触控板移动。",
    "நகர WASD / அம்புக்குறி விசைகள் அல்லது தொடுதளத்தைப் பயன்படுத்தவும்."
  ],
  [
    "VOLUME · %d%%",
    "KELANTANGAN · %d%%",
    "音量 · %d%%",
    "ஒலி அளவு · %d%%"
  ],
  [
    "Email",
    "E-mel",
    "电子邮件",
    "மின்னஞ்சல்"
  ],
  [
    "Password",
    "Kata laluan",
    "密码",
    "கடவுச்சொல்"
  ],
  [
    "Display name",
    "Nama paparan",
    "显示名称",
    "காட்சிப் பெயர்"
  ],
  [
    "SIGN IN",
    "LOG MASUK",
    "登录",
    "உள்நுழை"
  ],
  [
    "CREATE ACCOUNT",
    "CIPTA AKAUN",
    "创建账号",
    "கணக்கை உருவாக்கு"
  ],
  [
    "RESET PASSWORD",
    "TETAP SEMULA KATA LALUAN",
    "重置密码",
    "கடவுச்சொல்லை மீட்டமை"
  ],
  [
    "FORGOT PASSWORD?",
    "LUPA KATA LALUAN?",
    "忘记密码？",
    "கடவுச்சொல்லை மறந்துவிட்டீர்களா?"
  ],
  [
    "TIME TO VOTE",
    "MASA UNTUK MENGUNDI",
    "投票时间",
    "வாக்களிக்கும் நேரம்"
  ],
  [
    "VICTORY",
    "KEMENANGAN",
    "胜利",
    "வெற்றி"
  ],
  [
    "DEFEAT",
    "KEKALAHAN",
    "失败",
    "தோல்வி"
  ],
  [
    "PLAY AGAIN",
    "MAIN SEMULA",
    "再玩一次",
    "மீண்டும் விளையாடு"
  ],
  [
    "MAIN MENU",
    "MENU UTAMA",
    "主菜单",
    "முதன்மைப் பட்டி"
  ],
  [
    "English is selected.",
    "Bahasa Inggeris dipilih.",
    "已选择英语。",
    "ஆங்கிலம் தேர்ந்தெடுக்கப்பட்டுள்ளது."
  ],
  [
    "Language applied.",
    "Bahasa telah ditukar.",
    "语言已应用。",
    "மொழி மாற்றப்பட்டது."
  ],
  [
    "Translating game text with Huawei… Internet is required.",
    "Sedang menterjemah teks game dengan Huawei… Internet diperlukan.",
    "正在通过华为翻译游戏文本…需要联网。",
    "Huawei மூலம் விளையாட்டு உரை மொழிபெயர்க்கப்படுகிறது… இணையம் தேவை."
  ],
  [
    "Some game text needs Huawei translation in the Android app.",
    "Sesetengah teks game memerlukan terjemahan Huawei dalam aplikasi Android.",
    "部分游戏文本需要在 Android 应用中通过华为翻译。",
    "சில விளையாட்டு உரைகளுக்கு Android செயலியில் Huawei மொழிபெயர்ப்பு தேவை."
  ],
  [
    "Choosing a language sends game UI text to Huawei for translation. Internet is required for new text.",
    "Pilihan bahasa menghantar teks antaramuka game kepada Huawei untuk terjemahan. Teks baharu memerlukan internet.",
    "选择语言后，游戏界面文本将发送给华为进行翻译。翻译新文本需要联网。",
    "மொழியைத் தேர்ந்தெடுத்தால் விளையாட்டு உரை Huawei-க்கு மொழிபெயர்க்க அனுப்பப்படும். புதிய உரைக்கு இணையம் தேவை."
  ],
  [
    "Malay is available offline.",
    "Bahasa Melayu tersedia tanpa internet.",
    "马来语支持离线使用。",
    "மலாய் மொழி இணையமின்றி கிடைக்கும்。"
  ],
  [
    "English and Malay work offline. Chinese and Tamil use Huawei translation for additional game text and need internet.",
    "Bahasa Inggeris dan Melayu boleh digunakan tanpa internet. Bahasa Cina dan Tamil menggunakan terjemahan Huawei untuk teks game tambahan dan memerlukan internet.",
    "英语和马来语支持离线使用。中文和泰米尔语的其他游戏文本通过华为翻译，需要联网。",
    "ஆங்கிலமும் மலாயும் இணையமின்றி இயங்கும். கூடுதல் விளையாட்டு உரைகளுக்கு சீனமும் தமிழும் Huawei மொழிபெயர்ப்பைப் பயன்படுத்துவதால் இணையம் தேவை."
  ]
]
