-- Converted website NT1 presets (Vanilla), with two approved sources:
-- 40 original codes pinned to Naxxramas Resource Hub full-sync at commit
-- b77f25ea948d77488e9b934c8b66bbafe182948f
-- (assets/naxx-talent-sets-full-sync.js), plus seven Warrior codes supplied
-- directly by the project owner via Resource Hub calculator links 2026-10-11.
-- Never alter the original pinned 40 or the seven supplied NT1 strings.
-- Warlock and Death Knight are excluded from website presets for now;
-- the original Bot specs menu remains accessible for both and for Paladin.
-- No server-side DBC/talent-eligibility verification implied.
if not MultiBot then return end
MultiBot.NT1WebsitePresetSource = "b77f25ea948d77488e9b934c8b66bbafe182948f"
MultiBot.NT1WarriorPresetSource = "Owner-supplied calculator links, 2026-10-11"
MultiBot.NT1WebsitePresets = {
    {class="druid", category="Raid", name="Feral Druid", role="DPS", variant=1, code="NT1:vanilla:druid:m3-3.m4-5.m6-3.m9-2.ma-2.mb-3.mc-1.md-2.mf-2.mg-5.mh-1.mu-5.mw-5.my-3.mz-1.wa-1.1du-3.1h6-2.1h7-2"},
    {class="druid", category="Raid", name="Balance Druid", role="DPS", variant=1, code="NT1:vanilla:druid:l6-5.l7-2.l8-2.lr-3.ls-3.lw-1.lx-3.ly-3.m0-5.m1-1.mt-2.mu-5.my-3.mz-1.1di-3.1dj-2.1em-2.1h7-2.1q7-2.1q8-1"},
    {class="druid", category="Raid", name="Balance Druid", role="DPS", variant=2, code="NT1:vanilla:druid:l6-5.l7-2.l8-2.lr-3.lw-1.lx-3.ly-3.m0-5.m1-1.mt-2.mu-5.my-3.mz-1.1di-3.1dj-2.1dk-3.1em-2.1h7-2.1q7-2.1q8-1"},
    {class="druid", category="Raid", name="Feral Tank Druid", role="Tank", variant=1, code="NT1:vanilla:druid:m2-3.m4-5.m6-3.m7-3.m9-2.mb-3.mc-1.md-2.mf-2.mg-5.mh-1.mt-2.mu-4.mw-5.mz-1.wa-1.1du-3.1h6-2.1qa-3"},
    {class="druid", category="Raid", name="Restoration Druid", role="Healer", variant=1, code="NT1:vanilla:druid:lr-3.mt-2.mv-3.mw-5.mx-5.mz-1.n0-5.n1-3.n2-3.n3-1.nd-2.ne-2.nf-5.ng-1.1do-2.1em-2.1q6-5.1q8-1"},
    {class="mage", category="Raid", name="Frost Mage", role="DPS", variant=1, code="NT1:vanilla:mage:11-5.1p-3.1q-3.1u-3.1w-3.1x-1.1y-2.1z-1.20-1.21-3.22-2.23-5.24-3.kl-2.19t-3.19u-2.1c8-3.1f9-2.1pf-1.1pq-3"},
    {class="shaman", category="Raid", name="Restoration Shaman", role="Healer", variant=1, code="NT1:vanilla:shaman:g5-3.g6-1.ga-5.gb-3.gc-3.ge-1.gf-1.gg-5.gh-5.gi-5.gj-3.h1-5.h2-5.19q-3.19s-3"},
    {class="shaman", category="Raid", name="Enhancement Shaman", role="DPS", variant=1, code="NT1:vanilla:shaman:fn-5.fo-5.fp-4.fy-1.gq-5.gy-3.gz-3.h1-5.h2-3.h4-1.h5-1.19n-3.19p-3.19r-2.1ax-3.1ay-1.1lv-3"},
    {class="shaman", category="Raid", name="Elemental Shaman", role="DPS", variant=1, code="NT1:vanilla:shaman:fl-1.fm-1.fn-5.fo-5.fp-5.fx-1.fy-1.gz-3.h1-5.h2-5.k1-5.19k-3.19l-2.19m-3.1aq-3.1at-3"},
    {class="priest", category="Raid", name="Shadow Priest", role="DPS", variant=1, code="NT1:vanilla:priest:9k-2.9m-3.9n-3.9o-1.ct-3.cu-5.cv-3.cx-3.dd-5.de-2.dg-1.dx-1.eh-1.oh-2.19i-1.1dd-3.1dh-2.1gq-5.1kb-2.1qz-3"},
    {class="priest", category="Raid", name="Holy Priest", role="Healer", variant=1, code="NT1:vanilla:priest:9k-2.9n-3.9o-1.9s-3.a1-3.b5-5.b6-5.b8-5.ba-3.bc-3.be-2.bh-2.ca-1.wt-5.17d-1.19f-2.1gq-5"},
    {class="priest", category="Raid", name="Discipline Priest", role="Healer", variant=1, code="NT1:vanilla:priest:8y-1.9h-3.9j-3.9k-2.9n-3.9o-1.9r-1.9s-3.a1-3.b5-5.ba-3.be-2.ca-1.wt-5.xd-5.1d7-2.1d8-3.1gq-5"},
    {class="priest", category="Raid", name="Discipline Priest", role="Healer", variant=2, code="NT1:vanilla:priest:8y-1.9h-3.9j-3.9k-2.9n-3.9o-1.9r-1.9s-3.a1-3.b5-5.bc-3.be-2.ca-1.wt-5.xd-5.1d7-2.1d8-3.1gq-5"},
    {class="rogue", category="Raid", name="Combat Rogue", role="DPS", variant=1, code="NT1:vanilla:rogue:51-5.56-3.5l-2.5o-1.5p-1.65-5.67-1.6q-5.7h-5.7i-5.7l-3.v6-4.1bb-2.1er-2.1lg-2.1qc-5"},
    {class="hunter", category="Raid", name="Beastmastery Hunter", role="DPS", variant=1, code="NT1:vanilla:hunter:11b-3.11c-5.11g-2.11h-5.12e-5.12h-1.12i-1.12j-1.12l-1.12m-2.12p-5.12s-5.12t-3.194-2.195-2.1dz-2.1e6-3.1ei-2.1ne-1"},
    {class="hunter", category="Raid", name="Beastmastery Hunter", role="DPS", variant=2, code="NT1:vanilla:hunter:11b-3.11c-5.11h-5.12e-5.12h-1.12i-1.12j-1.12l-1.12m-2.12p-5.12s-5.12t-3.194-2.195-2.1dz-2.1e6-3.1ei-2.1ej-2.1ne-1"},
    {class="hunter", category="Raid", name="Marksmanship Hunter", role="DPS", variant=1, code="NT1:vanilla:hunter:11a-1.11c-5.11d-1.11f-3.11h-5.11l-1.11t-1.11u-3.12e-5.12l-1.12s-2.193-5.194-2.195-2.1e4-2.1e6-3.1ea-1.1ei-2.1ej-2.1ne-1.1p1-3"},
    {class="druid", category="Solo", name="Feral Druid", role="DPS", variant=1, code="NT1:vanilla:druid:m2-2.m3-5.m4-5.m6-3.m9-2.mb-3.mc-1.md-2.mf-2.mg-5.mh-1.mt-2.mu-4.mw-5.mz-1.wa-1.1ds-2.1du-3.1h6-2"},
    {class="druid", category="Solo", name="Balance Druid", role="DPS", variant=1, code="NT1:vanilla:druid:l6-5.l7-2.l8-2.lr-3.ls-2.lw-1.lx-3.ly-3.m0-5.m1-1.mt-2.mu-5.my-3.mz-1.1di-3.1dj-2.1dk-3.1em-2.1h7-2.1q8-1"},
    {class="druid", category="Solo", name="Feral Tank Druid", role="Tank", variant=1, code="NT1:vanilla:druid:m2-3.m4-5.m6-3.m7-3.m9-2.mb-3.mc-1.md-2.mf-2.mg-5.mh-1.mt-2.mu-4.mw-5.mz-1.wa-1.1du-3.1h6-2.1qa-3"},
    {class="druid", category="Solo", name="Restoration Druid", role="Healer", variant=1, code="NT1:vanilla:druid:l6-5.lr-3.mt-2.mv-3.mw-5.mx-5.mz-1.n0-5.n1-3.n2-3.n3-1.nd-2.ne-2.nf-1.ng-1.1do-2.1em-2.1q6-4.1q8-1"},
    {class="mage", category="Solo", name="Frost Mage", role="DPS", variant=1, code="NT1:vanilla:mage:11-5.12-3.1p-3.1q-3.1s-3.1u-3.1v-3.1w-3.1x-1.1z-1.20-1.21-3.22-2.23-5.24-3.2d-1.kl-2.19t-3.1f9-3"},
    {class="mage", category="Solo", name="Frost Mage", role="DPS", variant=2, code="NT1:vanilla:mage:11-5.12-2.1p-3.1q-3.1r-2.1s-2.1u-3.1v-3.1w-3.1x-1.1z-1.20-1.21-3.22-2.23-5.24-3.2d-1.kl-2.19t-3.1f9-3"},
    {class="shaman", category="Solo", name="Restoration Shaman", role="Healer", variant=1, code="NT1:vanilla:shaman:fo-5.g5-3.g6-1.ga-5.gb-3.gc-3.ge-1.gf-1.gg-5.gh-5.gi-5.h1-5.h2-5.h5-1.19s-3"},
    {class="shaman", category="Solo", name="Restoration Shaman", role="Healer", variant=2, code="NT1:vanilla:shaman:fn-1.fo-2.g5-3.g6-1.ga-5.gb-3.gc-3.ge-1.gf-1.gg-5.gh-5.gi-5.gv-2.h1-5.h2-5.h5-1.19s-3"},
    {class="shaman", category="Solo", name="Enhancement Shaman", role="DPS", variant=1, code="NT1:vanilla:shaman:fl-3.fn-5.fp-4.fr-2.fy-1.gq-5.gy-3.gz-3.h1-5.h2-3.h4-1.h5-1.19n-3.19p-3.19r-2.1ax-3.1ay-1.1lv-3"},
    {class="shaman", category="Solo", name="Elemental Shaman", role="DPS", variant=1, code="NT1:vanilla:shaman:fl-2.fm-1.fn-5.fo-5.fp-5.fr-2.fx-1.fy-1.h1-5.h2-5.k1-5.19k-3.19l-2.19m-3.1aq-3.1at-3"},
    {class="priest", category="Solo", name="Shadow Priest", role="DPS", variant=1, code="NT1:vanilla:priest:8x-2.9m-3.9n-3.ct-3.cu-5.cv-3.cx-3.dd-5.de-2.dg-1.dx-1.eh-1.oh-2.19i-2.1dd-3.1dh-2.1gq-5.1kb-2.1qz-3"},
    {class="priest", category="Solo", name="Holy Priest", role="Healer", variant=1, code="NT1:vanilla:priest:8x-2.9h-1.9j-3.9k-2.9n-2.9o-1.9s-1.a1-3.b5-5.b6-5.b7-2.ba-3.be-2.ca-1.cx-3.wt-5.17d-1.19f-2.1d2-2.1gq-5"},
    {class="priest", category="Solo", name="Discipline Priest", role="Healer", variant=1, code="NT1:vanilla:priest:8x-2.8y-1.9h-3.9j-3.9k-2.9n-3.9o-1.9r-1.9s-1.a1-3.b5-1.b7-1.ba-3.be-2.ca-1.cx-3.wt-5.xd-5.1d7-2.1d8-3.1gq-5"},
    {class="rogue", category="Solo", name="Subtlety Rogue", role="DPS", variant=1, code="NT1:vanilla:rogue:51-5.52-5.65-5.6s-3.6t-3.6v-2.79-2.7b-2.7d-2.7o-2.7w-1.8f-1.al-1.ix-1.v7-3.1ba-5.1bl-3.1qc-5"},
    {class="rogue", category="Solo", name="Assassination Rogue", role="DPS", variant=1, code="NT1:vanilla:rogue:65-5.79-2.7g-3.7h-5.7i-5.7k-2.7l-2.7m-2.7o-3.7p-3.7s-1.7t-1.7v-5.iy-3.1bt-2.1lg-2.1qc-5"},
    {class="rogue", category="Solo", name="Combat Rogue", role="DPS", variant=1, code="NT1:vanilla:rogue:51-5.56-3.57-3.5l-2.65-5.67-1.6q-5.7h-4.7i-5.7k-2.7l-2.8d-1.v6-5.1bb-2.1be-2.1er-2.1lg-2"},
    {class="rogue", category="Solo", name="Combat Rogue", role="DPS", variant=2, code="NT1:vanilla:rogue:51-5.54-5.56-3.57-3.5l-2.65-5.67-1.7h-4.7i-5.7k-2.7l-2.8d-1.v6-5.1bb-2.1be-2.1er-2.1lg-2"},
    {class="rogue", category="Solo", name="Combat Rogue", role="DPS", variant=3, code="NT1:vanilla:rogue:51-5.52-5.56-3.57-3.5l-2.65-5.67-1.7h-4.7i-5.7k-2.7l-2.8d-1.v6-5.1bb-2.1be-2.1er-2.1lg-2"},
    {class="hunter", category="Solo", name="Survival Hunter", role="DPS", variant=1, code="NT1:vanilla:hunter:107-5.108-3.109-3.10a-3.10p-3.10t-1.11c-5.11d-1.11e-3.11h-5.193-5.1e6-3.1ea-2.1ee-1.1ei-1.1ej-2.1ek-2.1px-3"},
    {class="hunter", category="Solo", name="Beastmastery Hunter", role="DPS", variant=1, code="NT1:vanilla:hunter:11c-5.11h-5.12e-5.12h-2.12i-1.12j-1.12k-2.12l-1.12m-2.12p-5.12r-3.12s-5.12t-4.194-2.1dz-2.1e6-3.1ei-2.1ne-1"},
    {class="hunter", category="Solo", name="Beastmastery Hunter", role="DPS", variant=2, code="NT1:vanilla:hunter:11b-3.11c-5.11h-5.12e-5.12h-1.12i-1.12j-1.12k-1.12l-1.12m-2.12p-5.12r-2.12s-5.12t-4.194-2.1dz-2.1e6-3.1ei-2.1ne-1"},
    {class="hunter", category="Solo", name="Marksmanship Hunter", role="DPS", variant=1, code="NT1:vanilla:hunter:108-1.11a-2.11b-3.11c-5.11d-1.11f-3.11h-5.11l-1.11t-1.11u-3.12e-5.193-5.194-2.1e4-2.1e6-3.1ea-2.1ei-2.1ej-2.1ek-3"},
    {class="hunter", category="Solo", name="Marksmanship Hunter", role="DPS", variant=2, code="NT1:vanilla:hunter:108-1.11a-1.11b-3.11c-5.11d-1.11f-3.11g-1.11h-5.11l-1.11t-1.11u-3.12e-5.193-5.194-2.1e4-2.1e6-3.1ea-2.1ei-2.1ej-2.1ek-3"},

    -- Approved user-supplied Warrior Vanilla level-60 builds, 2026-10-11.
    -- Unlike the preceding 40 rows, these are NOT attributed to the old
    -- pinned full-sync snapshot; they came directly from calculator URLs.
    {class="warrior", category="Solo", name="Protection Warrior", role="Tank", variant=1, code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-2.3m-5.3u-5.3x-3.40-3.42-1.43-2.44-1.45-2.48-1.49-1.ie-2.ji-5.18h-5.19y-2.1qi-3.2bc-1"},
    {class="warrior", category="Solo", name="Fury Warrior", role="DPS", variant=1, code="NT1:vanilla:warrior:3d-3.3i-2.3j-3.3m-5.4a-2.4b-5.4c-5.4d-5.4f-4.4g-1.4l-1.4n-1.ie-2.17x-5.1a1-3.1qi-3.2bc-1"},
    {class="warrior", category="Solo", name="Arms Warrior", role="DPS", variant=1, code="NT1:vanilla:warrior:3d-3.3i-2.3j-3.3k-3.3m-3.3n-2.3o-5.3p-1.3r-1.3s-3.3t-1.4a-1.4b-2.4d-5.4h-3.4m-3.ie-2.1fn-1.1q0-3.1qi-3.2bc-1"},
    {class="warrior", category="Raid", name="Protection Warrior", role="Tank", variant=1, code="NT1:vanilla:warrior:3g-1.3m-5.3u-5.3w-5.3x-3.40-3.42-1.43-2.44-1.45-2.48-1.49-1.4d-5.4f-1.ji-5.18h-5.19y-2.1qi-3"},
    {class="warrior", category="Raid", name="Fury - Rend Flurry", role="DPS", variant=1, code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-3.3m-2.4a-5.4c-5.4d-5.4f-3.4l-1.4n-1.ht-1.ie-2.16t-2.16u-2.17x-5.1a1-3.1qi-3.2bc-1"},
    {class="warrior", category="Raid", name="Fury - Anger Management", role="DPS", variant=2, code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-3.3m-2.3t-1.4a-5.4c-5.4d-5.4f-3.4l-1.4n-1.ht-1.ie-2.16t-2.16u-2.17x-5.1a1-3.1qi-3"},
    {class="warrior", category="Raid", name="Arms Warrior", role="DPS", variant=1, code="NT1:vanilla:warrior:3d-3.3g-1.3j-3.3k-3.3m-1.3n-2.3o-5.3p-1.3q-1.3r-1.3s-3.3t-1.4d-5.4h-5.4m-2.ht-2.ie-2.16u-1.1fn-2.1q0-3.1qi-3.2bc-1"},
}
