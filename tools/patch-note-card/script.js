const STICKER_POOL = [
  { path: 'fish/GoldenKoi.png', size: 125 },
  { path: 'fish/CoralSeahorse.png', size: 105 },
  { path: 'fish/DewdropKoi.png', size: 115 },
  { path: 'fish/BubbleCarp.png', size: 110 },
  { path: 'fish/CrystalGuppy.png', size: 100 },
  { path: 'fish/FrostRay.png', size: 130 },
  { path: 'fish/PearlClam.png', size: 100 },
  { path: 'fish/PearlNautilus.png', size: 110 },
  { path: 'fish/LanternJellyfish.png', size: 115 },
  { path: 'auras/TidalBloom.png', size: 120 },
  { path: 'auras/MoonlitRipple.png', size: 120 },
  { path: 'auras/NebulaKoi.png', size: 125 },
  { path: 'auras/SparklingDew.png', size: 115 },
  { path: 'materials/moon_pearl.png', size: 90 },
  { path: 'materials/enhance_stone.png', size: 90 },
  { path: 'materials/star_shard.png', size: 90 },
  { path: 'equipment/BambooRod.png', size: 130 },
  { path: 'equipment/MoonsilverRod.png', size: 130 },
  { path: 'equipment/Hold.png', size: 100 },
  { path: 'npc/Marlin_happy.png', size: 140 }
];

// Cozy Lake coral and sand, with warm shades for the paper and ink.
const THEME = {
  scene: '#F1E2D2',
  paper: '#FFF9ED',
  note: '#FFFDF6',
  cream: '#FFF2E0',
  sand: '#F3E9D8',
  track: '#E4CFB7',
  ink: '#514238',
  muted: '#765D4D',
  titleInk: '#A34E38',
  tagInk: '#895735',
  rule: '#D7BDA8',
  backing: '#D5A986'
};

const DISPLAY_FONT = "'Fredoka', 'IBM Plex Sans Thai', sans-serif";
const BODY_FONT = "'Nunito', 'IBM Plex Sans Thai', sans-serif";
const TAG_PALETTE = [
  { name: "คาราเมล", color: THEME.tagInk },
  { name: "ดินเผา", color: THEME.titleInk },
  { name: "โกโก้", color: "#61473B" },
  { name: "พลัมหม่น", color: "#79516A" },
  { name: "น้ำเงินหม่น", color: "#435E79" }
];

const DEFAULT_HIGHLIGHTS = {
  title: "PATCH HIGHLIGHTS",
  date: "22-23 พ.ย. 2026",
  build: "BUILD v6.0",
  sections: [
    {
      tag: "C29 / SAVE V6",
      boxStyle: "paper",
      title: "ระบบไอเทมแบบ UUID & กระเป๋าใหม่",
      points: [
        "ปลา 1 ตัวต่อ 1 ช่องเดี่ยว มีน้ำหนัก, Mutation และมูลค่าเฉพาะตัว",
        "คันเบ็ดและสายเบ็ดซื้อซ้ำและขายคืนได้ 40% ของมูลค่ารวม",
        "ปรับสเต็ปความจุกระเป๋าใหม่เป็น 10, 16, 24, 36 และ 50 ช่อง"
      ]
    },
    {
      tag: "C30/C31 / GEAR",
      boxStyle: "paper",
      title: "Modifier เบ็ด/สาย & Rod Fusion",
      points: [
        "สุ่ม Prefix และ Suffix ให้เบ็ดและสาย (สุ่มค่า -N ถึง +N)",
        "Cap Breaker ปลดล็อกเพดานสเตตัสสูงสุดเดิมของเกม",
        "ระบบ Rod Fusion หลอมย้าย Mod ที่ NPC Old Marlin พร้อม Gem Guard"
      ]
    },
    {
      tag: "C35 / CODEX",
      boxStyle: "paper",
      title: "Stats Codex สารานุกรมใน Main Menu",
      points: [
        "ค้นหาคำอธิบายสเตตัส, Mod และ Mutation ครบ 86 รายการ",
        "ระบบ Searchable Index ค้นหาได้รวดเร็วแบบเรียลไทม์",
        "ปุ่มไอคอนใหม่ใน Main Menu พร้อมฟิลเตอร์แยกหมวดหมู่"
      ]
    },
    {
      tag: "C23/C34 / UI",
      boxStyle: "paper",
      title: "Daily Login B & ปรับปรุง UI มือถือ",
      points: [
        "Daily Login แบบ B Grand Shelf 7 วัน พร้อมปุ่มลอยบน HUD",
        "Store แบ่งหน้าด้วยปุ่ม < > (ไม่เป็น Scroller) บนจอมือถือ",
        "Inventory จัดเรียง Newest และปุ่มลอย NEW n นำทาง"
      ]
    },
    {
      tag: "C36-C39 / VFX",
      boxStyle: "paper",
      title: "Aura VFX 15 ออร่า & คลัง Assets Studio",
      points: [
        "สเปกพรอมป์ 75 ชีต และ Texture นำร่อง 3 ออร่าพร้อมพรีวิว Canvas",
        "Aura Particle Editor บน Windows และ Importer ลง Studio",
        "จัดระเบียบ ReplicatedStorage.Assets ครบ 208 รายการ"
      ]
    }
  ]
};

const state = {
  seed: randomSeed(),
  ratio: "portrait",
  data: JSON.parse(JSON.stringify(DEFAULT_HIGHLIGHTS))
};

const stickersReady = Promise.all(STICKER_POOL.map(({ path, size }) => new Promise((resolve) => {
  const image = new Image();
  image.onload = () => resolve({ image, size });
  image.onerror = () => resolve(null);
  // A local image URL taints the canvas when the page is opened from disk.
  image.src = location.protocol === "file:" ? OFFLINE_STICKER_ART[path] : `assets/art/${path}`;
}))).then((stickers) => stickers.filter(Boolean));

const fontsReady = Promise.allSettled([
  document.fonts.load("700 55px Fredoka"),
  document.fonts.load("700 23px 'IBM Plex Sans Thai'", "สมุดบันทึก"),
  document.fonts.load("600 21px 'IBM Plex Sans Thai'", "เนื้อหาบันทึก"),
  document.fonts.load("600 20px Nunito"),
  document.fonts.load("700 20px Nunito")
]);

function randomSeed() {
  return crypto.getRandomValues(new Uint32Array(1))[0];
}

function mulberry32(a) {
  return function() {
    let t = (a += 0x6D2B79F5) >>> 0;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function getDimensions(ratio) {
  if (ratio === "square") return { w: 1200, h: 1200 };
  if (ratio === "landscape") return { w: 1920, h: 1080 };
  return { w: 1080, h: 1350 };
}

function drawPanel(ctx, x, y, width, height, radius, fill, border) {
  ctx.beginPath();
  ctx.roundRect(x, y, width, height, radius);
  ctx.fillStyle = fill;
  ctx.fill();
  if (border) {
    ctx.strokeStyle = border;
    ctx.lineWidth = 2;
    ctx.stroke();
  }
}

function drawTape(ctx, x, y, angle, width) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(angle);
  drawPanel(ctx, -width / 2, -10, width, 20, 2, "rgba(218,174,128,0.38)");
  ctx.fillStyle = "rgba(255,255,255,0.44)";
  ctx.fillRect(-width / 2 + 3, -8, width - 6, 2);
  ctx.restore();
}

async function renderCard(canvas, scale = 1, snapshot = state) {
  const [stickers] = await Promise.all([stickersReady, fontsReady]);
  const { seed, ratio, data } = snapshot;
  const { w: baseW, h: baseH } = getDimensions(ratio);
  canvas.width = baseW * scale;
  canvas.height = baseH * scale;

  const ctx = canvas.getContext("2d");
  ctx.scale(scale, scale);
  ctx.textBaseline = "top";

  const pagePad = 32;
  const pageW = baseW - 2 * pagePad;
  const pageH = baseH - 2 * pagePad;
  const contentLeft = pagePad + 120;
  const contentW = baseW - 2 * contentLeft;
  const headerY = pagePad + 30;
  const notesTop = pagePad + 189;
  const footerY = baseH - pagePad - 28;
  const ruleSpacing = 29;

  ctx.fillStyle = THEME.scene;
  ctx.fillRect(0, 0, baseW, baseH);

  ctx.save();
  ctx.shadowColor = "rgba(81,66,56,0.20)";
  ctx.shadowBlur = 18;
  ctx.shadowOffsetY = 8;
  drawPanel(ctx, pagePad + 10, pagePad + 12, pageW, pageH, 14, THEME.backing);
  ctx.restore();
  drawPanel(ctx, pagePad + 6, pagePad + 7, pageW, pageH, 14, THEME.sand, THEME.track);
  drawPanel(ctx, pagePad + 3, pagePad + 3, pageW, pageH, 13, THEME.cream, THEME.track);
  drawPanel(ctx, pagePad, pagePad, pageW, pageH, 12, THEME.paper, THEME.track);

  // Leave the top of the page clear for the title.
  ctx.strokeStyle = THEME.rule;
  ctx.globalAlpha = 0.53;
  ctx.lineWidth = 1;
  ctx.beginPath();
  for (let y = notesTop + 18; y < footerY; y += ruleSpacing) {
    ctx.moveTo(pagePad + 23, y);
    ctx.lineTo(baseW * 0.55, y + 0.6);
    ctx.lineTo(baseW - pagePad - 20, y);
  }
  ctx.stroke();
  ctx.globalAlpha = 1;

  const tapeX = baseW - pagePad - 70;
  drawTape(ctx, tapeX, pagePad + 5, 0.12, 110);
  const occupied = [
    { x: tapeX - 57, y: pagePad - 13, w: 114, h: 35 }
  ];

  ctx.fillStyle = THEME.tagInk;
  ctx.font = `700 17px ${BODY_FONT}`;
  const label = "AURA FISHING / FIELD LOGBOOK";
  let titleW = ctx.measureText(label).width;
  ctx.fillText(label, contentLeft, headerY, contentW);

  ctx.fillStyle = THEME.titleInk;
  ctx.font = `700 55px ${DISPLAY_FONT}`;
  titleW = Math.max(titleW, ctx.measureText(data.title).width);
  ctx.fillText(data.title, contentLeft, headerY + 28, contentW);

  ctx.fillStyle = THEME.muted;
  ctx.font = `700 18px ${BODY_FONT}`;
  const meta = `${data.date}  /  ${data.build}`;
  titleW = Math.max(titleW, ctx.measureText(meta).width);
  ctx.fillText(meta, contentLeft, headerY + 107, contentW);
  occupied.push({ x: contentLeft - 6, y: headerY - 6, w: Math.min(titleW, contentW) + 12, h: 139 });

  const columns = ratio === "landscape" ? 2 : 1;
  const rows = Math.max(1, Math.ceil(data.sections.length / columns));
  const columnGap = 28;
  const columnW = (contentW - (columns - 1) * columnGap) / columns;
  const rowH = (footerY - 18 - notesTop) / rows;
  data.sections.forEach((section, i) => {
    const indent = (i % 3) * 6;
    const box = {
      x: contentLeft + Math.floor(i / rows) * (columnW + columnGap) + indent,
      y: notesTop + (i % rows) * rowH,
      w: columnW - indent,
      h: rowH - 10
    };
    occupied.push(drawJournalEntry(ctx, section, box, i));
  });

  const footer = "Aura Fishing - Official Developer Field Notes";
  ctx.font = `700 14px ${BODY_FONT}`;
  ctx.fillStyle = THEME.muted;
  ctx.textAlign = "center";
  const footerW = Math.min(ctx.measureText(footer).width, contentW);
  ctx.fillText(footer, baseW / 2, footerY, footerW);
  occupied.push({ x: (baseW - footerW) / 2, y: footerY, w: footerW, h: 20 });

  const artInset = pagePad + 8;
  const area = { x: artInset, y: artInset, w: baseW - 2 * artInset, h: baseH - 2 * artInset };
  drawJournalStickers(ctx, area, occupied, mulberry32(seed), stickers);
}

function drawJournalEntry(ctx, section, box, index) {
  const { x, y, w, h } = box;
  const framed = section.boxStyle !== "none";
  const taped = section.boxStyle === "paper";
  if (taped) {
    const direction = index % 2 === 0 ? 1 : -1;
    ctx.save();
    ctx.translate(x + w / 2, y + h / 2);
    ctx.rotate(direction * 0.008);
    ctx.shadowColor = "rgba(81,66,56,0.16)";
    ctx.shadowBlur = 7;
    ctx.shadowOffsetY = 3;
    drawPanel(ctx, -w / 2, -h / 2, w, h, 6, THEME.note, THEME.track);
    ctx.restore();
    drawTape(ctx, x + w - (direction > 0 ? 63 : 102), y + 1, direction * 0.11, 88);
  } else if (section.boxStyle === "fill") {
    drawPanel(ctx, x, y, w, h, 12, THEME.sand);
  } else if (framed) {
    drawPanel(ctx, x, y, w, h, 12, THEME.paper, THEME.track);
  }

  const left = x + (framed ? 15 : 0);
  const textW = w - (framed ? 30 : 0);
  const tag = section.tag.trim().toUpperCase();
  ctx.font = `700 23px ${DISPLAY_FONT}`;
  ctx.fillStyle = section.tagColor || THEME.tagInk;
  let usedW = ctx.measureText(tag).width;
  ctx.fillText(tag, left, y + 8, textW);

  ctx.fillStyle = THEME.ink;
  ctx.font = `700 31px ${DISPLAY_FONT}`;
  usedW = Math.max(usedW, ctx.measureText(section.title).width);
  ctx.fillText(section.title, left, y + 41, textW);

  const pointsY = y + 82;
  const pointsBottom = y + h - 8;
  const lineH = Math.min(29, (pointsBottom - pointsY) / Math.max(1, section.points.length));
  const bodySize = Math.max(1, Math.min(21, Math.floor(lineH - 3)));
  const markerRadius = Math.min(3.2, bodySize / 5);
  ctx.font = `600 ${bodySize}px ${BODY_FONT}`;
  ctx.fillStyle = THEME.ink;
  ctx.strokeStyle = THEME.tagInk;
  ctx.lineWidth = 1.4;
  let usedBottom = y + 75;
  section.points.forEach((point, i) => {
    const pointY = pointsY + i * lineH;
    ctx.beginPath();
    ctx.arc(left + 6, pointY + bodySize * 0.58, markerRadius, 0, Math.PI * 2);
    ctx.stroke();
    ctx.fillText(point, left + 18, pointY, textW - 18);
    usedW = Math.max(usedW, ctx.measureText(point).width + 18);
    usedBottom = pointY + lineH;
  });
  if (taped) return { x: x - 8, y: y - 16, w: w + 16, h: h + 25 };
  return framed ? box : { x: left - 6, y, w: Math.min(usedW, textW) + 12, h: usedBottom - y + 6 };
}

function drawJournalStickers(ctx, area, occupied, rand, stickers) {
  const pool = [...stickers];
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }

  let placed = 0;
  for (const sticker of pool) {
    for (let attempt = 0; attempt < 160; attempt++) {
      const size = sticker.size * (0.48 + rand() * 0.68);
      const angle = (rand() - 0.5) * 0.9;
      // Reserve the rotated square plus room for the sticker outline and shadow.
      const radius = size / 2 * (Math.abs(Math.cos(angle)) + Math.abs(Math.sin(angle))) + 15;
      const box = {
        x: area.x + rand() * (area.w - 2 * radius),
        y: area.y + rand() * (area.h - 2 * radius),
        w: 2 * radius,
        h: 2 * radius
      };
      if (occupied.some((other) => box.x < other.x + other.w && box.x + box.w > other.x
        && box.y < other.y + other.h && box.y + box.h > other.y)) continue;

      occupied.push(box);
      ctx.save();
      ctx.translate(box.x + radius, box.y + radius);
      ctx.rotate(angle);
      ctx.filter = "saturate(0.74) sepia(0.1) drop-shadow(0 0 2px #FFFFFF) drop-shadow(0 3px 4px rgba(81,66,56,0.24))";
      ctx.drawImage(sticker.image, -size / 2, -size / 2, size, size);
      ctx.restore();
      placed++;
      break;
    }
    if (placed === 5) break;
  }
}

async function renderPng(snapshot) {
  const canvas = document.createElement("canvas");
  await renderCard(canvas, 2, snapshot);
  const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
  if (!blob) throw new Error("PNG export failed");
  return blob;
}

function init() {
  const canvas = document.getElementById("boardCanvas");
  const inputSeed = document.getElementById("inputSeed");
  const btnReroll = document.getElementById("btnReroll");
  const btnDownloadPng = document.getElementById("btnDownloadPng");
  const btnCopyImage = document.getElementById("btnCopyImage");
  const btnToggleEditor = document.getElementById("btnToggleEditor");
  const btnCloseDrawer = document.getElementById("btnCloseDrawer");
  const contentDrawer = document.getElementById("contentDrawer");
  inputSeed.value = state.seed;

  function refresh() {
    renderCard(canvas, 1);
  }

  function reroll() {
    let seed = randomSeed();
    while (seed === state.seed) seed = randomSeed();
    state.seed = seed;
    inputSeed.value = state.seed;
    refresh();
    showToast(`สุ่มสติกเกอร์ใหม่: #${state.seed}`);
  }

  btnReroll.addEventListener("click", reroll);

  inputSeed.addEventListener("change", (e) => {
    const num = parseInt(e.target.value, 10);
    if (Number.isSafeInteger(num)) {
      state.seed = num;
      refresh();
    }
    inputSeed.value = state.seed;
  });

  window.addEventListener("keydown", (e) => {
    if (e.target instanceof HTMLElement && e.target.matches("input, textarea, select")) return;
    if (e.code === "Space" && e.target instanceof HTMLButtonElement) return;
    if (e.code === "Space" || e.key === "r" || e.key === "R") {
      e.preventDefault();
      reroll();
    }
  });

  document.querySelectorAll(".pill-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".pill-btn").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.ratio = btn.dataset.ratio;
      refresh();
    });
  });

  btnToggleEditor.addEventListener("click", () => {
    contentDrawer.classList.toggle("open");
  });
  btnCloseDrawer.addEventListener("click", () => {
    contentDrawer.classList.remove("open");
  });

  // Drawer Fields
  const fldTitle = document.getElementById("fldTitle");
  const fldDate = document.getElementById("fldDate");
  const fldBuild = document.getElementById("fldBuild");

  fldTitle.addEventListener("input", (e) => { state.data.title = e.target.value; refresh(); });
  fldDate.addEventListener("input", (e) => { state.data.date = e.target.value; refresh(); });
  fldBuild.addEventListener("input", (e) => { state.data.build = e.target.value; refresh(); });

  renderDrawerSections(refresh);

  document.getElementById("btnResetData").addEventListener("click", () => {
    state.data = JSON.parse(JSON.stringify(DEFAULT_HIGHLIGHTS));
    fldTitle.value = state.data.title;
    fldDate.value = state.data.date;
    fldBuild.value = state.data.build;
    renderDrawerSections(refresh);
    refresh();
    showToast("รีเซ็ตข้อมูลเป็นค่าเริ่มต้นเรียบร้อยแล้ว");
  });

  btnDownloadPng.addEventListener("click", async () => {
    showToast("กำลังเรนเดอร์ภาพความละเอียดสูง (2x)...");
    const snapshot = structuredClone(state);
    try {
      const blob = await renderPng(snapshot);
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `aura-fishing-patch-journal-seed-${snapshot.seed}.png`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      showToast("บันทึกภาพสำเร็จ!");
    } catch {
      showToast("บันทึก PNG ไม่สำเร็จ");
    }
  });

  btnCopyImage.addEventListener("click", async () => {
    if (!navigator.clipboard?.write || typeof ClipboardItem !== "function") {
      showToast("เบราว์เซอร์นี้ไม่รองรับการคัดลอกรูป");
      return;
    }
    try {
      const item = new ClipboardItem({ "image/png": renderPng(structuredClone(state)) });
      await navigator.clipboard.write([item]);
      showToast("คัดลอกรูปแล้ว");
    } catch {
      showToast("คัดลอกรูปไม่สำเร็จ");
    }
  });

  refresh();
}

function renderDrawerSections(refresh) {
  const container = document.getElementById("drawerSections");
  container.innerHTML = state.data.sections.map((sec, i) => `
    <div class="section-card-editor">
      <div class="field-cols">
        <div class="field-row">
          <label for="sectionTag${i}">Tag</label>
          <input type="text" id="sectionTag${i}" class="sec-tag" data-idx="${i}" value="${sec.tag}">
        </div>
        <div class="field-row">
          <label>รูปแบบกระดาษ</label>
          <select class="sec-box-style" data-idx="${i}">
            <option value="paper" ${sec.boxStyle === 'paper' ? 'selected' : ''}>กระดาษแปะเทป</option>
            <option value="stroke" ${(sec.boxStyle || 'stroke') === 'stroke' ? 'selected' : ''}>มีเส้นขอบ (Stroke)</option>
            <option value="fill" ${sec.boxStyle === 'fill' ? 'selected' : ''}>ไร้เส้นขอบ (No Stroke)</option>
            <option value="none" ${sec.boxStyle === 'none' ? 'selected' : ''}>บนเส้นบรรทัด (Open)</option>
          </select>
        </div>
      </div>
      <fieldset class="tag-palette">
        <legend>สี Tag</legend>
        <div class="tag-swatches">
          ${TAG_PALETTE.map(({ name, color }) => `
            <label class="tag-swatch" title="${name}">
              <input type="radio" class="sec-tag-color" name="sectionColor${i}" data-idx="${i}"
                value="${color}" aria-label="${name}" ${color === (sec.tagColor || THEME.tagInk) ? 'checked' : ''}>
              <span aria-hidden="true" style="--tag-color: ${color}"></span>
            </label>
          `).join("")}
        </div>
      </fieldset>
      <div class="field-row">
        <label>หัวข้อ</label>
        <input type="text" class="sec-title" data-idx="${i}" value="${sec.title}">
      </div>
      <div class="field-row">
        <label>ข้อความย่อย (1 บรรทัดต่อข้อ)</label>
        <textarea class="sec-bullets" data-idx="${i}">${sec.points.join('\n')}</textarea>
      </div>
    </div>
  `).join("");

  container.querySelectorAll(".sec-tag").forEach((el) => {
    el.addEventListener("input", (e) => {
      state.data.sections[e.target.dataset.idx].tag = e.target.value;
      refresh();
    });
  });

  container.querySelectorAll(".sec-tag-color").forEach((el) => {
    el.addEventListener("change", (e) => {
      state.data.sections[e.target.dataset.idx].tagColor = e.target.value;
      refresh();
    });
  });

  container.querySelectorAll(".sec-box-style").forEach((el) => {
    el.addEventListener("change", (e) => {
      state.data.sections[e.target.dataset.idx].boxStyle = e.target.value;
      refresh();
    });
  });

  container.querySelectorAll(".sec-title").forEach((el) => {
    el.addEventListener("input", (e) => {
      state.data.sections[e.target.dataset.idx].title = e.target.value;
      refresh();
    });
  });

  container.querySelectorAll(".sec-bullets").forEach((el) => {
    el.addEventListener("input", (e) => {
      state.data.sections[e.target.dataset.idx].points = e.target.value.split("\n").filter((s) => s.trim().length > 0);
      refresh();
    });
  });
}

let toastTimeout;

function showToast(msg) {
  const toast = document.getElementById("toast");
  toast.textContent = msg;
  toast.classList.add("show");
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => toast.classList.remove("show"), 2500);
}

document.addEventListener("DOMContentLoaded", init);
