param([string]$OutPath)
# A3 / S=1/30 。モデル空間は実寸mm。A3枠 = 420x297 x30 = 12600x8910
$sb = New-Object System.Text.StringBuilder
function W($s){ [void]$sb.AppendLine($s) }
function F([double]$v){ $v.ToString("0.###",[Globalization.CultureInfo]::InvariantCulture) }
function L([double]$x1,[double]$y1,[double]$x2,[double]$y2,$layer){ W "0";W "LINE";W "8";W $layer;W "10";W (F $x1);W "20";W (F $y1);W "30";W "0";W "11";W (F $x2);W "21";W (F $y2);W "31";W "0" }
function Rect($x1,$y1,$x2,$y2,$layer){ L $x1 $y1 $x2 $y1 $layer; L $x2 $y1 $x2 $y2 $layer; L $x2 $y2 $x1 $y2 $layer; L $x1 $y2 $x1 $y1 $layer }
function C($x,$y,$r,$layer){ W "0";W "CIRCLE";W "8";W $layer;W "10";W (F $x);W "20";W (F $y);W "30";W "0";W "40";W (F $r) }
# h: 0=左 1=中央 2=右
function T($x,$y,$ht,$txt,$layer,$h=0,$rot=0){
  W "0";W "TEXT";W "8";W $layer;W "10";W (F $x);W "20";W (F $y);W "30";W "0";W "40";W (F $ht);W "1";W $txt
  if($rot -ne 0){ W "50";W (F $rot) }
  if($h -ne 0){ W "72";W "$h";W "11";W (F $x);W "21";W (F $y);W "31";W "0" }
}
function Hatch([double]$x1,[double]$y1,[double]$x2,[double]$y2,[double]$s,$layer){
  for($k=$x1-$y2+$s; $k -lt $x2-$y1; $k+=$s){
    $ya=[Math]::Max($y1,$x1-$k); $yb=[Math]::Min($y2,$x2-$k)
    if($ya -lt $yb){ L ($ya+$k) $ya ($yb+$k) $yb $layer }
  }
}
$DT=75  # 寸法文字 2.5mm x30
function DimH($x1,$x2,$y,$yref,$txt,$t=$DT){
  L $x1 $y $x2 $y "DIM"; L $x1 $yref $x1 ($y+60*[Math]::Sign($y-$yref)) "DIM"; L $x2 $yref $x2 ($y+60*[Math]::Sign($y-$yref)) "DIM"
  L ($x1-40) ($y-40) ($x1+40) ($y+40) "DIM"; L ($x2-40) ($y-40) ($x2+40) ($y+40) "DIM"
  T (($x1+$x2)/2) ($y+30) $t $txt "DIM" 1
}
function DimV($y1,$y2,$x,$xref,$txt,$t=$DT){
  L $x $y1 $x $y2 "DIM"; L $xref $y1 ($x+60*[Math]::Sign($x-$xref)) $y1 "DIM"; L $xref $y2 ($x+60*[Math]::Sign($x-$xref)) $y2 "DIM"
  L ($x-40) ($y1-40) ($x+40) ($y1+40) "DIM"; L ($x-40) ($y2-40) ($x+40) ($y2+40) "DIM"
  T ($x-30) (($y1+$y2)/2) $t $txt "DIM" 1 90
}

# ---------- HEADER / TABLES ----------
W "0";W "SECTION";W "2";W "HEADER"
W "9";W '$ACADVER';W "1";W "AC1009"
W "9";W '$DWGCODEPAGE';W "3";W "ANSI_932"
W "9";W '$INSUNITS';W "70";W "4"
W "9";W '$EXTMIN';W "10";W "0";W "20";W "0";W "30";W "0"
W "9";W '$EXTMAX';W "10";W "12600";W "20";W "8910";W "30";W "0"
W "0";W "ENDSEC"
W "0";W "SECTION";W "2";W "TABLES"
W "0";W "TABLE";W "2";W "LAYER";W "70";W "7"
foreach($ly in @(@("WAKU",7),@("GAIKEI",7),@("STEEL",5),@("COVER",1),@("SHITAJI",6),@("DIM",3),@("MOJI",7))){
  W "0";W "LAYER";W "2";W $ly[0];W "70";W "0";W "62";W "$($ly[1])";W "6";W "CONTINUOUS"
}
W "0";W "ENDTAB";W "0";W "ENDSEC"
W "0";W "SECTION";W "2";W "ENTITIES"

# ---------- 図枠・表題欄 ----------
Rect 0 0 12600 8910 "WAKU"
Rect 300 300 12300 8610 "WAKU"
Rect 8700 300 12300 1200 "WAKU"
L 8700 750 12300 750 "WAKU"; L 9600 300 9600 1200 "WAKU"; L 11100 300 11100 750 "WAKU"
T 8800 900 90 "件名" "MOJI"; T 9700 880 150 "板金カバー工事（H1800 全面）" "MOJI"
T 8800 450 90 "図面" "MOJI"; T 9700 450 120 "平面・立面・樋断面詳細図" "MOJI"
T 11200 450 90 "A3 S=1/30" "MOJI"
T 600 8250 180 "赤部：H1800 板金カバー 全面" "MOJI"
T 600 8000 90 "※手書きスケッチより作図。高さ・取合いは要現場確認" "MOJI"

# ---------- 正面図 (3390面) ----------
$x0=900; $g=4900
L ($x0-300) $g ($x0+3690) $g "GAIKEI"                 # GL
Rect $x0 $g ($x0+100) ($g+2200) "STEEL"                   # 柱 H-200x100
Rect ($x0+3290) $g ($x0+3390) ($g+2200) "STEEL"
Rect $x0 ($g+2200) ($x0+3390) ($g+2400) "STEEL"           # 梁 H-200x100
L $x0 ($g+2215) ($x0+3390) ($g+2215) "STEEL"; L $x0 ($g+2385) ($x0+3390) ($g+2385) "STEEL"
Rect ($x0-100) ($g+2400) ($x0+3490) ($g+2488) "GAIKEI"    # 折板
for($xx=$x0-100; $xx -lt $x0+3490; $xx+=200){ L $xx ($g+2400) $xx ($g+2488) "GAIKEI" }
Rect ($x0-100) ($g+2330) ($x0+3490) ($g+2400) "COVER"     # 鼻隠し(水切)
Rect $x0 $g ($x0+3390) ($g+1800) "COVER"                  # 板金カバー H1800
Hatch $x0 $g ($x0+3390) ($g+1800) 300 "COVER"
T ($x0+1695) ($g+2050) 105 "H-200×100" "MOJI" 1
T ($x0+3700) ($g+2430) 90 "折板" "MOJI"
T ($x0+1695) ($g+900) 105 "板金カバー（赤部）" "MOJI" 1
DimH $x0 ($x0+3390) ($g-350) $g "3,390"
DimV $g ($g+1800) ($x0-350) $x0 "1,800"
DimV $g ($g+2400) ($x0-600) $x0 "2,400(仮)"
T ($x0+1695) ($g-650) 150 "正面図  S=1/30" "MOJI" 1

# ---------- 側面図 (2549面) ----------
$x1=5300
L ($x1-300) $g ($x1+2849) $g "GAIKEI"
Rect ($x1+24.5) $g ($x1+124.5) ($g+2200) "STEEL"
Rect ($x1+2424.5) $g ($x1+2524.5) ($g+2200) "STEEL"
Rect $x1 ($g+2200) ($x1+2549) ($g+2400) "STEEL"
Rect ($x1-150) ($g+2400) ($x1+2699) ($g+2488) "GAIKEI"
Rect $x1 $g ($x1+2549) ($g+1800) "COVER"
Hatch $x1 $g ($x1+2549) ($g+1800) 300 "COVER"
DimH $x1 ($x1+2549) ($g-350) $g "2,549"
DimH ($x1+74.5) ($x1+2474.5) ($g+2750) ($g+2488) "2,400（柱芯 推定）"
T ($x1+1275) ($g-650) 150 "側面図  S=1/30" "MOJI" 1

# ---------- 平面図 ----------
$px=1200; $py=1100; $W=3390; $D=2549
# H鋼 (四隅) 外面からカバー・下地 30
foreach($c in @(@(30,30),@(($W-130),30),@(30,($D-230)),@(($W-130),($D-230)))){
  $cx=$px+$c[0]; $cy=$py+$c[1]
  Rect $cx $cy ($cx+100) ($cy+200) "STEEL"
}
# 板金カバー 左・上・右 (赤)
L $px $py $px ($py+$D) "COVER"; L $px ($py+$D) ($px+$W) ($py+$D) "COVER"; L ($px+$W) ($py+$D) ($px+$W) $py "COVER"
L ($px+15) $py ($px+15) ($py+$D-15) "COVER"; L ($px+15) ($py+$D-15) ($px+$W-15) ($py+$D-15) "COVER"; L ($px+$W-15) ($py+$D-15) ($px+$W-15) $py "COVER"
# 下地
L ($px+30) ($py+230) ($px+30) ($py+$D-230) "SHITAJI"; L ($px+130) ($py+$D-30) ($px+$W-130) ($py+$D-30) "SHITAJI"; L ($px+$W-30) ($py+230) ($px+$W-30) ($py+$D-230) "SHITAJI"
# フェンス (下側)
L ($px-400) ($py-60) ($px+$W) ($py-60) "GAIKEI"; L ($px-400) ($py-90) ($px+$W) ($py-90) "GAIKEI"
T ($px+$W/2) ($py+$D/2) 105 "（内部）" "MOJI" 1
T ($px+$W+150) ($py+$D-150) 90 "板金カバー" "MOJI"; T ($px+$W+150) ($py+$D-300) 90 "下地" "MOJI"; T ($px+$W+150) ($py+$D-450) 90 "H鋼" "MOJI"
T ($px-400) ($py-250) 90 "フェンス" "MOJI"
DimH $px ($px+$W) ($py+$D+300) ($py+$D) "3,390"
DimV $py ($py+$D) ($px-300) $px "2,549"
T ($px+$W/2) ($py-550) 150 "平面図  S=1/30" "MOJI" 1

# ---------- 樋断面詳細 S=1/5 (1/30図面上で6倍描き) ----------
$k=6; $dx=10550; $dy=3680
function DL([double]$a,[double]$b,[double]$c,[double]$d,$ly){ L ($dx+$a*$k) ($dy+$b*$k) ($dx+$c*$k) ($dy+$d*$k) $ly }
function DR([double]$a,[double]$b,[double]$c,[double]$d,$ly){ Rect ($dx+$a*$k) ($dy+$b*$k) ($dx+$c*$k) ($dy+$d*$k) $ly }
# H-200x100 断面
DR 0 0 100 8 "STEEL"; DR 0 192 100 200 "STEEL"; DR 46.5 8 53.5 192 "STEEL"
# 折板 (梁上 88)
DL -150 200 250 200 "GAIKEI"; DL -150 288 250 288 "GAIKEI"; DL -150 200 -150 288 "GAIKEI"
# 軒樋 (左側に吊り)
DL -150 270 -175 270 "GAIKEI"; DL -175 270 -175 150 "GAIKEI"; DL -175 150 -300 150 "GAIKEI"; DL -300 150 -300 260 "GAIKEI"; DL -300 260 -285 260 "GAIKEI"
# 下地 (□-30x30)
DR -35 150 -5 180 "SHITAJI"; DR -35 20 -5 50 "SHITAJI"
# 板金カバー (赤) 梁外面を包む
DL -40 300 -40 -60 "COVER"; DL -40 300 -150 300 "COVER"; DL -40 -60 -20 -60 "COVER"
T ($dx-300*$k) ($dy+340*$k) 90 "折板" "MOJI"
T ($dx-300*$k) ($dy+120*$k) 90 "軒樋" "MOJI"
T ($dx+150*$k) ($dy+100*$k) 90 "H-200×100" "MOJI"
T ($dx-30*$k) ($dy-90*$k) 90 "板金カバー" "MOJI"
T ($dx-170*$k) ($dy+60*$k) 75 "下地□" "MOJI"
L ($dx+120*$k) $dy ($dx+120*$k) ($dy+200*$k) "DIM"; T ($dx+135*$k) ($dy+100*$k) $DT "200" "DIM" 1 90
C ($dx-25*$k) ($dy+120*$k) (300*$k) "GAIKEI"
T ($dx-25*$k) ($dy-260*$k) 150 "樋断面詳細  S=1/5" "MOJI" 1

W "0";W "ENDSEC";W "0";W "EOF"
[System.IO.File]::WriteAllText($OutPath, $sb.ToString(), [System.Text.Encoding]::GetEncoding(932))
"ok"
