# 見積書を作る（職人・業者の見積の読み取り結果 → わしの建設の原紙に書き込んだExcel）
#
# 使い方:
#   powershell -NoProfile -ExecutionPolicy Bypass -File make-mitsumori.ps1 -In 入力.json [-Template 原紙.xltx] [-OutDir 保存先]
#
# 値付けのルール（mitsumori-rules.md）はここで計算する。Claudeは計算せず、読み取った内容をJSONで渡すだけ。
# Excel本体に書き込むので、原紙のロゴ・社印・書式はそのまま残る。

param(
  [Parameter(Mandatory = $true)][string]$In,
  [string]$Template = '',
  [string]$OutDir = ''
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Template) { $Template = Join-Path $here 'genshi.local.xltx' }
if (-not $OutDir) { $OutDir = Join-Path $here 'out' }

# ===== ルール =====
$RULE = @{
  markup      = 1.5     # 売値 = 原価 × これ
  overheadPct = 8       # 諸経費 = 明細合計 × これ%
  dayRate     = 25000   # わしのの人 1日（売値）
  dayCost     = 25000   # わしのの人 1日（原価）
  targetGp    = 25      # 値引き後の粗利率がこれ%を超えるようにする
  roundUnit   = 10000   # 値引き後の金額をこの単位にそろえる
}
$FIRST_ROW = 10; $LAST_ROW = 31   # 原紙の明細欄

function N($v) { if ($null -eq $v -or "$v" -eq '') { return 0.0 } ; return [double]("$v" -replace '[,，¥￥円\s]', '') }
function RoundHalfUp([double]$x) { return [math]::Floor($x + 0.5) }   # JavaScriptの Math.round と同じ丸め
# Excelのセルに数字を入れる（PowerShellからだと Value2 に数値を直接入れられないため、式として数字を書く）
function SetNum($cell, $v) { $cell.Formula = ([double]$v).ToString([Globalization.CultureInfo]::InvariantCulture) }
function Has($o, $name) { return $null -ne $o -and $o.PSObject.Properties.Name -contains $name -and $null -ne $o.$name -and "$($o.$name)" -ne '' }

$job = Get-Content -Raw -Encoding UTF8 $In | ConvertFrom-Json
$markup = if (Has $job 'markup') { N $job.markup } else { $RULE.markup }

# ===== 業者ごとの読み取り結果 → 明細 =====
$items = New-Object System.Collections.ArrayList
$overheadCost = 0.0; $overheadWho = @(); $notes = New-Object System.Collections.ArrayList
foreach ($v in $job.vendors) {
  $vendor = "$($v.vendor)".Trim()
  $rows = @($v.items | Where-Object { $_.name -and (N $_.amount) -ne 0 })
  $sum = ($rows | ForEach-Object { N $_.amount } | Measure-Object -Sum).Sum
  # NET金額があれば、各行の原価をその割合で割り振る（端数は一番大きい行で調整）
  $net = if (Has $v 'net_total') { N $v.net_total } else { 0 }
  $f = if ($net -gt 0 -and $net -lt $sum) { $net / $sum } else { 1.0 }
  $costs = @($rows | ForEach-Object { RoundHalfUp ((N $_.amount) * $f) })
  if ($f -ne 1.0 -and $costs.Count) {
    $big = [array]::IndexOf($costs, ($costs | Measure-Object -Maximum).Maximum)
    $costs[$big] += $net - ($costs | Measure-Object -Sum).Sum
  }
  $keihi = 0.0
  for ($i = 0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    if ("$($r.kind)" -eq 'keihi') { $keihi += $costs[$i]; continue }
    # 数量の小数は切り上げ（56.4m → 57m）。単価は職人見積の単価 × 掛け率
    $q = if ((N $r.qty) -gt 0) { N $r.qty } else { 1.0 }
    $qty = [math]::Ceiling($q)
    $unit = if ($r.unit) { "$($r.unit)" } else { '式' }
    $cost = $costs[$i]
    if ($unit -ne '式' -and $qty -gt 1) {
      $price = [math]::Ceiling(($cost / $q) * $markup / 10) * 10; $amount = $qty * $price
    } else {
      $price = $null; $amount = [math]::Ceiling($cost * $markup / 100) * 100
    }
    [void]$items.Add([pscustomobject]@{ name = "$($r.name)"; qty = $qty; unit = $unit; price = $price; amount = $amount; cost = $cost; who = $vendor; note = ''; check = [bool]$r.check })
  }
  if ($keihi) { $overheadCost += $keihi; if ($vendor) { $overheadWho += "$vendor（諸経費・出張費）" } }
  foreach ($n in @($v.notes)) { if ($n -and -not $notes.Contains("$n")) { [void]$notes.Add("$n") } }
}
foreach ($n in @($job.notes)) { if ($n -and -not $notes.Contains("$n")) { [void]$notes.Add("$n") } }

# ===== 現場管理費・諸経費・値引き =====
$days = if (Has $job 'labor_days') { N $job.labor_days } else { 0 }
if ($days) {
  $n = if ($days -eq 0.5) { '半日' } else { "${days}人工" }
  $who = if (Has $job 'labor_who') { "わしの建設（$($job.labor_who) $n）" } else { "わしの建設（$n）" }
  [void]$items.Add([pscustomobject]@{ name = '現場管理費'; qty = 1; unit = '式'; price = $null; amount = $days * $RULE.dayRate; cost = $days * $RULE.dayCost; who = $who; note = ''; check = $false })
}
$base = ($items | ForEach-Object { $_.amount } | Measure-Object -Sum).Sum
$overhead = if (Has $job 'overhead') { N $job.overhead } else { (RoundHalfUp ($base * $RULE.overheadPct / 100 / 100)) * 100 }
if ($overhead -or $overheadCost) {
  [void]$items.Add([pscustomobject]@{ name = '諸経費'; qty = 1; unit = '式'; price = $null; amount = $overhead; cost = $overheadCost; who = ($overheadWho -join '、'); note = ''; check = $false })
}
$pre = ($items | ForEach-Object { $_.amount } | Measure-Object -Sum).Sum
$cost = ($items | ForEach-Object { N $_.cost } | Measure-Object -Sum).Sum
$goal = if ($cost) { [math]::Ceiling($cost / (1 - $RULE.targetGp / 100) / $RULE.roundUnit) * $RULE.roundUnit } else { 0 }
$discount = if (Has $job 'discount') { - [math]::Abs((N $job.discount)) } elseif ($goal -and $pre -gt $goal) { $goal - $pre } else { 0 }
$sub = $pre + $discount
$gp = if ($sub) { ($sub - $cost) / $sub } else { 0 }

# 原紙に書く行の並び：明細 → 3行下に値引き（中央揃え）→ その下に注意書き（左寄せ）
$sheet = New-Object System.Collections.ArrayList
foreach ($it in $items) { [void]$sheet.Add(@{ type = 'item'; it = $it }) }
if ($discount) { [void]$sheet.Add(@{ type = 'blank' }); [void]$sheet.Add(@{ type = 'blank' }); [void]$sheet.Add(@{ type = 'discount' }) }
foreach ($n in $notes) { [void]$sheet.Add(@{ type = 'note'; text = $n }) }
if ($sheet.Count -gt ($LAST_ROW - $FIRST_ROW + 1)) { throw "明細・値引き・注意書きで$($sheet.Count)行あります。原紙に入るのは$($LAST_ROW - $FIRST_ROW + 1)行までです。" }

# 作業日「10/18，19，25，26」（月が変わる時だけ月を書く）
$datesText = ''
if (Has $job 'dates') {
  $prevM = 0; $parts = @()
  foreach ($d in (@($job.dates) | ForEach-Object { [datetime]$_ } | Sort-Object)) {
    $parts += $(if ($d.Month -eq $prevM) { "$($d.Day)" } else { "$($d.Month)/$($d.Day)" }); $prevM = $d.Month
  }
  $datesText = $parts -join '，'
}

# ===== Excelに書き込む =====
if (-not (Test-Path $Template)) { throw "原紙が見つかりません: $Template" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$date = if (Has $job 'date') { [datetime]$job.date } else { Get-Date }
$title = "$($job.title)"
$fileBase = (($title, "$($job.client)", '見積' | Where-Object { $_ } | Select-Object -First 1) -replace '[\\/:*?"<>|\s　]', '') + $date.ToString('yyMM')
$out = Join-Path (Resolve-Path $OutDir) "$fileBase.xlsx"

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
try {
  $wb = $xl.Workbooks.Add((Resolve-Path $Template).Path)   # 原紙(.xltx)から新しいブックを作る
  $ws = $wb.Worksheets.Item(1)
  $ws.Range('A4').Value2 = "$($job.client)"
  $ws.Range('B4').Value2 = $(if (Has $job 'honor') { "$($job.honor)" } else { '御中' })
  $ws.Range('F4').Formula = [string][int]$date.ToOADate()   # 日付（原紙の書式で「令和◯年◯月◯日」と出る）
  $ws.Range('A8').Value2 = $title
  $ws.Range('F8').Value2 = $datesText
  $ws.Range("A${FIRST_ROW}:H${LAST_ROW}").ClearContents() | Out-Null
  for ($k = 0; $k -lt $sheet.Count; $k++) {
    $r = $FIRST_ROW + $k; $row = $sheet[$k]
    switch ($row.type) {
      'blank' { }
      'discount' {
        $ws.Range("A$r").Value2 = '値引き'; $ws.Range("A$r").HorizontalAlignment = -4108   # 中央揃え
        SetNum $ws.Range("E$r") $discount
      }
      'note' { $ws.Range("A$r").Value2 = $row.text; $ws.Range("A$r").HorizontalAlignment = -4131 }   # 左寄せ
      'item' {
        $it = $row.it
        $ws.Range("A$r").Value2 = $it.name; $ws.Range("A$r").HorizontalAlignment = -4131
        SetNum $ws.Range("B$r") $it.qty
        $ws.Range("C$r").Value2 = $it.unit
        if ($null -ne $it.price) { SetNum $ws.Range("D$r") $it.price; $ws.Range("E$r").Formula = "=B$r*D$r" }
        else { SetNum $ws.Range("E$r") $it.amount }
        if ($it.note) { $ws.Range("F$r").Value2 = $it.note }
        if ($it.cost) { SetNum $ws.Range("G$r") $it.cost }   # 原価（印刷範囲外）
        if ($it.who) { $ws.Range("H$r").Value2 = $it.who }     # 職人・業者名
      }
    }
  }
  $xl.CalculateFull()
  $wb.SaveAs($out, 51)   # 51 = .xlsx
  $wb.Close($false)
} finally {
  $xl.Quit()
  [void][Runtime.InteropServices.Marshal]::ReleaseComObject($xl)
}

# ===== 結果 =====
"保存: $out"
"値引き前 {0:N0} / 値引き {1:N0} / 小計 {2:N0} / 税込 {3:N0}" -f $pre, $discount, $sub, ($sub * 1.1)
"原価 {0:N0} / 粗利 {1:N0}（{2:P1}）" -f $cost, ($sub - $cost), $gp
$checks = @($items | Where-Object { $_.check })
if ($checks.Count) { "要確認（読み取りに自信がない行）: " + (($checks | ForEach-Object { $_.name }) -join '、') }
