/**
 * Aura Fishing - Google Apps Script for QA & Task Tracking
 *
 * Setup Instructions:
 * 1. Open the project Google Spreadsheet:
 *    https://docs.google.com/spreadsheets/d/1DTHGPvdOduMTRMj_VMJqrTUPKScIv3Jn0sBjPm_VmDk/edit
 * 2. In Google Sheets menu, click: Extensions > Apps Script
 * 3. Delete any default code in Code.gs, paste this entire file, and click Save (disk icon).
 * 4. In the toolbar, select "setupQASheet" and click "Run".
 * 5. Grant permissions if prompted.
 *
 * What this script does:
 * - Creates/formats the "QA_Tasks" tab using the Aura Fishing Medical Palette.
 * - Sets column widths, freezes the header, and adds Status dropdowns with color rules.
 * - Creates the "Dev_Log" tab (update log / reports) written by tools/sheets/sync.mjs.
 * - Enables automatic timestamping when editing rows directly in Google Sheets.
 * - Provides doGet / doPost endpoints for dashboard synchronization.
 */

const LOG_SHEET = "Dev_Log";
const GUIDE_SHEET = "QA_Guide";

// QA instructions tab, text supplied by tools/sheets/sync.mjs: rows = [[step, text], ...]
function writeGuide(rows) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(GUIDE_SHEET) || ss.insertSheet(GUIDE_SHEET, 0);
  sheet.clear();
  sheet.setTabColor("#E3B341");
  sheet.getRange(1, 1, 1, 2).setValues([["#", "QA guide"]])
    .setBackground("#122056").setFontColor("#FFFFFF").setFontWeight("bold");
  sheet.setColumnWidth(1, 60);
  sheet.setColumnWidth(2, 900);
  if (rows.length) {
    const range = sheet.getRange(2, 1, rows.length, 2);
    range.setNumberFormat("@").setValues(rows.map(r => [String(r[0]), String(r[1])]));
    range.setVerticalAlignment("top");
    sheet.getRange(2, 2, rows.length, 1).setWrap(true);
    sheet.getRange(2, 1, rows.length, 1).setHorizontalAlignment("center");
  }
  return json({ success: true, count: rows.length });
}

function json(value) {
  return ContentService.createTextOutput(JSON.stringify(value)).setMimeType(ContentService.MimeType.JSON);
}

function setupLogSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(LOG_SHEET) || ss.insertSheet(LOG_SHEET);
  sheet.setTabColor("#16653E");
  const headers = ["Time", "Source", "Summary"];
  sheet.getRange(1, 1, 1, headers.length).setValues([headers])
    .setBackground("#122056").setFontColor("#FFFFFF").setFontWeight("bold").setHorizontalAlignment("center");
  sheet.setFrozenRows(1);
  sheet.setColumnWidth(1, 170);
  sheet.setColumnWidth(2, 90);
  sheet.setColumnWidth(3, 820);
  sheet.getRange("A2:B").setHorizontalAlignment("center").setVerticalAlignment("top");
  sheet.getRange("C2:C").setWrap(true).setVerticalAlignment("top");
  return sheet;
}

function readLog() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(LOG_SHEET);
  if (!sheet || sheet.getLastRow() <= 1) return json([]);
  return json(sheet.getRange(2, 1, sheet.getLastRow() - 1, 3).getValues()
    .map(r => ({ time: String(r[0]), source: String(r[1]), summary: String(r[2]) })));
}

function writeLog(rows) {
  const sheet = setupLogSheet();
  if (sheet.getLastRow() > 1) sheet.getRange(2, 1, sheet.getLastRow() - 1, 3).clearContent();
  if (rows.length) {
    // Text format keeps ISO timestamps from being turned into dates.
    sheet.getRange(2, 1, rows.length, 1).setNumberFormat("@");
    sheet.getRange(2, 1, rows.length, 3).setValues(rows.map(r => [String(r[0]), String(r[1]), String(r[2])]));
  }
  return json({ success: true, count: rows.length });
}

function setupQASheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetName = "QA_Tasks";
  let sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
  }

  // Set tab color to palette accent (#5B65DC)
  sheet.setTabColor("#5B65DC");

  // Define headers
  const headers = ["ID", "Type", "System", "Title", "Status", "QA Comment", "Last Updated", "Tester", "How to Test"];
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);

  // Style header row (Medical Palette Dark Navy #122056)
  const headerRange = sheet.getRange(1, 1, 1, headers.length);
  headerRange.setBackground("#122056");
  headerRange.setFontColor("#FFFFFF");
  headerRange.setFontWeight("bold");
  headerRange.setFontSize(10);
  headerRange.setHorizontalAlignment("center");
  headerRange.setVerticalAlignment("middle");
  sheet.setRowHeight(1, 36);
  sheet.setFrozenRows(1);

  // Set column widths
  sheet.setColumnWidth(1, 80);   // ID
  sheet.setColumnWidth(2, 90);   // Type
  sheet.setColumnWidth(3, 120);  // System
  sheet.setColumnWidth(4, 340);  // Title
  sheet.setColumnWidth(5, 140);  // Status
  sheet.setColumnWidth(6, 360);  // QA Comment
  sheet.setColumnWidth(7, 160);  // Last Updated
  sheet.setColumnWidth(8, 110);  // Tester
  sheet.setColumnWidth(9, 520);  // How to Test
  sheet.getRange("I2:I").setWrap(true).setVerticalAlignment("top");
  sheet.getRange("D2:D").setWrap(true);
  sheet.getRange("F2:F").setWrap(true);

  // Alignments
  sheet.getRange("A2:A").setHorizontalAlignment("center").setFontFamily("Consolas");
  sheet.getRange("B2:B").setHorizontalAlignment("center");
  sheet.getRange("C2:C").setHorizontalAlignment("center");
  sheet.getRange("E2:E").setHorizontalAlignment("center");
  sheet.getRange("G2:G").setHorizontalAlignment("center").setFontFamily("Consolas");
  sheet.getRange("H2:H").setHorizontalAlignment("center");

  // Dropdown for Type (Col B)
  const typeRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(["Task", "Bug", "Feature"], true)
    .setAllowInvalid(true)
    .build();
  sheet.getRange("B2:B1000").setDataValidation(typeRule);

  // Dropdown for System (Col C)
  const systemRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(["Fishing", "UI", "Inventory", "Shop", "Save", "Balance", "Audio", "General"], true)
    .setAllowInvalid(true)
    .build();
  sheet.getRange("C2:C1000").setDataValidation(systemRule);

  // Dropdown for Status (Col E)
  const statusValues = ["Completed", "Ready for testing", "In progress", "Bug / Failed", "Not started"];
  const statusRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(statusValues, true)
    .setAllowInvalid(true)
    .build();
  sheet.getRange("E2:E1000").setDataValidation(statusRule);

  // Conditional formatting for Status
  const statusRange = sheet.getRange("E2:E1000");
  const rules = [
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("Completed")
      .setBackground("#e3f5ec")
      .setFontColor("#16653e")
      .setRanges([statusRange])
      .build(),
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("Ready for testing")
      .setBackground("#fffbeb")
      .setFontColor("#b45309")
      .setRanges([statusRange])
      .build(),
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("In progress")
      .setBackground("#eff6ff")
      .setFontColor("#1d4ed8")
      .setRanges([statusRange])
      .build(),
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("Bug / Failed")
      .setBackground("#fee2e2")
      .setFontColor("#b91c1c")
      .setRanges([statusRange])
      .build(),
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("Not started")
      .setBackground("#f1f5f9")
      .setFontColor("#64748b")
      .setRanges([statusRange])
      .build()
  ];
  sheet.setConditionalFormatRules(rules);

  // Tasks are pushed by tools/sheets/sync.mjs (reads docs/TASKS.md); nothing is hard-coded here.
  setupLogSheet();

  Logger.log("QA_Tasks sheet setup successfully completed.");
}

/**
 * Trigger: Automatically update timestamp when editing rows in Google Sheets.
 */
function onEdit(e) {
  if (!e || !e.range) return;
  const sheet = e.range.getSheet();
  if (sheet.getName() !== "QA_Tasks") return;

  const row = e.range.getRow();
  const col = e.range.getColumn();

  // Only trigger for data rows (row > 1) and ignore edits to Col 7 (Last Updated)
  if (row > 1 && col !== 7) {
    const timestamp = Utilities.formatDate(new Date(), "Asia/Bangkok", "yyyy-MM-dd HH:mm:ss");
    sheet.getRange(row, 7).setValue(timestamp);

    // If tester column (Col 8) is blank, fill with active user
    const testerCell = sheet.getRange(row, 8);
    if (!testerCell.getValue()) {
      const email = Session.getActiveUser().getEmail();
      testerCell.setValue(email ? email.split("@")[0] : "QA");
    }
  }
}

/**
 * Optional Web App API: GET returns all QA tasks in JSON format.
 */
function doGet(e) {
  if (e && e.parameter && e.parameter.sheet === LOG_SHEET) return readLog();
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("QA_Tasks");
  if (!sheet) {
    return ContentService.createTextOutput(JSON.stringify({ error: "QA_Tasks sheet not found" }))
      .setMimeType(ContentService.MimeType.JSON);
  }

  const values = sheet.getDataRange().getValues();
  if (values.length <= 1) {
    return ContentService.createTextOutput(JSON.stringify([]))
      .setMimeType(ContentService.MimeType.JSON);
  }

  const tasks = [];
  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    if (!row[0]) continue;
    tasks.push({
      id: String(row[0]),
      type: String(row[1] || "Task"),
      group: String(row[2] || "General"),
      title: String(row[3] || ""),
      status: String(row[4] || "testing"),
      qaComment: String(row[5] || ""),
      updatedAt: String(row[6] || ""),
      tester: String(row[7] || "QA"),
      howTo: String(row[8] || "")
    });
  }

  return ContentService.createTextOutput(JSON.stringify(tasks))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Optional Web App API: POST accepts JSON array of QA tasks and overwrites the sheet.
 */
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    // { sheet: "Dev_Log", rows: [[time, source, summary], ...] } replaces the whole log tab.
    if (data && data.sheet === LOG_SHEET) return writeLog(data.rows || []);
    if (data && data.sheet === GUIDE_SHEET) return writeGuide(data.rows || []);
    if (!Array.isArray(data)) {
      return ContentService.createTextOutput(JSON.stringify({ error: "Expected an array of tasks" }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("QA_Tasks");
    if (!sheet) {
      setupQASheet();
      sheet = ss.getSheetByName("QA_Tasks");
    }

    // Keep header; remember "How to Test" per ID so dashboard pushes (which omit it) do not wipe it.
    const lastRow = sheet.getLastRow();
    const howTo = {};
    if (lastRow > 1) {
      sheet.getRange(2, 1, lastRow - 1, 9).getValues().forEach(r => { howTo[r[0]] = r[8]; });
      sheet.getRange(2, 1, lastRow - 1, 9).clearContent();
    }

    const rows = data.map(task => [
      task.id || "",
      task.type || "Task",
      task.group || "General",
      (typeof task.name === "object" ? (task.name.th || task.name.en) : task.name) || task.title || "",
      task.status || "testing",
      task.qaComment || task.note || "",
      task.updatedAt || Utilities.formatDate(new Date(), "Asia/Bangkok", "yyyy-MM-dd HH:mm:ss"),
      task.updatedBy || task.tester || "QA",
      task.howTo !== undefined ? task.howTo : (howTo[task.id] || "")
    ]);

    if (rows.length > 0) {
      sheet.getRange(2, 1, rows.length, 9).setValues(rows);
    }

    return ContentService.createTextOutput(JSON.stringify({ success: true, count: rows.length }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ error: err.message }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
