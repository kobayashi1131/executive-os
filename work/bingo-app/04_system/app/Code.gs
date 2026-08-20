/**
 * bingo-app 用の最小バックエンド（Google Apps Script）。
 * 共有状態(JSON文字列)を1つだけ、スクリプトプロパティに保存する。
 * doGet: 現在の状態を返す。doPost: 状態を丸ごと上書きする。
 *
 * デプロイ方法は work/bingo-app/04_system/app/DEPLOY.md を参照。
 */

function doGet(e) {
  var json = PropertiesService.getScriptProperties().getProperty('STATE') || '';
  return ContentService.createTextOutput(json).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  var body = e.postData.contents;
  // 壊れたJSONは保存しない（既存の状態を守る）
  JSON.parse(body);
  PropertiesService.getScriptProperties().setProperty('STATE', body);
  return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(ContentService.MimeType.JSON);
}
