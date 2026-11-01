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
    "ASLEEP",
    "TERTIDUR",
    "已睡着",
    "தூங்குகிறார்"
  ],
  [
    "The gong is cooling down. Wait %d seconds.",
    "Gong sedang dicas semula. Tunggu %d saat.",
    "铜锣正在冷却，请等待 %d 秒。",
    "மணி மீண்டும் தயாராகிறது. %d விநாடிகள் காத்திருக்கவும்."
  ],
  [
    "Emergency meeting gong • ready in %ds",
    "Gong mesyuarat kecemasan • sedia dalam %ds",
    "紧急会议铜锣 • %d秒后可用",
    "அவசரக் கூட்ட மணி • %d வினாடிகளில் தயார்"
  ],
  [
    "Emergency meeting gong • tap INTERACT",
    "Gong mesyuarat kecemasan • tekan INTERAKSI",
    "紧急会议铜锣 • 点击互动",
    "அவசரக் கூட்ட மணி • செயல்படு என்பதைத் தட்டவும்"
  ],
  [
    "The gong is cooling down. Wait %d seconds before calling another meeting.",
    "Gong sedang dicas semula. Tunggu %d saat sebelum memanggil mesyuarat lagi.",
    "铜锣正在冷却，请等待 %d 秒后再召开会议。",
    "மீண்டும் கூட்டத்தை அழைப்பதற்கு முன் %d விநாடிகள் காத்திருக்கவும்."
  ],
  [
    "SLEEPING",
    "TERTIDUR",
    "睡着",
    "தூங்குகிறார்"
  ],
  [
    "The Nenek Kebayan outnumber the remaining awake villagers. Nenek Kebayan wins!",
    "Bilangan Nenek Kebayan melebihi Orang Kampung yang masih berjaga. Nenek Kebayan menang!",
    "Nenek Kebayan 的人数超过仍然清醒的村民。Nenek Kebayan 获胜！",
    "விழித்திருக்கும் கிராமவாசிகளை விட Nenek Kebayan அதிகமாக உள்ளனர். Nenek Kebayan வெற்றி!"
  ],
  [
    "DISCUSSION  •  %ds",
    "PERBINCANGAN  •  %ds",
    "讨论  •  %d秒",
    "கலந்துரையாடல்  •  %d வி"
  ],
  [
    "VOTING  •  %ds",
    "PENGUNDIAN  •  %ds",
    "投票  •  %d秒",
    "வாக்களிப்பு  •  %d வி"
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
  ],
  [
    "Playing modes",
    "Mod permainan",
    "游戏模式",
    "விளையாட்டு முறைகள்"
  ],
  [
    "Start Game → Play with Friends, Solo vs Bots, or Quick Match.\nFriends: create or join a private room with a code. The host starts when at least two human players are ready.\nSolo: play offline as one Villager with nine bots.\nQuick Match searches for up to 60 seconds; bots fill empty spaces after the wait.\nEvery match has ten characters: eight Villagers and two Nenek Kebayan.",
    "Tekan Mula Permainan → Main Bersama Rakan, Solo menentang Bot atau Cari Perlawanan.\nRakan: cipta atau sertai bilik peribadi menggunakan kod. Hos boleh memulakan permainan apabila sekurang-kurangnya dua pemain manusia bersedia.\nSolo: bermain di luar talian sebagai seorang Orang Kampung bersama sembilan bot.\nCari Perlawanan mencari pemain sehingga 60 saat; bot mengisi ruang kosong selepas itu.\nSetiap perlawanan mempunyai sepuluh watak: lapan Orang Kampung dan dua Nenek Kebayan.",
    "点击开始游戏 → 与朋友游玩、单人对战机器人或快速匹配。\n朋友模式：创建私人房间并分享代码，或输入代码加入。至少两名真人玩家准备就绪后，房主即可开始。\n单人模式：离线扮演一名村民，与九个机器人游玩。\n快速匹配：最多搜索 60 秒；等待结束后由机器人填补空位。\n每场比赛共有十名角色：八名村民和两名 Nenek Kebayan。",
    "விளையாட்டைத் தொடங்கு → நண்பர்களுடன் விளையாடு, தனியாகப் போட்களுடன் விளையாடு அல்லது விரைவு போட்டி.\nநண்பர்கள்: குறியீட்டுடன் தனி அறையை உருவாக்கவும் அல்லது சேரவும். குறைந்தது இரண்டு மனித வீரர்கள் தயாரானதும் அறைத் தலைவர் தொடங்கலாம்.\nதனி: இணையமின்றி ஒரு கிராமவாசியாக ஒன்பது போட்களுடன் விளையாடவும்.\nவிரைவு போட்டி 60 வினாடிகள் வரை வீரர்களைத் தேடும்; பின்னர் காலியிடங்களைப் போட்கள் நிரப்பும்.\nஒவ்வொரு போட்டியிலும் பத்து கதாபாத்திரங்கள்: எட்டு கிராமவாசிகள் மற்றும் இரண்டு Nenek Kebayan."
  ],
  [
    "Villagers",
    "Orang Kampung",
    "村民",
    "கிராமவாசிகள்"
  ],
  [
    "Complete all twelve tasks and find both Nenek Kebayan to win. Follow task routes, inspect clues, and compare observations.",
    "Selesaikan semua dua belas tugas dan cari kedua-dua Nenek Kebayan untuk menang. Ikuti laluan tugas, periksa petunjuk dan bandingkan pemerhatian.",
    "完成全部十二项任务并找出两位 Nenek Kebayan 即可获胜。沿任务路线前进、检查线索并互相核对观察结果。",
    "வெற்றி பெற பன்னிரண்டு பணிகளையும் முடித்து இரண்டு Nenek Kebayan-களையும் கண்டுபிடிக்கவும். பணி வழிகளைப் பின்பற்றி, தடயங்களைப் பார்த்து, கவனித்தவற்றை ஒப்பிடவும்."
  ],
  [
    "Nenek Kebayan",
    "Nenek Kebayan",
    "Nenek Kebayan",
    "Nenek Kebayan"
  ],
  [
    "Blend in with the Villagers and use your abilities carefully. Sleep Spell puts human Villagers to sleep for the rest of the match; they can move but cannot chat, vote, or complete tasks. Fog lasts 20 seconds; Door Lock lasts 10 seconds. Both abilities recharge in two minutes.",
    "Bersembunyi dalam kalangan Orang Kampung dan gunakan kebolehan dengan cermat. Mantera Tidur membuat pemain manusia tidur sehingga perlawanan tamat; mereka masih boleh bergerak tetapi tidak boleh berbual, mengundi atau menyelesaikan tugas. Kabus berlangsung selama 20 saat; Kunci Pintu selama 10 saat. Kedua-dua kebolehan dicas semula dalam masa dua minit.",
    "混入村民之中并谨慎使用能力。睡眠法术会让真人村民睡到本局结束；他们仍可移动，但不能聊天、投票或完成任务。迷雾持续 20 秒；锁门持续 10 秒。两种能力都需要两分钟冷却。",
    "கிராமவாசிகளுடன் கலந்து, உங்கள் திறன்களை கவனமாகப் பயன்படுத்தவும். தூக்க மந்திரம் மனித கிராமவாசிகளை போட்டி முடியும் வரை தூங்கச் செய்யும்; அவர்கள் நகரலாம், ஆனால் அரட்டை, வாக்கு அல்லது பணிகளைச் செய்ய முடியாது. மூடுபனி 20 வினாடிகள் நீடிக்கும்; கதவுப் பூட்டு 10 வினாடிகள் நீடிக்கும். இரு திறன்களும் மீண்டும் தயாராக இரண்டு நிமிடங்கள் ஆகும்."
  ],
  [
    "Meetings & Voting",
    "Mesyuarat dan Undian",
    "会议与投票",
    "கூட்டமும் வாக்கெடுப்பும்"
  ],
  [
    "Approach the gong and press Interact to call a meeting. Discuss for 45 seconds, then vote or skip within 20 seconds. Votes cannot be changed after submission.",
    "Dekati gong dan tekan Interaksi untuk memanggil mesyuarat. Berbincang selama 45 saat, kemudian undi atau langkau dalam masa 20 saat. Undi yang telah dihantar tidak boleh diubah.",
    "走近锣并按互动键召开会议。讨论 45 秒，然后在 20 秒内投票或跳过。提交后不能更改投票。",
    "கோங்கை அணுகி, தொடர்பு பொத்தானை அழுத்தி கூட்டத்தை அழைக்கவும். 45 வினாடிகள் கலந்துரையாடிய பிறகு, 20 வினாடிகளுக்குள் வாக்களிக்கவும் அல்லது தவிர்க்கவும். சமர்ப்பித்த வாக்கை மாற்ற முடியாது."
  ],
  [
    "Controls",
    "Kawalan",
    "操作方式",
    "கட்டுப்பாடுகள்"
  ],
  [
    "On a phone, drag the touch pad in the lower-left area to move. On a computer, use WASD or the arrow keys. Press E or tap Interact near a task or the gong. Use the map for routes and the journal to review clues.",
    "Pada telefon, seret pad sentuh di bahagian kiri bawah untuk bergerak. Pada komputer, gunakan WASD atau kekunci anak panah. Tekan E atau sentuh Interaksi berhampiran tugas atau gong. Gunakan peta untuk melihat laluan dan jurnal untuk menyemak petunjuk.",
    "手机上拖动左下角的触控区域移动；电脑上使用 WASD 或方向键。靠近任务或铜锣时按 E 或点击互动。使用地图查看路线，并在日志中查看线索。",
    "தொலைபேசியில் நகர, கீழ்-இடது தொடு தளத்தை இழுக்கவும். கணினியில் WASD அல்லது அம்புக்குறிகளைப் பயன்படுத்தவும். பணி அல்லது கோங்கிற்கு அருகில் E அழுத்தவும் அல்லது தொடர்பைத் தட்டவும். வழிகளுக்கு வரைபடத்தையும் தடயங்களை மீண்டும் பார்க்க குறிப்பேட்டையும் பயன்படுத்தவும்."
  ]
]
