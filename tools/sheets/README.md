# Aura Fishing - QA & Task Google Sheets Setup

This folder contains the setup script for the Aura Fishing QA & Task Tracking spreadsheet.

## File
- `setup_qa_sheet.gs`: Google Apps Script source code.

## Quick Setup Steps (ใช้เวลาไม่เกิน 1 นาที)

1. เปิด Google Spreadsheet ของโปรเจกต์:
   `https://docs.google.com/spreadsheets/d/1DTHGPvdOduMTRMj_VMJqrTUPKScIv3Jn0sBjPm_VmDk/edit`
2. ที่เมนูด้านบน เลือก **ส่วนขยาย (Extensions)** > **Apps Script**
3. ลบโค้ดเดิมในหน้าต่างออกทั้งหมด แล้วคัดลอกโค้ดจากไฟล์ `setup_qa_sheet.gs` ไปวาง
4. กดปุ่ม **บันทึก (Save)** (ไอคอนแผ่นดิสก์)
5. ในแถบเครื่องมือด้านบน เลือกฟังก์ชัน `setupQASheet` แล้วกดปุ่ม **เรียกใช้ (Run)**
6. หากมีหน้าต่างขอสิทธิ์การเข้าถึง (Authorization) ให้กดยอมรับสิทธิ์

## สิ่งที่สคริปต์ทำให้โดยอัตโนมัติ:
- สร้างและจัดฟอร์แมตแท็บ `QA_Tasks` ในธีม Medical Palette (สีน้ำเงินเข้ม `#122056` และขอบมน)
- ตรึงแถวหัวตาราง (Freeze Row 1) และกำหนดความกว้างคอลัมน์ให้พอดี
- สร้าง Dropdown ให้คอลัมน์ Type (`Task`, `Bug`, `Feature`), System และ Status
- ไฮไลต์สีสถานะอัตโนมัติ:
  - `Completed`: สีเขียว
  - `Ready for testing`: สีเหลือง/ส้ม
  - `In progress`: สีน้ำเงิน
  - `Bug / Failed`: สีแดง
  - `Not started`: สีเทา
- ลงข้อมูลงานตั้งต้นทั้งหมดจากโปรเจกต์ (A1-A17, B1-B14, C1-C11)
- **Auto-Timestamp Trigger**: เมื่อมีใครแก้ข้อมูลในแถวใดก็ตามบนชีต คอลัมน์ Last Updated (คอลัมน์ G) จะอัปเดตวันและเวลา (`YYYY-MM-DD HH:mm:ss`) ให้โดยอัตโนมัติ
- **Web App API**: รองรับฟังก์ชัน `doGet` และ `doPost` สำหรับซิงก์ข้อมูลไป-กลับกับ Web Dashboard โดยตรง

## Tabs
- `QA_Tasks`: every task from `docs/TASKS.md` (ID, Type, System, Title, Status, QA Comment, Last Updated, Tester). QA team owns Status / QA Comment / Tester.
- `QA_Guide`: วิธีตรวจ 1/2/3, วิธีรายงานผลและบั๊ก (ข้อความอยู่ใน `GUIDE` ของ `sync.mjs`); `QA_Tasks` มีคอลัมน์ `How to Test` ดึงจากหัวข้อ "ทดสอบ" ของแต่ละงานใน `docs/TASKS.md` (ตัวไหนไม่มีหัวข้อ จะใช้ข้อความ default)
- `Dev_Log`: update log / reports (Time, Source, Summary), rebuilt from `docs/TASKS.md` "บันทึกการอัปเดต" + `dashboard/data/project.json` history.

## ให้ agent อัปเดตหลังแก้งานทุกครั้ง
1. แก้ `docs/TASKS.md` (สถานะงาน + บรรทัดใน "บันทึกการอัปเดต") ก่อน
2. รัน `node tools/sheets/sync.mjs` ดูผล (dry run) แล้วรัน `node tools/sheets/sync.mjs --apply`
3. ปรับสถานะงานเฉพาะข้อ: `node tools/sheets/sync.mjs --apply --set B3=testing --set A12=done` (`done|testing|progress|failed|planned`) ใช้กับแถว `BUG-*` ที่ QA เพิ่มเองได้ เช่น `--set BUG-1=testing` หลัง dev แก้บั๊กแล้ว
4. รัน `node dashboard/snapshots.mjs` เพื่อให้ dashboard ที่เปิดจากไฟล์ตรงกับ md

สคริปต์เพิ่มงานใหม่และอัปเดตชื่องาน แต่ไม่ทับ Status / QA Comment ที่ทีม QA แก้ในชีต (ยกเว้นระบุ `--set`) และเก็บแถวที่เพิ่มในชีตเอง (QA-*, BUG-*)

## ต้อง Deploy ใหม่เมื่อแก้ `setup_qa_sheet.gs`
Apps Script > Deploy > Manage deployments > แก้ deployment เดิม > Version: New version > Deploy (URL เดิมไม่เปลี่ยน) แล้วรัน `setupQASheet` หนึ่งครั้งเพื่อสร้างแท็บ `Dev_Log`
