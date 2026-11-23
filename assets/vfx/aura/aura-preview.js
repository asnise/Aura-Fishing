(() => {
  const profiles = {
    TidalBloom: {
      name: 'Tidal Bloom',
      files: [
        '01_core_tidal_mist_4x4.png',
        '02_ground_blossom_ripple_4x4.png',
        '03_orbital_petal_drift_strip.png',
        '04_floral_glints_4x4.png',
        '05_petals_foam_atlas_2x2.png',
      ],
      primary: '#96ebc8',
      accent: '#ffbedc',
      backgrounds: ['#15332c', '#0d1e1c', '#071211'],
      fps: 14,
      core: { size: 3.15, opacity: .68 },
      spread: { diameter: 4.1, count: 8, rotation: .08 },
      motes: { rate: 6, life: 1.8, speed: .6, base: [2], extra: [0, 1, 3] },
      flares: { rate: 4, life: .4, size: .25 },
      orbit: { tilt: 15, speed: .55, radius: 1.56, opacity: .82, trails: 1 },
    },
    MoonlitRipple: {
      name: 'Moonlit Ripple',
      files: [
        '01_core_moonbeam_mist_4x4.png',
        '02_ground_lunar_concentric_ripple_4x4.png',
        '03_orbital_silver_halo_strip.png',
        '04_moonlit_diamond_glints_4x4.png',
        '05_silver_droplets_atlas_2x2.png',
      ],
      primary: '#c8dcff',
      accent: '#829fff',
      backgrounds: ['#141f3d', '#0c1328', '#080b18'],
      fps: 14,
      core: { size: 3.4, opacity: .78 },
      spread: { diameter: 4.75, count: 10, rotation: .06 },
      motes: { rate: 10, life: 1.3, speed: .8, base: [0, 1], extra: [2, 3] },
      flares: { rate: 5, life: .45, size: .28 },
      orbit: { tilt: 20, speed: .46, radius: 1.64, opacity: .88, trails: 1 },
    },
    NebulaKoi: {
      name: 'Nebula Koi',
      files: [
        '01_core_nebula_mist_4x4.png',
        '02_ground_starlight_pond_4x4.png',
        '03_orbital_koi_swim_strip.png',
        '04_cosmic_star_flares_4x4.png',
        '05_stardust_scales_atlas_2x2.png',
      ],
      primary: '#c8aaff',
      accent: '#ffa0d2',
      backgrounds: ['#1a2233', '#101622', '#090e16'],
      fps: 16,
      core: { size: 3.8, opacity: .8 },
      spread: { diameter: 5.35, count: 14, rotation: .26 },
      motes: { rate: 16, life: 1.5, speed: 1.2, base: [0], extra: [1, 2, 3] },
      flares: { rate: 6, life: .45, size: .35 },
      orbit: { tilt: 15, speed: .62, radius: 1.76, opacity: .96, trails: 2, phase: -3.25 },
    },
  };

  // Visible top and bottom rows of the existing 256 px core cells.
  const coreBounds = {
    TidalBloom: [[126,172],[97,177],[85,182],[91,187],[76,193],[55,200],[35,207],[21,213],[18,214],[28,212],[36,209],[33,205],[44,199],[50,193],[64,186],[83,181]],
    MoonlitRipple: [[197,220],[182,220],[157,220],[136,220],[110,221],[84,221],[55,221],[27,221],[35,222],[38,222],[37,222],[32,222],[33,221],[37,221],[175,221],[188,221]],
    NebulaKoi: [[167,210],[132,212],[124,213],[98,213],[83,218],[68,219],[48,220],[21,220],[29,220],[29,219],[30,218],[52,218],[84,217],[98,217],[142,216],[178,214]],
  };
  const catalog = [
    {"id":"SparklingDew","name":"Sparkling Dew","rarity":"Common","primary":"#b4f0ff","accent":"#dcfff5","source":"MoonlitRipple","tempo":14,"intent":"หยดน้ำค้างจับแสงเช้า ระลอกบางสองชั้นกับริ้วน้ำสั้นที่มีเม็ดน้ำใสตามหลัง"},
    {"id":"TidalBloom","name":"Tidal Bloom","rarity":"Common","intent":"หมอกน้ำสีมิ้นต์ผลิขึ้นจากโคน พาระลอกกลีบดอกไม้และริ้วกลีบสีชมพูรอบเอว"},
    {"id":"KelpWhisper","name":"Kelp Whisper","rarity":"Uncommon","primary":"#6ed278","accent":"#288c50","source":"MoonlitRipple","tempo":14,"intent":"ริ้วสาหร่ายยืดตัวตามน้ำ ทิ้งฟองและสปอร์เขียวที่ลอยช้ากว่ากระแสหลัก"},
    {"id":"CoralHeart","name":"Coral Heart","rarity":"Uncommon","primary":"#ff96a0","accent":"#ff6482","source":"TidalBloom","tempo":14,"intent":"แสงปะการังอุ่นเต้นเป็นคู่ ระลอกชั้นนอกจางก่อนและมีเม็ดแสงสีทับทิมหลุดจากริ้ว"},
    {"id":"NeonWave","name":"Neon Wave","rarity":"Rare","primary":"#00c8ff","accent":"#005aff","source":"MoonlitRipple","tempo":16,"intent":"สันคลื่นไซแอนกวาดจากเท้าออกด้านข้าง ทิ้งแพลงก์ตอนสีน้ำเงินตามสายน้ำ"},
    {"id":"MoonlitRipple","name":"Moonlit Ripple","rarity":"Rare","intent":"ระลอกสีเงินขยายเป็นวงเปิด ประกายเพชรตอบรับริ้วน้ำที่โคจรช้า"},
    {"id":"StormCurrent","name":"Storm Current","rarity":"Rare","primary":"#96dcff","accent":"#ffdc5a","source":"MoonlitRipple","tempo":18,"intent":"น้ำวนก่อนฝนแผ่ออกเป็นเกลียว ฟองฝนพุ่งต่ำและมีแสงทองวาบเล็กที่ปลายริ้ว"},
    {"id":"SolarFlare","name":"Solar Flare","rarity":"Epic","primary":"#ffdc50","accent":"#ff5000","source":"MoonlitRipple","tempo":16,"intent":"แสงอาทิตย์สะท้อนน้ำเป็นวงทองค่อย ๆ แผ่ มีไอน้ำสีอำพันตามขอบวง"},
    {"id":"FrostPearl","name":"Frost Pearl","rarity":"Epic","primary":"#ebfaff","accent":"#a0d2ff","source":"MoonlitRipple","tempo":14,"intent":"ไอเย็นตั้งขึ้นเป็นริ้วเดียว ลายผลึกหกเหลี่ยมไล่จากโคนออกสู่ปลายวงพร้อมประกายมุก"},
    {"id":"NebulaKoi","name":"Nebula Koi","rarity":"Epic","intent":"แกนม่วงยกตัวก่อนคลื่นดาวจะแผ่ออก ปลาคาร์ปชมพูโคจรพร้อมริ้วน้ำบางและหางฝุ่นดาว"},
    {"id":"AbyssalShadow","name":"Abyssal Shadow","rarity":"Legendary","primary":"#6e28aa","accent":"#bc83eb","source":"NebulaKoi","tempo":14,"intent":"เงาร่องน้ำลึกชั้นโปร่งคลายออก เผยเส้นเรืองแสงสีม่วงและแพลงก์ตอนตามชายวง"},
    {"id":"LotusNaga","name":"Lotus Naga","rarity":"Legendary","primary":"#3cc882","accent":"#ff96c8","source":"TidalBloom","tempo":16,"intent":"พญานาคหยกว่ายผ่านระลอกกลีบบัว มีริ้วตามแนวตัวและละอองชมพูที่ปล่อยตามหลัง"},
    {"id":"SerpentOfTheVoid","name":"Serpent of the Void","rarity":"Legendary","primary":"#ff78dc","accent":"#5adcff","source":"NebulaKoi","tempo":16,"intent":"สายน้ำขอบชมพูและไซแอนบิดตัวเป็นเกลียวกว้าง พญางูไหลผ่านช่องว่างในริ้ว"},
    {"id":"DragonEmperor","name":"Dragon Emperor","rarity":"Mythic","primary":"#ffd700","accent":"#ff8c00","source":"NebulaKoi","tempo":16,"intent":"มังกรทองพาริ้วเมฆน้ำหงายออกจากโคน แสงทองไล่จากวงใหญ่ถึงเกล็ดเล็ก"},
    {"id":"CelestialLeviathan","name":"Celestial Leviathan","rarity":"Mythic","primary":"#ffffff","accent":"#b48cff","source":"NebulaKoi","tempo":14,"intent":"วาฬโปร่งแสงว่ายช้าตามริ้วออโรร่า ระลอกกว้างทอดผ่านจุดดาวที่ค่อย ๆ ดับ"},
  ];
  const rarityOrder = ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Mythic'];
  const illustrated = ['AbyssalShadow', 'LotusNaga', 'NebulaKoi', 'SerpentOfTheVoid', 'DragonEmperor', 'CelestialLeviathan'];
  const sourceCells = {
    TidalBloom: { base: [2], extra: [0, 1, 3] },
    MoonlitRipple: { base: [0], extra: [2, 3] },
    NebulaKoi: { base: [1], extra: [2, 3] },
  };
  for (const entry of catalog) {
    const rank = rarityOrder.indexOf(entry.rarity);
    const base = profiles[entry.id] ?? {
      backgrounds: ['#213443', '#111e29', '#0b121c'],
      fps: entry.tempo,
      core: { size: 3 + rank * .2, opacity: .63 + rank * .05 },
      spread: { diameter: 4 + rank * .51, count: 7 + rank * 3, rotation: .08 + rank * .025 },
      motes: { rate: 6 + rank * 2, life: 1.65, speed: .58 + rank * .11, ...sourceCells[entry.source] },
      flares: { rate: 3 + rank, life: .44, size: .23 + rank * .028 },
      orbit: { tilt: 14 + rank, speed: .53 - rank * .025, radius: 1.54 + rank * .075, opacity: .79, trails: rank >= 3 ? 2 : 1 },
    };
    profiles[entry.id] = { ...base, ...entry };
  }
  const previewRoot = new URL('./', document.currentScript.src);
  const requested = document.body.dataset.aura || new URL(location.href).searchParams.get('aura');
  const auraId = Object.hasOwn(profiles, requested) ? requested : 'NebulaKoi';
  const profile = profiles[auraId];
  const coreRows = coreBounds[profile.source ?? auraId];
  const referenceHeight = coreRows[8][1] - coreRows[8][0];
  const scene = document.getElementById('scene');
  const context = scene.getContext('2d', { alpha: false });
  const status = document.getElementById('status');
  const toggle = document.getElementById('toggle');
  const tierButtons = [...document.querySelectorAll('[data-tier]')];
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
  const turn = 2 * Math.PI;
  const orbitPasses = [0, 1].map(() => {
    const canvas = document.createElement('canvas');
    return { canvas, brush: canvas.getContext('2d', { alpha: false }) };
  });
  let textures;
  let tier = 3;
  let yaw = .42;
  let pitch = .41;
  const initialTime = 3.4;
  let time = initialTime;
  let frameRequest;
  let lastTimestamp;
  let drag;

  const chooser = document.getElementById('aura-choice');
  if (chooser) {
    for (const entry of catalog) chooser.add(new Option(entry.name, entry.id));
    chooser.value = auraId;
    chooser.addEventListener('change', () => {
      const url = new URL(location.href);
      url.searchParams.set('aura', chooser.value);
      location.href = url;
    });
    document.getElementById('aura-name').textContent = profile.name;
    document.getElementById('aura-rarity').textContent = profile.rarity;
    document.getElementById('aura-intent').textContent = profile.intent;
    document.getElementById('aura-source').textContent = profile.source
      ? 'แบบร่างจังหวะจากเท็กซ์เจอร์น้ำในโปรเจกต์'
      : 'พรีวิวจากชีตของออร่านี้';
    const cover = document.getElementById('aura-art');
    const folder = illustrated.includes(auraId) ? 'auras_Art' : 'auras';
    cover.src = new URL('../../art/' + folder + '/' + auraId + '.png', previewRoot);
    cover.alt = 'ภาพออร่า ' + profile.name + ' ในเกม';
    const slug = profile.name.toLowerCase().replaceAll(' ', '_');
    document.getElementById('aura-prompt').href = new URL(auraId + '/prompt_layer_' + slug + '_vfx.md', previewRoot);
    scene.setAttribute('aria-label', 'ตัวอย่าง ' + profile.name + ' ลากหรือกดปุ่มลูกศรเพื่อหมุนมุมมอง');
  }

  // Part centers and dimensions in studs for the reference mannequin.
  const mannequin = [
    { x: 0, y: 4.2, z: 0, w: .83, h: .85, d: .78, material: 'head' },
    { x: 0, y: 3.12, z: 0, w: 1.29, h: 1.18, d: .71, material: 'shirt' },
    { x: 0, y: 2.37, z: 0, w: 1.2, h: .38, d: .66, material: 'pants' },
    { x: -.85, y: 2.85, z: 0, w: .35, h: 1.43, d: .47, material: 'shirt' },
    { x: .85, y: 2.85, z: 0, w: .35, h: 1.43, d: .47, material: 'shirt' },
    { x: -.32, y: 1.25, z: 0, w: .55, h: 1.94, d: .57, material: 'pants' },
    { x: .32, y: 1.25, z: 0, w: .55, h: 1.94, d: .57, material: 'pants' },
    { x: -.32, y: .15, z: .1, w: .56, h: .3, d: .77, material: 'boots' },
    { x: .32, y: .15, z: .1, w: .56, h: .3, d: .77, material: 'boots' },
  ];
  const materials = {
    head: ['#839194', '#6c7b80', '#a4acaf'],
    shirt: ['#425b69', '#344957', '#59717d'],
    pants: ['#293d4e', '#213344', '#3b5160'],
    boots: ['#293036', '#202930', '#3c474d'],
  };
  const faces = [
    { vertices: [4, 5, 6, 7], shade: 0 },
    { vertices: [1, 0, 3, 2], shade: 0 },
    { vertices: [5, 1, 2, 6], shade: 1 },
    { vertices: [0, 4, 7, 3], shade: 1 },
    { vertices: [7, 6, 2, 3], shade: 2 },
  ];

  function mix(start, end, alpha) {
    return start + (end - start) * alpha;
  }

  function seed(index, salt) {
    const n = Math.sin(index * 12.9898 + salt * 78.233) * 43758.5453;
    return n - Math.floor(n);
  }

  function tint(image, color, accent, highlight = 0) {
    const canvas = document.createElement('canvas');
    canvas.width = image.naturalWidth;
    canvas.height = image.naturalHeight;
    const brush = canvas.getContext('2d');
    brush.fillStyle = '#000000';
    brush.fillRect(0, 0, canvas.width, canvas.height);
    brush.drawImage(image, 0, 0);
    brush.globalCompositeOperation = 'multiply';
    if (accent) {
      const gradient = brush.createLinearGradient(0, 0, canvas.width, 0);
      gradient.addColorStop(0, color);
      gradient.addColorStop(.37, accent);
      gradient.addColorStop(.72, color);
      gradient.addColorStop(1, color);
      brush.fillStyle = gradient;
    } else {
      brush.fillStyle = color;
    }
    brush.fillRect(0, 0, canvas.width, canvas.height);
    if (highlight) {
      brush.globalCompositeOperation = 'lighter';
      brush.globalAlpha = highlight;
      brush.filter = 'contrast(2) brightness(.85)';
      brush.drawImage(image, 0, 0);
    }
    return canvas;
  }

  async function load(path) {
    const image = new Image();
    image.src = path;
    try {
      await image.decode();
    } catch (error) {
      throw new Error('Could not load ' + path, { cause: error });
    }
    return image;
  }

  function drawFrame(texture, grid, frame, size, opacity, anchor = .5) {
    const cell = texture.width / grid;
    const x = (frame % grid) * cell;
    const y = Math.floor(frame / grid) * cell;
    // The black matte contributes zero light when screened onto the scene.
    context.globalCompositeOperation = 'screen';
    context.globalAlpha = opacity;
    context.drawImage(texture, x, y, cell, cell, -size / 2, -size * anchor, size, size);
  }

  function emit(rate, lifetime, draw, delay = 0) {
    const clock = time - delay;
    const latest = Math.floor(clock * rate);
    const count = Math.ceil(rate * lifetime);
    for (let i = latest; i > latest - count; i--) {
      const seconds = Math.max(0, clock - i / rate);
      if (seconds < lifetime) draw(i, seconds, seconds / lifetime);
    }
  }

  function addMannequin(project, queue) {
    for (const part of mannequin) {
      const left = part.x - part.w / 2, right = part.x + part.w / 2;
      const bottom = part.y - part.h / 2, top = part.y + part.h / 2;
      const back = part.z - part.d / 2, front = part.z + part.d / 2;
      const corners = [
        project(left, bottom, back), project(right, bottom, back),
        project(right, top, back), project(left, top, back),
        project(left, bottom, front), project(right, bottom, front),
        project(right, top, front), project(left, top, front),
      ];
      for (const face of faces) {
        const points = face.vertices.map(i => corners[i]);
        const [a, b, c] = points;
        if ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x) >= 0) continue;
        const depth = points.reduce((sum, point) => sum + point.depth, 0) / points.length;
        queue.push({ depth, draw() {
          context.beginPath();
          context.moveTo(a.x, a.y);
          for (const point of points.slice(1)) context.lineTo(point.x, point.y);
          context.closePath();
          context.fillStyle = materials[part.material][face.shade];
          context.fill();
          context.strokeStyle = '#17242b';
          context.lineWidth = .8;
          context.stroke();
        } });
      }
    }
  }

  function addOrbit(project, queue, width, height, density) {
    const { tilt, speed, radius, opacity, trails, phase = 0 } = profile.orbit;
    const centerDepth = project(0, 2.48, 0).depth;
    const arcs = [[], []];
    const tips = [];
    const paths = [{
      texture: textures.orbit, start: time * speed + phase, sweep: turn,
      radius, y: 2.48, tilt, height: turn * radius * textures.orbit.height / textures.orbit.width,
      opacity, segments: 48,
    }];
    for (let trail = 0; trail < trails; trail++) {
      const lower = trail === 0;
      paths.push({
        texture: textures.orbitTrail, start: time * speed * (lower ? .8 : -.58) + phase + trail * 2.7 - 1.55,
        sweep: turn * (lower ? .39 : .32), radius: radius * (lower ? 1.11 : .94),
        y: lower ? 2.25 : 2.82, tilt: lower ? -20 : 28, height: lower ? 1.3 : 1.04,
        opacity: opacity * (lower ? .71 : .53), segments: 24, trail: true,
      });
    }

    for (const path of paths) {
      const step = path.sweep / path.segments;
      const sourceWidth = path.texture.width / path.segments;
      const angleOfTilt = path.tilt * Math.PI / 180;
      const segmentLength = step * path.radius;
      function orbitPoint(angle, y = 0) {
        const across = path.radius * Math.sin(angle);
        const lift = path.trail ? (angle - path.start) / path.sweep * .46 - .2 : 0;
        return project(path.radius * Math.cos(angle), path.y + across * Math.sin(angleOfTilt) + lift + y,
          across * Math.cos(angleOfTilt));
      }
      for (let i = 0; i < path.segments; i++) {
        const angle = path.start + i * step;
        const next = angle + step;
        const left = orbitPoint(angle);
        const right = orbitPoint(next);
        const mid = angle + step / 2;
        const center = orbitPoint(mid);
        const top = orbitPoint(mid, path.height / 2);
        const bottom = orbitPoint(mid, -path.height / 2);
        const facing = Math.min(1, Math.abs(right.x - left.x) / (center.size * segmentLength) * 1.45);
        const taper = path.trail ? Math.sin((i + .5) / path.segments * Math.PI) ** 1.15 : 1;
        const alpha = path.opacity * mix(.22, 1, facing) * taper;
        arcs[Number(center.depth >= centerDepth)].push({
          left, right, top, bottom, alpha, texture: path.texture, sourceWidth, u: i * sourceWidth, depth: center.depth,
        });
      }
      if (path.trail) tips.push(orbitPoint(path.start + path.sweep * .81));
    }

    // Stitch each arc on black before screening it once, so neighboring slices
    // can overlap without adding a bright vertical seam.
    for (const [pass, slices] of arcs.entries()) {
      const { canvas, brush } = orbitPasses[pass];
      if (canvas.width !== scene.width || canvas.height !== scene.height) {
        canvas.width = scene.width;
        canvas.height = scene.height;
      }
      brush.resetTransform();
      brush.globalAlpha = 1;
      brush.globalCompositeOperation = 'source-over';
      brush.fillStyle = '#000000';
      brush.fillRect(0, 0, canvas.width, canvas.height);
      brush.globalCompositeOperation = 'lighten';
      slices.sort((a, b) => a.depth - b.depth);
      for (const slice of slices) {
        const { left, right, top, bottom, alpha, texture, sourceWidth, u } = slice;
        const start = Math.max(0, u - 2);
        const end = Math.min(texture.width, u + sourceWidth + 2);
        brush.globalAlpha = alpha;
        brush.setTransform(
          (right.x - left.x) * density, (right.y - left.y) * density,
          (bottom.x - top.x) * density, (bottom.y - top.y) * density,
          left.x * density, left.y * density,
        );
        brush.drawImage(texture, start, 0, end - start, texture.height,
          (start - u) / sourceWidth, -.5, (end - start) / sourceWidth, 1);
      }
      queue.push({ depth: centerDepth + (pass === 0 ? -1 : 1) * radius * .72, draw() {
        context.save();
        context.globalCompositeOperation = 'screen';
        context.drawImage(canvas, 0, 0, width, height);
        context.restore();
      } });
    }
    return tips;
  }

  function render() {
    if (!textures || !scene.clientWidth || !scene.clientHeight) return;
    const width = scene.clientWidth, height = scene.clientHeight;
    const density = Math.min(devicePixelRatio || 1, 1.75);
    const bufferWidth = Math.round(width * density), bufferHeight = Math.round(height * density);
    if (scene.width !== bufferWidth || scene.height !== bufferHeight) {
      scene.width = bufferWidth;
      scene.height = bufferHeight;
    }
    context.setTransform(density, 0, 0, density, 0, 0);
    context.globalAlpha = 1;
    context.globalCompositeOperation = 'source-over';
    const [centerColor, middleColor, edgeColor] = profile.backgrounds;
    const background = context.createRadialGradient(width / 2, height * .58, 0,
      width / 2, height * .58, Math.max(width * .52, height * .75));
    background.addColorStop(0, centerColor);
    background.addColorStop(.58, middleColor);
    background.addColorStop(1, edgeColor);
    context.fillStyle = background;
    context.fillRect(0, 0, width, height);

    const cosYaw = Math.cos(yaw), sinYaw = Math.sin(yaw);
    const cosPitch = Math.cos(pitch), sinPitch = Math.sin(pitch);
    const radius = Math.max(2.1, profile.spread.diameter * .56);
    const targetHeight = 2.3;
    const topOfHead = 4.68 - targetHeight;
    const upper = -(.62 * sinPitch + topOfHead * cosPitch) * 11 / (11 - .62 * cosPitch - topOfHead * sinPitch);
    const lower = (radius * sinPitch + targetHeight * cosPitch) * 11 / (11 - radius * cosPitch + targetHeight * sinPitch);
    const scale = Math.min(width / Math.max(5.9, radius * 2.25), height * .9 / (lower - upper));
    const viewCenter = (height - (lower + upper) * scale) / 2;
    const queue = [];

    function project(x, y, z) {
      const horizontal = x * cosYaw - z * sinYaw;
      const forward = x * sinYaw + z * cosYaw;
      const up = y - targetHeight;
      const depth = forward * cosPitch + up * sinPitch;
      const size = scale * 11 / (11 - depth);
      return { x: width / 2 + horizontal * size, y: viewCenter + (forward * sinPitch - up * cosPitch) * size, size, depth };
    }

    function ground(texture, frame, diameter, opacity, spin, grid = 4) {
      const center = project(0, 0, 0);
      const x = project(.1, 0, 0), z = project(0, 0, .1);
      context.save();
      context.transform((x.x - center.x) * 10, (x.y - center.y) * 10,
        (z.x - center.x) * 10, (z.y - center.y) * 10, center.x, center.y);
      context.rotate(spin);
      drawFrame(texture, grid, frame, diameter, opacity);
      context.restore();
    }

    function sprayTrail(angle, radius, length, opacity) {
      const x = Math.cos(angle), z = Math.sin(angle);
      const start = project(x * Math.max(.08, radius - length), .025, z * Math.max(.08, radius - length));
      const tip = project(x * radius, .025, z * radius);
      const side = project(x * radius - z * .58, .025, z * radius + x * .58);
      context.save();
      context.transform(tip.x - start.x, tip.y - start.y, side.x - tip.x, side.y - tip.y, start.x, start.y);
      context.globalCompositeOperation = 'screen';
      context.globalAlpha = opacity;
      context.drawImage(textures.orbitTrail, 0, -.5, 1, 1);
      context.restore();
    }

    function billboard(texture, grid, frame, point, size, opacity, rotation = 0, anchor = .5) {
      queue.push({ depth: point.depth, draw() {
        context.save();
        context.translate(point.x, point.y);
        context.rotate(rotation);
        drawFrame(texture, grid, frame, size * point.size, opacity, anchor);
        context.restore();
      } });
    }

    const cycle = .5 + (time - initialTime) * profile.fps / 16;
    const pulse = cycle % 1;
    const pulseIndex = Math.floor(cycle);
    const scaleByTier = [.72, .87, 1][tier - 1];
    const footprint = profile.spread.diameter * scaleByTier;
    const feet = project(0, 0, 0);
    if (tier >= 2) {
      const light = context.createRadialGradient(feet.x, feet.y - scale * .55, 0, feet.x, feet.y - scale * .55, scale * 1.8);
      light.addColorStop(0, profile.primary + (tier === 3 ? '33' : '26'));
      light.addColorStop(1, profile.primary + '00');
      context.fillStyle = light;
      context.fillRect(0, 0, width, height);
    }
    context.beginPath();
    for (let mark = -4; mark <= 4; mark++) {
      const offset = mark * .65;
      const near = project(offset, 0, -2.6), far = project(offset, 0, 2.6);
      const left = project(-2.6, 0, offset), right = project(2.6, 0, offset);
      context.moveTo(near.x, near.y);
      context.lineTo(far.x, far.y);
      context.moveTo(left.x, left.y);
      context.lineTo(right.x, right.y);
    }
    context.strokeStyle = profile.primary + '20';
    context.stroke();

    function spreadWave(phase, diameter, strength, texture, rim, rotation) {
      if (phase <= 0 || phase >= 1) return;
      const travel = 1 - (1 - phase) ** 2;
      const opacity = Math.sin(Math.PI * phase) ** .7 * strength;
      const size = mix(.96, diameter, travel);
      ground(texture, Math.floor(phase * 16), size, opacity, rotation);
      ground(rim, 0, size * .93, opacity * .58, 0, 1);
    }
    spreadWave((pulse - .1) / .9, footprint, .94, textures.ground, textures.rim, time * profile.spread.rotation);
    if (tier >= 2) {
      spreadWave((pulse - .24) / .76, footprint * .88, .65,
        textures.groundAccent, textures.rimAccent, -time * profile.spread.rotation);
    }

    const sprayCount = Math.round(profile.spread.count * scaleByTier);
    for (let i = 0; i < sprayCount; i++) {
      const key = pulseIndex * sprayCount + i;
      const age = (pulse - .12 - seed(key, 0) * .19) / .69;
      if (age <= 0 || age >= 1) continue;
      const angle = (i / sprayCount + seed(pulseIndex, 1)) * turn + (seed(key, 2) - .5) * .36;
      const radius = mix(.15, footprint * mix(.38, .55, seed(key, 3)), 1 - (1 - age) ** 2);
      const lift = .06 + Math.sin(Math.PI * age) * mix(.18, .72, seed(key, 4));
      const sprayOpacity = Math.sin(Math.PI * age);
      if (i % 2 === 0) sprayTrail(angle, radius, mix(.84, .31, age), sprayOpacity ** 2 * .72);
      const point = project(Math.cos(angle) * radius, lift, Math.sin(angle) * radius);
      const cell = profile.motes.base[i % profile.motes.base.length];
      billboard(textures.sparks, 2, cell, point, mix(.12, .26, seed(key, 5)),
        sprayOpacity * .8, (seed(key, 6) - .5) * age);
    }

    const plume = project(0, .12, 0);
    // Keep the plume rooted at the feet and screen its light over the mannequin.
    plume.depth = project(0, 2.48, 0).depth + .9;
    const coreFrame = Math.floor(pulse * 16);
    const [top, bottom] = coreRows[coreFrame];
    // Compensate for the scale changes baked into the original sheets. The dim
    // bookend frames keep their fall-off instead of being stretched to full size.
    const correction = Math.min(1.65, referenceHeight / (bottom - top));
    const coverage = (bottom - top) * correction / referenceHeight;
    const fade = Math.min(1, pulse / .26, (1 - pulse) / .27);
    const opacity = profile.core.opacity * (coverage * Math.sin(fade * Math.PI / 2)) ** 2;
    billboard(textures.mist, 4, coreFrame, plume, profile.core.size * correction, opacity, 0, bottom / 256);

    const motes = profile.motes;
    function addMotes(rate, cells, texture, delay) {
      emit(rate, motes.life, (i, seconds, progress) => {
        const angle = seed(i, 4) * turn + progress * .75;
        const radius = .57 + seed(i, 5) * .66;
        const y = .35 + seed(i, 6) * .72 + seconds * motes.speed;
        const point = project(Math.cos(angle) * radius, y, Math.sin(angle) * radius);
        const cell = cells[Math.floor(seed(i, 7) * cells.length)];
        const rotation = (seed(i, 8) - .5) * (1 + 2 * progress);
        billboard(texture, 2, cell, point, mix(.14, .31, seed(i, 9)),
          Math.sin(Math.PI * progress) * .96, rotation);
      }, delay);
    }
    addMotes(motes.rate, motes.base, textures.sparks, 0);
    if (tier >= 2) {
      addMotes(motes.rate * .7, motes.extra, textures.sparksAccent, .17);
      const flares = profile.flares;
      emit(flares.rate, flares.life, (i, _seconds, progress) => {
        const angle = seed(i, 10) * turn;
        const radius = .61 + seed(i, 11) * .8;
        const point = project(Math.cos(angle) * radius, .55 + seed(i, 12) * 2.3, Math.sin(angle) * radius);
        // The glint sheet plays once over its shorter particle lifetime.
        billboard(textures.flare, 4, Math.min(15, Math.floor(progress * 16)), point, flares.size * 1.45, 1);
      });
    }

    addMannequin(project, queue);
    if (tier === 3) {
      const tips = addOrbit(project, queue, width, height, density);
      for (const [i, point] of tips.entries()) {
        const frame = 4 + Math.floor((time * 5 + i * 4) % 8);
        billboard(textures.flare, 4, frame, point, .32, .87);
      }
    }
    queue.sort((a, b) => a.depth - b.depth);
    for (const { draw } of queue) draw();
  }

  function tick(timestamp) {
    if (lastTimestamp !== undefined) time += Math.min(.05, (timestamp - lastTimestamp) / 1000);
    lastTimestamp = timestamp;
    render();
    frameRequest = requestAnimationFrame(tick);
  }

  function setPlaying(playing) {
    if (frameRequest !== undefined) cancelAnimationFrame(frameRequest);
    lastTimestamp = undefined;
    frameRequest = playing ? requestAnimationFrame(tick) : undefined;
    toggle.textContent = playing ? 'พักภาพ' : 'เล่นต่อ';
  }

  function rotate(deltaX, deltaY) {
    yaw += deltaX * .009;
    pitch = Math.max(.13, Math.min(.95, pitch + deltaY * .008));
    if (frameRequest === undefined) render();
  }

  scene.addEventListener('pointerdown', event => {
    if (event.button !== 0 || drag || !textures) return;
    drag = { id: event.pointerId, x: event.clientX, y: event.clientY };
    scene.setPointerCapture(event.pointerId);
  });
  scene.addEventListener('pointermove', event => {
    if (event.pointerId !== drag?.id) return;
    rotate(event.clientX - drag.x, event.clientY - drag.y);
    drag.x = event.clientX;
    drag.y = event.clientY;
  });
  scene.addEventListener('lostpointercapture', () => { drag = undefined; });
  scene.addEventListener('keydown', event => {
    const directions = { ArrowLeft: [-12, 0], ArrowRight: [12, 0], ArrowUp: [0, -12], ArrowDown: [0, 12] };
    if (!directions[event.key]) return;
    event.preventDefault();
    rotate(...directions[event.key]);
  });
  toggle.addEventListener('click', () => setPlaying(frameRequest === undefined));
  reducedMotion.addEventListener('change', event => setPlaying(!event.matches && Boolean(textures)));
  for (const button of tierButtons) {
    button.addEventListener('click', () => {
      tier = Number(button.dataset.tier);
      for (const control of tierButtons) control.setAttribute('aria-pressed', control === button);
      render();
    });
  }

  async function start() {
    const sourceId = profile.source ?? auraId;
    const sheets = profiles[sourceId].files.map(file => new URL(sourceId + '/' + file, previewRoot));
    const waterStrip = new URL('MoonlitRipple/03_orbital_silver_halo_strip.png', previewRoot);
    if (profile.source) sheets[2] = waterStrip;
    const [mist, ground, orbit, flare, sparks, rim, trail] = await Promise.all([
      ...sheets.map(load),
      load(new URL('../../art/auras/fx_ring.png', previewRoot)),
      load(waterStrip),
    ]);
    textures = {
      mist: tint(mist, profile.primary, undefined, .38),
      ground: tint(ground, profile.primary, undefined, .32),
      groundAccent: tint(ground, profile.accent),
      rim: tint(rim, profile.primary),
      rimAccent: tint(rim, profile.accent),
      orbit: tint(orbit, profile.primary, profile.accent, .24),
      orbitTrail: tint(trail, profile.accent, profile.primary, .32),
      flare: tint(flare, profile.name === 'Tidal Bloom' ? profile.accent : '#ffffff'),
      sparks: tint(sparks, profile.primary),
      sparksAccent: tint(sparks, profile.accent),
    };
    status.hidden = true;
    toggle.disabled = false;
    for (const button of tierButtons) button.disabled = false;
    new ResizeObserver(render).observe(scene);
    render();
    setPlaying(!reducedMotion.matches);
  }

  start().catch(error => {
    status.textContent = 'โหลดภาพออร่าไม่ได้ ' + profile.name;
    console.error(error);
  });
})();
