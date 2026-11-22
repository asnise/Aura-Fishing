# Rod Fusion: ค่าใช้จ่ายและโอกาสล้มเหลว

ใช้คู่กับ `docs/MODIFIER_SYSTEM_SPEC.md` และมติข้อ 3 ใน `docs/DESIGN_DECISIONS_2026-11-21.md`
แบบหน้าจอ: Figma "Screen 19 - Rod Fusion steps" (node 3782:24507), ขั้น Mod แสดงบรรทัด Cost ก่อนปุ่ม FUSE.

## หลักคิด
- ผู้เล่นต้องซื้อหรือหาคันที่ 2 (รุ่นเดียวกัน) มาเป็นตัวสละอยู่แล้ว นั่นคือต้นทุนก้อนแรก (ขายคืนได้ 40% ของราคา)
- ค่าหลอมต้องเป็นก้อนที่สองที่รู้สึกได้ แต่ไม่แพงกว่าการตีบวก +10 (ประมาณ 2.7 เท่าของราคาคัน)
- Mod ยิ่งหายาก ยิ่งแพง และของระดับสูงสุดใช้ Pearls ด้วย เพื่อให้ Pearls มีที่ใช้ปลายเกม
- ล้างค่าติดลบต้องถูกกว่าปกติ เพราะเป็นเหตุผลหลักที่คนมาหลอม

## ค่า Coins (จ่ายเสมอ)
- Coins = ราคาคันหลัก x 0.25 x ตัวคูณความหายากของ Mod ที่ย้ายมา
- ตัวคูณความหายาก: Common 1, Uncommon 1.5, Rare 2.5, Epic 4, Legendary 7, Mythic 12
- Cap Breaker (Mod ชื่อ Max...) คูณเพิ่ม 1.5
- ทับช่องที่ Mod เดิมติดลบ: คูณ 0.5
- ใส่ลงช่องว่าง: คูณ 0.6
- ใช้ราคาคันหลักเป็นฐาน คันแพงจึงหลอมแพงตาม (เป็น Gold Sink ปลายเกมตามมติข้อ 2)

## ค่า Pearls (เฉพาะ Mod ระดับ Epic ขึ้นไป)
- Epic 300, Legendary 1,500, Mythic 8,000
- Cap Breaker คูณ 1.5
- Rare ลงไปไม่ใช้ Pearls
- เทียบกับตู้ปลา: Pearls เท่านี้คือราว 1 ชั่วโมงของตู้ที่เต็มด้วยปลาระดับนั้น

## โอกาสล้มเหลว (ตัดสินใจแล้ว: 5% ตายตัว)
- ล้มเหลว 5% ทุกกรณี เป็นเรื่องดวงจริงๆ ไม่ผูกกับความหายากหรือ Cap Breaker
- ล้มเหลวแล้ว หายแค่คัน Material (คันรอง) เท่านั้น คันหลักไม่เปลี่ยน ไม่เสีย Mod เดิม
- ล้มเหลวไม่หัก Coins และ Pearls (หักเมื่อสำเร็จเท่านั้น) เพื่อให้ "แค่ Material หาย" จริงๆ
- UI ต้องเห็นชัด: บรรทัดเตือนสีแดงก่อนกด FUSE ("5% FAIL  Only the Material rod is lost.") และหน้าผลลัพธ์ FUSION FAILED (Figma "Fusion result")

## Guard (ใช้ Gems) ทำแล้ว
- ติ๊ก Guard ในขั้น Compare จ่าย Gems เพื่อการันตีสำเร็จ (ข้ามโอกาสล้มเหลว 5%)
- ราคา: Rare 20, Epic 40, Legendary 80, Mythic 150 (Common และ Uncommon ไม่มี Guard)
- ไม่บังคับ ผู้เล่นฟรีหลอมได้ครบ ราคาอยู่ใน `GameConfig.Fusion.GuardGems`

## ระยะจาก NPC
- เซิร์ฟเวอร์ตรวจว่าผู้เล่นอยู่ภายใน `GameConfig.Fusion.NpcRange` (40 studs) จาก Old Marlin ถ้าแมพมีร้านของเขา

## ตัวอย่าง
- Bamboo Rod (1,500) ย้าย Rare: 1,500 x 0.25 x 2.5 = 938 Coins, ไม่มี Pearls
- Moonsilver Rod (120,000) ย้าย Epic: 120,000 x 0.25 x 4 = 120,000 Coins + 300 Pearls
- Celestial Rod (20,000,000) ย้าย Mythic Cap Breaker: 20,000,000 x 0.25 x 12 x 1.5 = 90,000,000 Coins + 12,000 Pearls

## ค่าที่ต้องเก็บใน Config (เมื่อเขียนโค้ด)
- เพิ่ม `GameConfig.Fusion`: FeeFraction 0.25, RarityMult, CapBreakerMult 1.5, CursedDiscount 0.5, EmptySlotMult 0.6, PearlCost, FailChance 0.05, GuardGems
- เซิร์ฟเวอร์เป็นผู้สุ่มความสำเร็จและหักเงินเอง (Remote `FuseRods` ตามขั้นที่ 6 ของ handoff)
- UI ขั้น Mod แสดง Cost (Coins, Pearls), โอกาสสำเร็จ และปุ่ม Guard ที่แสดงราคา Gems

## จุดที่ต้องทดลองสมดุล
- ถ้าผู้เล่นหลอมน้อยเกิน: ลด FeeFraction เหลือ 0.15
- ถ้าเงินเฟ้อจากการขายปลาทำให้ค่าหลอมไม่รู้สึก: เพิ่มตัวคูณ Legendary และ Mythic
- ตัวเลขทั้งหมดอยู่ใน Config เดียว ปรับได้โดยไม่แก้โค้ด
