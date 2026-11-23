# THE ORCHARD

## Layihə yaddaşı və Claude Pro üçün əsas kontekst sənədi

> Bu sənəd The Orchard layihəsi haqqında indiyə qədər ChatGPT ilə
> paylaşılmış məlumatları bir yerə toplayır. Claude bu sənədi layihənin
> əsas kontekst faylı kimi istifadə etməlidir. Burada təsdiqlənmiş
> qərarlar, planlaşdırılan ideyalar və hələ dəqiqləşdirilməmiş məqamlar
> ayrı göstərilir. Dəqiqləşdirilməmiş detalları özbaşına fakt kimi qəbul
> etmə.

------------------------------------------------------------------------

## 1. Layihənin ümumi təsviri

**Layihənin adı:** The Orchard\
**Layihənin növü:** 2D farming / life simulation / management oyunu\
**Oyun mühərriki:** Godot\
**Hazırlanma forması:** Solo layihə --- oyunu əsasən bir nəfər
hazırlayır.

The Orchard meyvə bağı və təsərrüfat həyatını idarə etmək üzərində
qurulan, zamanla genişləndirilə bilən 2D oyun layihəsidir. Oyunçu öz
təsərrüfatını inkişaf etdirməli, meyvə yetişdirməli, məhsul toplamalı,
məhsullarını satmalı, personajları açmalı və oyun dünyasını tədricən
böyütməlidir.

Layihə Hay Day kimi farming oyunlarından ilham alır, lakin məqsəd həmin
oyunu kopyalamaq deyil. The Orchard öz mexanikalarına, personajlarına,
iqtisadiyyatına və gələcək inkişaf istiqamətlərinə malik orijinal oyun
olmalıdır.

Əsas məqsəd qısa, əvvəlcədən müəyyən edilmiş bir hekayəni bitirmək
deyil. Oyun uzun müddət oynana bilən, yeni sistemlər və məzmun əlavə
etməklə genişləndirilə bilən quruluşa malik olmalıdır.

## 2. Yaradıcılıq istiqaməti və vizual üslub

### Təsdiqlənmiş seçimlər

-   Oyun 2D olacaq.
-   Pixel art əsas vizual istiqamət kimi seçilmir. İstifadəçi pixel art
    üslubundan yorulduğunu bildirib.
-   Həddindən artıq sadə, düz görünən 2D vizual üslub da arzuolunan
    deyil.
-   Üstünlük **hand-painted** --- əl ilə çəkilmiş, rəngli, yumşaq və
    atmosferik vizual üslubadır.
-   Oyun rahat, canlı və özünəməxsus təsərrüfat atmosferi yaratmalıdır.

Vizual istiqamət hazırlanarkən ağaclar, meyvələr, torpaq, tikililər,
personajlar və ətraf mühit eyni bədii üslubda görünməlidir. Ayrı-ayrı
asset-lər bir-birindən fərqli oyunlardan götürülmüş kimi görünməməlidir.

### Vacib qeyd

Hələlik dəqiq rəng palitrası, kamera bucağı, tile ölçüsü, sprite
ölçüləri və animasiya standartları barədə yekun qərar qeydə alınmayıb.
Bunları layihənin texniki və vizual dizayn mərhələsində müəyyənləşdirmək
lazımdır.

## 3. Əsas oyun dövrü (core gameplay loop)

Layihənin indiyə qədərki ideyalarından çıxan əsas oyun dövrü belədir:

1.  Oyunçu bağda fəaliyyət göstərir.
2.  Müxtəlif meyvə ağacları və bitkilər yetişdirir.
3.  Məhsullar yetişdikdən sonra onları toplayır.
4.  Məhsulları tacirə və gələcəkdə digər alıcılara satır.
5.  Satışdan əldə etdiyi gəlirlə təsərrüfatını inkişaf etdirir.
6.  Oyun irəlilədikcə XP qazanır və yeni personajların kilidini açır.
7.  Yeni personajlar, bacarıqlar və gələcək sistemlər oyun imkanlarını
    genişləndirir.

Bu, ilkin konseptual dövrdür. Məhsul yetişmə müddəti, enerji, inventar
tutumu, pul vahidi, səviyyə sistemi və digər balans detalları hələ
dəqiqləşdirilməyib.

## 4. Meyvəçilik və məhsullar

Oyunun əsas mövzularından biri meyvəçilikdir. İndiyə qədər adı çəkilən
meyvələr:

-   Alça
-   Vişnə
-   Tut
-   Albalı
-   Gilas və onun müxtəlif növləri

Məqsəd yalnız bir neçə ağacdan ibarət bağ yaratmaq deyil. Gələcəkdə
müxtəlif ağaclar, meyvələr və onların fərqli növləri əlavə edilə biləcək
sistem qurmaqdır.

### Hələ müəyyən edilməyənlər

-   Hər ağacın böyümə və məhsulvermə müddəti
-   Mövsümlərin olub-olmaması
-   Ağacların suvarılma və qulluq ehtiyacları
-   Məhsul keyfiyyəti və keyfiyyət səviyyələri
-   Meyvələrin satış qiymətlərinin dəqiq hesablanması
-   Emal və istehsal binaları

Bunlar hazır qərarlar deyil; gələcək dizayn zamanı müzakirə edilməlidir.

## 5. Personaj sistemi

Oyunun əvvəlində oyunçu öz əsas personajı ilə başlayacaq.

Digər personajlar başlanğıcdan açıq olmayacaq. Oyunçu XP topladıqca yeni
personajların kilidini aça biləcək.

### Personaj bacarıqları

Gələcəkdə hər personajın özünəməxsus bacarıqları olması nəzərdə tutulur.
Bu bacarıqlar personajları sadəcə görünüş baxımından fərqləndirməməli,
oyunun gedişinə də təsir etməlidir.

Lakin bacarıqların konkret siyahısı, XP tələbləri, personajların açılma
ardıcıllığı və bacarıqların gücü hələ müəyyən edilməyib. Claude bunları
təsdiqlənmiş qərar kimi təqdim etməməlidir.

## 6. Tacir Orxan və iqtisadiyyat sistemi

### Tacir Orxan

Oyunda **Orxan** adlı tacir olacaq. O, oyunçunun yetişdirdiyi və
topladığı məhsulları alacaq.

Orxan sadəcə həmişə eyni qiyməti təklif edən statik mağaza sistemi kimi
nəzərdə tutulmayıb.

### Dinamik qiymət ideyası

Orxanın təklif etdiyi qiymətlər digər oyunçuların məhsulları hansı
qiymətə satmasından da təsirlənə bilər.

Bu ideyanın məqsədi oyun iqtisadiyyatını daha canlı etməkdir. Beləliklə,
satış qiymətləri dəyişə, oyunçuların qərarları bazara təsir göstərə
bilər.

Bu, layihənin fərqləndirici ideyalarından biridir.

### Vacib texniki və dizayn qeydi

Qiymətlərin digər oyunçuların satışlarından necə hesablanacağı hələ
müəyyən edilməyib. Məsələn, orta qiymət, tələb-təklif, satış həcmi və ya
zaman intervalı kimi mexanizmlər barədə yekun qərar yoxdur.

Həmçinin multiplayer, server arxitekturası, oyunçuların bazar
məlumatlarının paylaşılması və məlumatların saxlanması barədə texniki
qərar verilməyib. Buna görə dinamik bazar ideyasını dərhal multiplayer
sisteminin artıq təsdiqlənmiş olması kimi yozmaq olmaz. Əvvəlcə bu
ideyanın texniki cəhətdən necə reallaşdırılacağı araşdırılmalıdır.

## 7. NPC və alıcılar

Orxandan əlavə, gələcəkdə müxtəlif alıcı NPC-lərin oyuna əlavə olunması
planlaşdırılır.

Bu NPC-lər fərqli personajlar ola və müxtəlif məhsullara maraq göstərə
bilərlər. Onların hər birinin öz xarakteri və davranış xüsusiyyətləri
olması ideyası var.

Hələlik NPC-lərin adları, görünüşləri, dialoqları, sifariş mexanikası və
konkret alıcı davranışları müəyyən edilməyib.

## 8. Ailə ağacı və personaj əlaqələri

Əvvəlki müzakirədə aşağıdakı ailə əlaqələri qeyd olunub. Bu məlumatlar
layihənin personajları və ailə ağacı üçün saxlanmalıdır.

``` text
Zöhrə
├── Gulnarə
│   ├── Elman
│   ├── Elxan
│   ├── Elnaz
│   └── Eltac
├── İlqar
│   ├── Duyğu
│   ├── Səid
│   └── Ülkər
└── Aytən
    ├── Vüqar
    ├── Nubar
    └── Zəhrə
```

Bu ailə ağacında adlar və əlaqələr istifadəçinin əvvəl paylaşdığı
formada saxlanılıb. Personajların oyundakı rolları, yaşları,
xarakterləri və hekayədəki funksiyaları barədə əlavə məlumat hələ qeydə
alınmayıb. Bu əlaqələri özbaşına dəyişmək olmaz.

## 9. Texnologiyalar və layihənin texniki vəziyyəti

### İstifadə olunan texnologiyalar

-   Godot --- oyun mühərriki
-   GDScript --- Godot daxilində istifadə edilən skript dili
-   Git / GitHub --- versiyaya nəzarət və layihə fayllarının saxlanması

İstifadəçi C# bilmədiyini bildirib. Buna görə texniki nümunələrdə əsas
seçim GDScript olmalıdır. C# həlli yalnız ayrıca səbəb olduqda və
əvvəlcədən izah edilərək təklif edilməlidir.

### Əvvəl qurulmuş Godot səhnəsi

Layihənin əvvəlki mərhələsində `main.tscn` yaradılmışdı.

Player obyektinin quruluşunda bunlar var idi:

-   `CharacterBody2D`
-   `CollisionShape2D`
-   `Sprite2D`
-   `Camera2D`

Hərəkət üçün `CharacterBody2D` istifadə olunurdu. Sürət dəyəri `200`
olaraq təyin edilmişdi.

Hərəkət istiqamətini hesablamaq üçün aşağıdakı Godot funksiyasından
istifadə edilmişdi:

``` gdscript
Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
```

Bu, əvvəlki texniki vəziyyəti göstərir. Layihənin hazırda həmin
vəziyyətdə olub-olmadığı yoxlanılmalıdır; bunu indiki vəziyyət kimi qəti
qəbul etmə.

### GitHub

GitHub repository adı:

`The_Orchard.git`

İstifadəçi Windows kompüterində Git 2.55.0 versiyasından istifadə
etdiyini bildirmişdi.

## 10. İstifadəçinin öyrənmə və iş üsulu

Bu layihə istifadəçinin solo game development öyrənmə prosesinin də bir
hissəsidir.

Buna görə:

-   Hər şeyi birdən-birə mürəkkəbləşdirmə.
-   Addım-addım izah et.
-   Kod verəndə hansı fayla yazılacağını, hansı node-a əlavə ediləcəyini
    və Godot Editor-da hansı əməliyyatların görüləcəyini dəqiq göstər.
-   Kodun nə etdiyini izah et; sadəcə hazır kodu atıb keçmə.
-   İstifadəçi C# bilmədiyi üçün GDScript-dən istifadə et.
-   Mövcud layihə strukturunu görmədən faylları və node-ları kor-koranə
    dəyişmə.
-   Bir mərhələni işlək vəziyyətə gətirmədən çoxsaylı yeni sistemlərə
    keçmə.
-   Lazım olduqda əvvəlcə arxitekturanı planlaşdır, sonra kodlaşdır.
-   Kod nümunələri Godot-un istifadə olunan versiyasına uyğun olmalıdır;
    versiya məlum deyilsə, əvvəlcə soruş.
-   Bir problemi həll edərkən işləyən hissələri lazımsız yerə yenidən
    yazma.

İstifadəçi oyunun təkcə işləməsini deyil, gələcəkdə böyüdülə bilən və
səliqəli arxitekturaya malik olmasını istəyir.

## 11. Layihənin əsas prinsipləri

The Orchard hazırlanarkən bu prinsiplər qorunmalıdır:

1.  **Orijinallıq:** Hay Day və digər oyunlardan ilham almaq olar, amma
    onların mexanikalarını və görünüşünü olduğu kimi kopyalamaq olmaz.
2.  **Genişlənəbilənlik:** Yeni bitkilər, personajlar, NPC-lər və
    mexanikalar sonradan əlavə edilə bilməlidir.
3.  **Səliqəli arxitektura:** Hər şeyi bir böyük skriptə yığmaq əvəzinə
    sistemləri məntiqli şəkildə ayırmaq lazımdır.
4.  **Vizual bütövlük:** Hand-painted üslub qorunmalıdır; pixel art əsas
    istiqamət deyil.
5.  **Mərhələli inkişaf:** Əvvəl işlək baza, sonra daha mürəkkəb
    mexanikalar.
6.  **İzah edilən kod:** İstifadəçi kodu başa düşərək öyrənməlidir.
7.  **Qərarların qorunması:** İstifadəçinin təsdiqlədiyi adlar, personaj
    əlaqələri və ideyalar səbəbsiz dəyişdirilməməlidir.

## 12. Təsdiqlənmiş məlumatlar və açıq suallar

### Təsdiqlənmiş və qorunmalı məlumatlar

-   Oyunun adı The Orchard-dur.
-   Godot mühərrikində hazırlanır.
-   Solo layihədir.
-   2D farming / life simulation / management istiqamətindədir.
-   Hay Day-dən ilhamlanır, amma kopya olmamalıdır.
-   Pixel art istənilmir; hand-painted vizual üslub üstün tutulur.
-   Oyun genişləndirilə bilən sistemlər üzərində qurulmalıdır.
-   Başlanğıcda öz personajımız olacaq.
-   Digər personajlar XP ilə açılacaq.
-   Personajların fərdi bacarıqları olacaq.
-   Alça, vişnə, tut, albalı və müxtəlif gilas növləri nəzərdə tutulub.
-   Tacir Orxan məhsulları alacaq.
-   Orxanın qiymətləri digər oyunçuların satış qiymətlərindən təsirlənə
    bilər.
-   Gələcəkdə fərqli alıcı NPC-lər əlavə olunacaq.
-   Zöhrə və onun ailə ağacı yuxarıda göstərilən kimidir.
-   İstifadəçi C# bilmir; GDScript ilə addım-addım işləmək daha
    uyğundur.
-   Əvvəl `main.tscn`, Player, `CharacterBody2D`, `CollisionShape2D`,
    `Sprite2D`, `Camera2D` qurulmuşdu.
-   GitHub repository `The_Orchard.git` adlanır.

### Hələ qərarlaşdırılmamış və ya yenidən yoxlanmalı məsələlər

-   Godot versiyası
-   Oyunun dəqiq kamera perspektivi və ölçüləri
-   Xəritənin quruluşu və dünya ölçüsü
-   İnventar sistemi
-   Pul və XP balansı
-   Ağacların yetişmə və məhsulvermə mexanikası
-   Mövsümlər və hava sistemi
-   Crafting / emal sistemi
-   Binalar və təsərrüfat genişləndirilməsi
-   Tapşırıq və quest sistemi
-   NPC dialoqları və süni davranışları
-   Personaj bacarıqlarının konkret siyahısı
-   Multiplayer olub-olmayacağı
-   Orxanın dinamik bazar qiymətlərinin texniki reallaşdırılması
-   Save/load sistemi
-   Səs və musiqi istiqaməti
-   Mobil, PC və ya başqa platformalara çıxış planı

Bu mövzular üzrə təklif verərkən əvvəlcə variantları və onların
üstünlüklərini izah et. İstifadəçi təsdiqləmədən onları layihənin rəsmi
qərarına çevirmə.

## 13. Claude üçün iş təlimatı

Sən The Orchard layihəsinin texniki və yaradıcı inkişafında istifadəçiyə
kömək edən game development köməkçisisən.

Bu sənədi layihənin ilkin yaddaşı kimi qəbul et. İstifadəçinin sonradan
verdiyi yeni qərarlar bu sənəddəki köhnə və ya qeyri-dəqiq məlumatları
yeniləyə bilər.

İş qaydaların:

1.  Əvvəlcə istifadəçinin hazırkı layihə fayllarını, səhnə ağacını və
    mövcud kodunu nəzərə al.
2.  Mövcud vəziyyəti bilmədən layihənin strukturunu dəyişmə.
3.  Hər böyük funksiyanı kiçik mərhələlərə böl.
4.  Hər mərhələdə konkret nəticə və yoxlama addımı göstər.
5.  Kodun hansı fayla yerləşdiriləcəyini dəqiq yaz.
6.  Node adlarını, fayl adlarını və dəyişənləri ardıcıl saxla.
7.  Mövcud işlək sistemi pozacaq dəyişikliklərdən çəkin.
8.  Yeni ideya təklif edəndə onun artıq təsdiqlənmiş qərar, yoxsa sadəcə
    təklif olduğunu açıq bildir.
9.  İstifadəçinin təsdiqlədiyi oyun dizaynı qərarlarını özbaşına
    dəyişmə.
10. Lazımsız mürəkkəb sistemlər qurma; amma gələcək genişlənməni də
    nəzərə al.
11. İstifadəçiyə yalnız kod deyil, qərarların səbəbini də öyrət.
12. Bir addımın nəticəsi yoxlanmadan növbəti böyük mərhələyə keçmə.

**Əsas məqsəd:** The Orchard-u tələsmədən, öyrənərək, texniki cəhətdən
səliqəli və gələcəkdə genişləndirilə bilən orijinal 2D oyun kimi
yaratmaq.

------------------------------------------------------------------------

## 14. Yeni məlumatlar üçün layihə qeydləri

Bu bölmə gələcəkdə yeni qərarları əlavə etmək üçün nəzərdə tutulub.

Hər yeni qərarı bu formatda qeyd et:

-   **Tarix:**
-   **Mövzu:**
-   **Qərar:**
-   **Status:** Təsdiqlənib / Sınaqdan keçirilir / Sadəcə ideyadır
-   **Təsir etdiyi sistemlər:**
-   **Əlavə qeydlər:**

Beləliklə, layihənin qərar tarixçəsi qorunacaq və Claude əvvəlki
qərarlarla ziddiyyət yaratmayacaq.
