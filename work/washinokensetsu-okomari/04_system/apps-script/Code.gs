/**
 * お困りごとポスト（社内テスト版）
 * Googleスプレッドシートに紐づけた Apps Script として動かす。
 * - 建物系の声: 「受付」シートに中身ごと記録（わしの建設のリスト）
 * - 人間関係・お給料／「社長だけ」: 中身は社長にメールで送り、シートには番号と分類だけ残す
 */

const SHEET_LIST = '受付';
const SHEET_CUSTOMERS = 'お客さん';
const CATS = ['建物・設備', '作業場・道具', '危ない所', '人間関係', 'お給料・待遇', 'その他'];
const PRIVATE_CATS = ['人間関係', 'お給料・待遇'];
const STATUS = ['受け付けました', '社長に届けました', '対応しました'];
const FIXED_BY = ['わしの建設', '社内'];
const LIST_HEADER = ['受付番号', '日時', '会社記号', '会社名', '分類', '場所', '内容', '名前', '写真', '社長直送', '見積候補', '状況', '直した所', 'メモ'];
const DEFAULT_CODE = 'washino';

/** 最初に1回だけ、エディタから実行する */
function setup() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const props = PropertiesService.getScriptProperties();
  props.setProperty('SHEET_ID', ss.getId());

  let list = ss.getSheetByName(SHEET_LIST);
  if (!list) {
    list = ss.getSheets()[0];
    list.setName(SHEET_LIST);
  }
  if (list.getLastRow() === 0) {
    list.appendRow(LIST_HEADER);
    list.setFrozenRows(1);
    list.getRange(1, 1, 1, LIST_HEADER.length).setFontWeight('bold').setBackground('#EAF1F8');
    list.setColumnWidth(7, 320);
  }

  let cu = ss.getSheetByName(SHEET_CUSTOMERS);
  if (!cu) {
    cu = ss.insertSheet(SHEET_CUSTOMERS);
    cu.appendRow(['会社記号', '会社名', '社長のメール']);
    cu.appendRow([DEFAULT_CODE, '有限会社わしの建設', '']);
    cu.getRange(1, 1, 1, 3).setFontWeight('bold').setBackground('#EAF1F8');
    cu.setColumnWidth(3, 260);
  }

  if (!props.getProperty('FOLDER_ID')) {
    const folder = DriveApp.createFolder('お困りごとポスト_写真');
    props.setProperty('FOLDER_ID', folder.getId());
  }
  SpreadsheetApp.getUi().alert('準備できました。「お客さん」シートの C2 に社長のメールアドレスを入れてください。');
}

function onOpen() {
  SpreadsheetApp.getUi().createMenu('お困りごとポスト')
    .addItem('「受け付けました」を全部「社長に届けました」にする', 'markAllDelivered')
    .addToUi();
}

/** 月1回の報告の後に使う */
function markAllDelivered() {
  const sh = ss_().getSheetByName(SHEET_LIST);
  const last = sh.getLastRow();
  if (last < 2) return;
  const col = LIST_HEADER.indexOf('状況') + 1;
  const range = sh.getRange(2, col, last - 1, 1);
  const values = range.getValues().map(r => [r[0] === STATUS[0] ? STATUS[1] : r[0]]);
  range.setValues(values);
}

function doGet(e) {
  const code = (e && e.parameter && e.parameter.c) ? String(e.parameter.c) : DEFAULT_CODE;
  const cu = getCustomer_(code);
  if (!cu) {
    return HtmlService.createHtmlOutput('<p style="font-family:sans-serif;padding:20px">このQRコードは使えません。わしの建設にお知らせください。</p>');
  }
  const t = HtmlService.createTemplateFromFile('Index');
  t.codeJson = JSON.stringify(cu.code).replace(/</g, '\\u003c');
  t.company = cu.name;
  t.catsJson = JSON.stringify(CATS);
  t.privateJson = JSON.stringify(PRIVATE_CATS);
  return t.evaluate()
    .setTitle('お困りごとポスト')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

/** 画面から呼ばれる。受付番号を返す */
function submit(f) {
  f = f || {};
  const cu = getCustomer_(String(f.code || ''));
  if (!cu) throw new Error('会社が見つかりません。わしの建設にお知らせください。');

  const cat = String(f.cat || '');
  if (CATS.indexOf(cat) < 0) throw new Error('「どんなこと？」を選んでください。');
  const body = String(f.body || '').trim().slice(0, 2000);
  if (!body) throw new Error('困っていることを書いてください。');
  const place = String(f.place || '').trim().slice(0, 100);
  const name = String(f.name || '').trim().slice(0, 50);
  const isPrivCat = PRIVATE_CATS.indexOf(cat) >= 0;
  if (!isPrivCat && !name) throw new Error('名前を書いてください。');
  const toBoss = isPrivCat || f.onlyBoss === true;
  if (toBoss && !/^[^@\s]+@[^@\s]+$/.test(cu.email)) {
    throw new Error('社長への送り先が設定されていません。わしの建設にお知らせください。');
  }
  const photo = f.photo ? photoBlob_(f.photo) : null;

  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const no = nextNo_(cu.code);
    const now = new Date();
    if (photo) photo.setName(no + (photo.getContentType() === 'image/png' ? '.png' : '.jpg'));

    if (toBoss) {
      const lines = [
        cu.name + ' 社長',
        '',
        'お困りごとポストに、社長だけに届ける声がありました。',
        'この内容は、わしの建設のリストには残していません。',
        '',
        '受付番号: ' + no,
        '日時: ' + Utilities.formatDate(now, 'Asia/Tokyo', 'yyyy/MM/dd HH:mm'),
        '分類: ' + cat,
        '場所: ' + (place || '（なし）'),
        '名前: ' + (name || '（書かれていません）'),
        '',
        '内容:',
        body
      ];
      const mail = { to: cu.email, subject: '【お困りごとポスト】社長だけに届く声 ' + no, body: lines.join('\n'), name: 'お困りごとポスト' };
      if (photo) mail.attachments = [photo];
      MailApp.sendEmail(mail);
      appendRow_([no, now, cu.code, cu.name, cat, '', '（社長に直送）', '', '', 'はい', false, STATUS[0], '社内', '']);
    } else {
      let photoUrl = '';
      if (photo) {
        const folder = DriveApp.getFolderById(PropertiesService.getScriptProperties().getProperty('FOLDER_ID'));
        photoUrl = folder.createFile(photo).getUrl();
      }
      appendRow_([no, now, cu.code, cu.name, cat, place, body, name, photoUrl, '', false, STATUS[0], '', '']);
    }
    return no;
  } finally {
    lock.releaseLock();
  }
}

function ss_() {
  return SpreadsheetApp.openById(PropertiesService.getScriptProperties().getProperty('SHEET_ID'));
}

function getCustomer_(code) {
  const rows = ss_().getSheetByName(SHEET_CUSTOMERS).getDataRange().getValues().slice(1);
  const r = rows.find(x => String(x[0]).trim() === code);
  return r ? { code: code, name: String(r[1]), email: String(r[2]).trim() } : null;
}

/** お客さんごとに S-0001 から数える */
function nextNo_(code) {
  const props = PropertiesService.getScriptProperties();
  const key = 'SEQ_' + code;
  const next = Number(props.getProperty(key) || 0) + 1;
  props.setProperty(key, String(next));
  return 'S-' + ('000' + next).slice(-4);
}

function appendRow_(row) {
  const sh = ss_().getSheetByName(SHEET_LIST);
  sh.appendRow(row);
  const r = sh.getLastRow();
  sh.getRange(r, LIST_HEADER.indexOf('見積候補') + 1).insertCheckboxes();
  sh.getRange(r, LIST_HEADER.indexOf('状況') + 1).setDataValidation(
    SpreadsheetApp.newDataValidation().requireValueInList(STATUS, true).build());
  sh.getRange(r, LIST_HEADER.indexOf('直した所') + 1).setDataValidation(
    SpreadsheetApp.newDataValidation().requireValueInList(FIXED_BY, true).setAllowInvalid(false).build());
}

function photoBlob_(dataUrl) {
  const m = /^data:(image\/(?:jpeg|png));base64,([A-Za-z0-9+/=]+)$/.exec(String(dataUrl));
  if (!m) throw new Error('写真の形式が読み込めませんでした。');
  if (m[2].length > 5000000) throw new Error('写真が大きすぎます。');
  return Utilities.newBlob(Utilities.base64Decode(m[2]), m[1]);
}
