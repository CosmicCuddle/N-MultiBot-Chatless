# MultiBot Chatless — Naxxramas Development Roadmap

Repository: https://github.com/CosmicCuddle/N-MultiBot-Chatless  
Client: World of Warcraft 3.3.5a (Interface 30300, Lua 5.1)  
Current main commit: 7bc9baaf9e4f2e8f97c61ce475db2cdea6671dd5 (post-merge roadmap update; PR #4 merged at 178a4c0f0070695eeb493d16aca7bb5c4b7a93cf); previous PR #3 7903afb2b3145dc27497f953f976a783fac7a11e, PR #2 75a3cf4c96ff53f4189a9c33d1327095ea0763f2 and PR #1 e33e87954cb53e5c8cb21b694faae37653dea180  
Current main version: MultiBot 4.0.4 — Saved Builds and website presets merged and main CI passed; live-client tests still pending  
Last maintained: 11 October 2026 — account-wide NT1 saves and class-specific website presets  
Public suite baseline: N Addon Collection v2.0.0, which still includes approved MultiBot 4.0  
Author and credit lineage: Nico Löbbert, Wishmaster117/TheWarlock, CosmicCuddle

This is the current handover for the Naxxramas fork. Also preserve docs/ROADMAP.md, which is the detailed historical upstream bridge-migration audit. That document includes older August 2026 baseline SHAs and should not be mistaken for the current Naxxramas fork version. Update this root file with every meaningful change, including the new exact next task.

## Active feature: MultiBot 4.0.4 — NT1 Saved Builds and Website Presets

Repository: https://github.com/CosmicCuddle/N-MultiBot-Chatless  
Merged feature branch: feature/nt1-saved-builds-pages; [PR #4](https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/4)  
Status: merged as main commit 178a4c0f0070695eeb493d16aca7bb5c4b7a93cf; [main test/package run 38128866892](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128866892) passed. Main lint passed. No player screenshots/relog verification yet; no standalone stable release or collection update.  
Baseline for rollback: MultiBot 4.0.3 from main.  
Next immediate task: **review Saved Builds Page 2 visual polish** in a standalone PR #5 test ZIP. The owner approved the Website Presets list/spacing based on actual Warrior Gorak All and Raid screenshots. Page 2 now uses the same dark list and top status line, with separate class/name/era columns and a visible selected-row indicator. Inspect it in the real WoW 3.3.5a client at the enlarged font size, select a saved name, confirm Load to import still works and that the Delete first-click warning appears **without clicking Delete again**. Previous functional save/load, /reload and relog checks passed. Defer manual NMB1 export/import, as explicitly requested; do not mark it passed. Later style Page 1 Import, then Page 4 appearance independently. Preserve addon/WTF backups, keep draft [PR #5](https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/5) unmerged, and leave published N Addon Collection v2.0.0 unchanged.

### Requirements and implemented design

- The existing NT1 Import stays Page 1. Paste code, choose a name, Save code. A changed existing code must be confirmed by clicking Save again. Save never applies to a bot.
- Saved Builds > opens Page 2: alphabetical account-wide named NT1 builds, class/era labels, five entries per page, previous/next navigation, Load to import (returns to Page 1) and two-click Delete. None send a server command.
- Separate account-wide SavedVariables table: MultiBotNT1SavedBuilds, declared in MultiBot.toc, independent of N Talent Calculator and existing MultiBot profiles. Previous builds are never migrated or deleted.
- The original bot-roster Set Talents action offers website presets as a third window view, filtered to the exact class of that roster bot. Raid/Solo, spec, role and variation are visible. Clicking any red website preset row **loads its NT1 code and name directly into Page 1** in a single click; no second Load button or server request. Preview and Apply remain separate actions.
- Bot specs button on the website page keeps access to the previous bridge-driven Playerbots specialization selector. For classes without converted website records, Set Talents uses the old selector immediately.
- From a bot roster, the player may not already be targeting that character in-game. A secure, exact-name **Apply-click** attempt can select it; the first click binds a newly found bot, the second opens confirmation, and final Apply remains separately confirmed. An optional **Check target** control and quiet manual-target fallback remain. Wrong name, class or previously verified GUID cannot bypass checks.
- Naxxramas Core remains the only authority for applying talents, talent/era/point restrictions, ownership and experimental rollback. No C++/SQL/DBC or Playerbots bridge changes.
- Published N Addon Collection v2.0.0 remains unchanged and does not acquire the new calculator or MultiBot snapshot.

### Exact source of the website presets

Owner's site: https://cosmiccuddle.github.io/Naxxramas-Resource-Hub/  
Repo: https://github.com/CosmicCuddle/Naxxramas-Resource-Hub  
Original pinned source: assets/naxx-talent-sets-full-sync.js at commit b77f25ea948d77488e9b934c8b66bbafe182948f — exactly **40 unchanged** converted Vanilla entries (Druid 9, Hunter 8, Mage 3, Priest 7, Rogue 6, Shaman 7). The two supplemental Rogue links in naxx-talent-set-sync.js already occur in that snapshot; do not double-count. **Additional user-authorised sources (11 October 2026):** seven direct calculator links for Warrior, then a second uploaded `Replace Website Talents.txt` containing those original 47 plus seven new Warlock/Mage codes. Only the seven previously absent codes are added. Total **54** entries. All new Warrior codes use `NT1:vanilla:warrior`, have 51 allocated points, no repeated talent IDs, and fit within the existing 255-character command envelope. Each code remains subject to current server-side DBC/era/eligibility checks; no in-game apply is claimed.

**Website class policy:** Warrior has seven owner-approved Vanilla builds (3 Solo; 4 Raid), and **Warlock is now approved** with five owner-supplied Vanilla builds (3 Solo; 2 Raid). Two additional Mage Solo builds (Arcane, Fire) are approved. **Continue excluding Death Knight** even if accidentally added by a future source refresh. Paladin has no approved converted NT1 website records. Keep the original Bot specs menu for these two unavailable classes, and retain the **Bot specs button for Warrior and Warlock** as well. Do not fabricate or rescale codes in the client. Website presets are bundled offline: deliberate source-pinned regeneration or owner-supplied link review, regression tests and roadmap documentation are required for changes.

### Files changed

| Path | Responsibility |
| --- | --- |
| MultiBot.toc | 4.0.4 version, account-wide SavedVariables, website preset data load order |
| Data/NT1WebsitePresets.lua | 40 original codes pinned to site commit + 7 Warrior owner links + 7 newly supplied Warlock/Mage codes (54 total) |
| UI/MultiBotNT1TalentsUI.lua | account-wide name/save/load/delete, two import/storage pages, website class page, explicit target re-confirmation, no auto apply |
| UI/MultiBotSpecUI.lua | integrate website page into existing Set Talents menu while retaining Bot specs access |
| tests/test_nt1_saved_builds.lua | names, overwrite/delete, persistence, 54 approved records (exact Warrior and Warlock/Mage codes), 51-point/code checks, Raid/Solo filters, pages and no server mutation |
| tests/test_nt1_bot_talents.lua | prior target safety and command assertions adapted to larger page window |
| .github/workflows/nt1-playerbot-talents.yml | Lua syntax/tests, website snapshot and bundle artifact |
| README.md | new user instructions, source notes and risks |
| ROADMAP.md | this permanent maintainer handover |

### 11 October 2026 — Website Presets visual acceptance and Saved Builds polish

- **Owner-verified client screenshots:** Warrior bot Gorak at enlarged font scale, All 7 (Page 1/2) and Raid 4 (Page 1/1), now shows correctly aligned dark list rows, distinct Raid/Solo accents, no overlapping instruction/footer, working filter counters. The owner explicitly said **"yep looks great"**. Accept the Website Presets appearance for these tested views; no need to redesign it again.
- **Next incremental scope — Saved Builds Page 2 only:** reuse that approved dark alternating Blizzard-textured list and tooltip border; render class, saved build name and era in separate aligned columns; use a visible green stripe plus text marker for the currently selected row. Keep click-to-select, separate Load to import, previous/next paging, two-click Delete and account-wide SavedVariables completely unchanged.
- **Prevent the same font overlap:** keep a short top status at y=-18, list frame at y=-52 and rows from y=-60 through y=-251, no footer status line. The selected-build and Delete-twice messages use the top status line, with short wording to avoid wrapping. Preserve the five-per-page, three-page and rollback tests, and add native row/selection/coordinate assertions.
- **Safety and next step:** run CI, install the standalone test build after copying the MultiBot folder and WTF SavedVariables, and inspect Saved Builds with 1+ names and at least 6 names where convenient. Check selection and Delete warning but **do not confirm Delete** just for appearance testing. If accepted, proceed to Page 1 Import styling; leave Backup/Import functional test deferred per owner request. No changes to 54 talent records or secure Apply.
- Draft PR #5 remains unmerged; N Addon Collection v2.0.0 untouched.

### 11 October 2026 — Website Presets footer overlap correction

- **Owner's real-client screenshot of Warrior Gorak at enlarged UI/font scale** confirmed the new dark preset list and distinct Raid/Solo labels are an improvement, but also showed the footer help sentence (`Loading never applies talents.`) physically overlapping the **Previous** navigation button. The visual pass is therefore not yet accepted.
- **Minimal reversible fix:** consolidate that reassurance into a single top instruction label `Select a build. No talents are applied.` at `TOPLEFT (22, -18)`; remove the redundant bottom label at y=-280. Do not shrink the five 31-high rows, delete role/variant information, or move the navigation buttons; the list frame ends directly above them. This avoids a cramped bottom label regardless of the large stylised font.
- **Automated regression:** retain no-server-command website selection, class variants, and explicit position assertions for status at y=-18, filters at y=-43 and list at y=-75. Lua mocks cannot establish final real-client font appearance, so inspect a new screenshot with the same scale before proceeding to Pages 1, 2 or 4.
- **Scope:** no talent data, server settings, SavedVariables, secure targeting, or Apply changes. NMB1 export/import manual testing remains deferred by the owner, not passed. Keep PR draft and public collection unchanged.

### 11 October 2026 — initial native Wrath website preset visual polish

- **Owner decision:** detailed manual NMB1 export/copy/import testing is more involved than desired and should be **skipped for now**. Record backup/import as *untested*, not passed; existing basic Saved Builds save/load, /reload and relog successes stand. Continue recommending a straightforward copy of MultiBot + account WTF files before installing changed addon builds.
- **Scoped visual revision (Page 3 only):** replace the five full-width red preset buttons with dark, alternating Blizzard-textured list rows and native-font labels; a soft gold Raid indicator versus blue Solo indicator (each explicitly labelled in text); a restrained tooltip-border list panel, subtle hover and header divider. Keep the same click targets, five-per-page navigation, filters, role/spec/variant details, status guidance and original Bot specs fallback.
- Use only stock Wrath-era textures/UI functions. No new artwork, game executable changes, server commands, talent codes, SavedVariables or protected Apply code touched. Keep test mock support for native Button styling, and explicit regression assertions that red template rows are replaced and raid/solo labels are still visible.
- **First QA checkpoint:** verify current draft PR CI then install the new standalone ZIP after copying the addon folder and WTF SavedVariables. Screenshot Warrior (7) and Warlock (5) browsers at actual enlarged font size and test hover and one-click import. **Do not assume mock tests prove real-client font/layout compatibility**. If this polish is accepted, style Pages 1, 2 and 4 consistently in separate reversible commits.
- PR #5 remains draft/unmerged; published N Addon Collection v2.0.0 stays unchanged.

### 11 October 2026 — in-game acceptance: Saved Builds persists across reload and relog

- **Owner-reported actual WoW 3.3.5a tests:** after successfully saving and loading a named NT1 talent build, that build remains available after `/reload` **and after logging out and logging back in**. These are separate tested persistence checkpoints, not merely mock SavedVariables tests.
- **Scope:** confirmed for the owner's tested character/account and installed development build. Same-account cross-character sharing, client exit/relaunch, five-per-page Saved Builds navigation, overwrite/delete and backup/export/import still require separate verification. No server talent application is implied.
- **Next safe step:** with WoW closed, back up the account `WTF` SavedVariables file(s) storing MultiBot and the addon folder before destructive testing. Then reopen WoW, visit **Saved Builds > → Backup / Import**, click **Export all** and inspect/copy the complete NMB1 text without importing anything yet. Confirm the saved test build is present and the `END|` record count matches the entries. A new copy/paste backup is a prerequisite for overwrite/delete/restore testing.
- No Lua/C++/SQL/DBC changes for these acceptance reports. Keep draft PR #5 unmerged and published N Addon Collection v2.0.0 unchanged.

### 11 October 2026 — in-game confirmation: Saved Builds round-trip

- **Owner confirmed:** the previously requested Page 1 Save As / Save code, Page 2 Saved Builds browse/select and Load to import **all work correctly in their WoW 3.3.5a client**. This completes the tested basic Saved Builds round-trip on draft PR #5 after importing a website preset. No new addon source code changes are needed for this milestone.
- **Remaining unverified separately:** SavedVariables survival after `/reload`, full logout/login and another same-account character; pagination after 5+ saved builds; Save overwrite confirmation, Delete confirmation; NMB1 export/import/restore, font/layout refinement. User's general confirmation does not prove those additional scenarios, and should not be over-reported as such.
- **Next test:** keep the existing test build as-is, issue `/reload`, reopen Saved Builds, verify the same saved name and talent code are still present and load correctly. Then test full relog. Make an account `WTF` SavedVariables backup before overwrite/deletion or import tests. Do not Apply talents, merge draft PR #5 or modify N Addon Collection v2.0.0.

### 11 October 2026 — in-game confirmation: added Mage/Warlock preset displays

- **Screenshots received from the owner in WoW 3.3.5a:** Mage bot **Ruby** with **Solo** filter selected displays exactly **four** presets: Arcane, Fire, Frost and Frost v2. Warlock bot **Hakua** with **Raid** filter selected displays exactly **two** presets: Affliction and Demonology; with **Solo** selected displays exactly **three**: Affliction, Demonology and Destruction. Counts and descriptions visibly match the approved additions. This establishes the filtered list views rendered in-game, not just in Lua tests.
- **Not yet shown:** the All-filter counts for these two bots, clicking/loading the newly added rows into Page 1, original Bot specs fallback, actual talent applications or Saved Builds persistence. Do not mark any of those tested until observed.
- **Next:** complete one Page 1 Save code -> Page 2 Saved Builds browse/select -> Load to import round-trip using a uniquely named test build (no Apply). After that, verify /reload and relog persistence, overwrite/delete and NMB1 backup/import before the approved native Wrath UI polish. Preserve existing MultiBot + WTF backups. PR #5 remains draft; public N Addon Collection v2.0.0 unchanged.

### 11 October 2026 — completed website talent catalogue (owner-supplied)

- **Owner uploaded:** `Replace Website Talents.txt`, 54 approved Vanilla level-60 calculator links. Compared with the approved 47 in MultiBot; **seven missing entries** added, not a blind replacement: Warlock Raid Affliction/Demonology, Warlock Solo Affliction/Demonology/Destruction, Mage Solo Arcane/Fire. Warlock previously excluded is now explicitly approved by this newer owner file; Death Knight remains excluded; Paladin has no approved code. Do not fabricate Warlock Raid Destruction or Mage Raid Fire/Arcane builds.
- Existing 40 source-pinned records, 7 Warrior user-supplied records, and their exact NT1 code strings remain untouched. Metadata records the separate source file; preserve all Raid/Solo variants and distinct variant labels.
- Source audit: 54 entries, 51 allocated points each, ranks 1–5, no repeated talent ID within a build, and all `.naxxbot talents` request strings within the WoW 3.3.5a SAY transport cap. One **intentional duplicate code** appears for Druid Feral Tank under both Raid and Solo; this does not represent an additional talent configuration, but both categorized presets remain.
- Lua regression fixtures assert exact seven new codes, per-class counts and filters, Death Knight exclusion, one-click import for Warlock/Mage, original Warlock Bot specs fallback and zero auto-Apply commands. This is a client data update; it does not validate server talent prerequisites or alter database, DBC, Playerbots, or Naxxramas Core.
- **Regression correction:** first [NT1 CI run 38156473945](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38156473945) failed at a stale Mage UI fixture still expecting **2** Solo builds; the newly approved Arcane/Fire additions correctly make **4**. Update the UI assertion to match and rerun all CI before a client ZIP is considered ready.
- **Next:** review CI on this new PR #5 head and test Warlock 5 entries (Raid 2/Solo 3), Mage 5 entries (Raid 1/Solo 4), both one-click imports, and old Warrior 7. Finish Saved Builds functional tests **before** the separately approved native Wrath UI makeover. Public collection stays untouched and PR remains draft.

### 11 October 2026 — planned NT1 interface polish (approved direction; not implemented)

- **Owner feedback from actual Warrior website-preset browser screenshot:** seven correct choices, filters, five entries/page and one-click import now display, but the screen looks like an unpolished utility panel rather than an integrated, purpose-built 3.3.5a feature. Owner agreed: **finish remaining Saved Builds and persistence tests first; then perform a dedicated, reversible NT1 visual polish pass**.
- **Desired appearance:** native Wrath-era Blizzard interface, not a modern web-style design. Keep the existing addon window size or adapt only after testing at the owner's enlarged/stylised font. Use existing client UI texture/9-slice-style borders and consistent muted backgrounds, section separation, Blizzard-like headings and contextual role/era text, and restrained accent colours rather than full-width same-red rows.
- **Information architecture:** consistent Page 1 Import, Page 2 Saved Builds, Page 3 Website Presets, Page 4 Backup/Restore headers. Page 3 clearly separates filter bar, selectable preset rows, pagination, short non-alarming help/status and footer. Row names remain easy to read; Raid/Solo and Tank/DPS/Healer visibly distinguishable, variation names remain intact. Keep the five-item pagination model until a specific replacement has been visually proven.
- **Accessibility and UX:** prioritise readability and hierarchy for large UI scaling/dyslexic readers; stable alignment, adequate spacing, short labels, large hit targets, keyboard-focus sanity, distinguish hover/selection without relying on colour alone, no unnecessary repeated uppercase paragraphs. Ensure tooltips explain safe loading vs actual Apply.
- **Non-negotiable behaviour to preserve:** 54 exact owner-approved website entries, Warrior 7 (4 Raid/3 Solo), Warlock 5 (2 Raid/3 Solo), Mage 5 (1 Raid/4 Solo), Death Knight exclusion, original Bot specs fallback, class/era/role, one-click preset load, account SavedVariables, two-click overwrite/delete, NMB1 import/export limits, protected secure auto-targeting, fresh target/GUID checks and final Apply confirmation. No automatic Apply or server/SQL/DBC changes.
- **Implementation gate:** finish Page 1/2 save-load, overwrite/delete, /reload+relog and Page 4 NMB1 tests **before UI edits**; take MultiBot+WTF backup. Make the polish on a separately identifiable development commit/checkpoint within the existing draft PR (or a dedicated branch when agreed), retain simple rollback, run Lua 5.1 regressions/lint/format + package, inspect in WoW at large font, verify every page and protected Apply again before merge/public release.
- **Current state:** UI redesign is a documented plan only. No appearance code changed. Await owner confirmation of Saved Builds workflow next.

### 11 October 2026 — in-game acceptance: Apply confirmation and Cancel

- **Player-confirmed live UI test:** auto-targeting the intended bot on first Apply click succeeded in WoW 3.3.5a; the owner subsequently tested the **second Apply click, correct-bot confirmation and Cancel** and reported **that also worked**.
- Mark the targeted UI interaction and cancellation route **accepted for the tested scenario**. This report does not independently prove packet/chat telemetry, server mutation, untargetable/out-of-range behaviour, combat restrictions or other-bot identity changes. No experimental talents need be applied for this test.
- **Next functional test:** create a uniquely named saved code in Page 1 (no Apply), browse Page 2 and load it back to Import. Check name/code match and that opening/closing doesn't discard it. Later test existing-name overwrite (requires second Save), two-click Delete, pagination past five entries, /reload and full relog, Page 4 NMB1 export/import with restorable backup, and original Bot specs.
- Work remains in draft PR #5 and unchanged public collection; preserve addon and account WTF backups before destructive Save overwrite/delete or file replacement.

### 11 October 2026 — in-game acceptance: secure auto-target works

- **Player feedback:** After installing the latest test build, the project owner confirmed **the automatic targeting works in the WoW 3.3.5a client**. This validates the visible, real-game target-selection interaction on the tested setup, beyond Lua CI.
- **Do not infer from this report** that the final Apply confirmation, server-side talent mutation, absence of Lua errors in every scenario, combat-mode behaviour, or all class presets were tested. Keep these as separate checks.
- **Next focused manual test:** select a roster bot other than the current target; click Apply and verify it selects the correct bot; click Apply again to view the named-bot confirmation and choose **Cancel**. Test non-targetable/out-of-range bot fallback. Then resume Saved Builds, backup/import, relog and larger-font visual regression.
- Continue retaining MultiBot and account WTF backups. PR #5 stays draft/unmerged. No N Addon Collection v2.0.0, Mod-Naxxramas-Core, database or DBC release/change.

### 11 October 2026 — protected one-click exact-name auto-target attempt

- **Lint follow-up:** GitHub Actions at commit `6d12e71` passed NT1 regression and packaging but reported two Luacheck missing-global warnings for `InCombatLockdown`. Use the Wrath global via `_G.InCombatLockdown` and repeat lint/format/packaging before asking for client test. This is not evidence of in-game secure targeting.


- Owner confirmed the guided Arndor targeting flow works but requested **automatic targeting** on Apply. Confirmed from 3.3.5a reference sources that `TargetByName` was removed in patch 2.0.1, and insecure Lua must not call protected `TargetUnit` or unrestricted macros. Instead, the **user's hardware click** on Apply uses `SecureActionButtonTemplate` with the native `/targetexact <name>` macro before an ordinary `HookScript` callback independently validates target identity. **If that click newly verifies the intended bot, it asks for one more deliberate Apply click before opening the confirmation**, ensuring any subsequent `PLAYER_TARGET_CHANGED` event cannot hide the popup immediately. The callback never issues Apply directly.
- Macro only configured from strictly validated ASCII letter-only character names (2–12), never from pasted NT1 text or website labels. Update macro for every roster/direct-target window outside combat; disable when name cannot be safely represented. If the bot isn't locally targetable, combat prevents safe setup, or identity/class/GUID mismatches, retain the old guided/no-server-command fallback. Do not create a saved user macro, fake `TargetByName`, or issue `RunMacroText` directly from Lua.
- Lua mocks now simulate Blizzard's protected click separately from the addon `HookScript`, including success/failure, wrong-class target, per-bot macro refresh, first-click target/second-click confirmation and zero server Apply until the player accepts the separate popup. A harmless `PLAYER_TARGET_CHANGED` event for the *same verified GUID* no longer dismisses the pending popup; a genuinely different name/class/GUID still invalidates it. First CI run [38153094292](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38153094292) caught a test assertion incorrectly expecting the earlier verified GUID to be **cleared** by merely targeting a wrong-class same-name unit. Keep the verified GUID to prevent substitution, and reject that wrong-class target/confirmation; the test assertion is corrected. This **does not prove** secure-template behaviour on the user's exact WoW 3.3.5a client; check for taint/protected-action errors and window visibility, especially when switching roster bots or in combat. Retain addon/WTF backups and draft PR; N Addon Collection v2.0.0 and Mod-Naxxramas-Core unchanged.

### 11 October 2026 — guided roster-bot target selection

- **Actual client report:** a Priest Raid website preset for bot **Arndor** was loaded while the game target was another character (**Karnok**); the addon displayed `Target changed. Reopen Talents for the correct bot.` in red, repeatedly. Roster menus do not require the player to already target that bot.
- **Fix:** Preview/Apply buttons now show compact, quiet guidance to target **Arndor** (with class verification), without sending a command. Listen for WoW 3.3.5a `PLAYER_TARGET_CHANGED`; only a name/class/GUID-compatible target can become bound, and the window then displays `Target verified. Click Apply talents.` or `Click Preview.` No automatic Preview, Apply, or confirmation happens on event; **another deliberate button click is always necessary**.
- Former Confirm target control becomes an optional **Check target** button sharing the same logic. A verified same-name/different-GUID entity cannot silently inherit binding. Changing target during a pending Apply confirmation invalidates the confirmation and hides the popup when supported, even if the original bot is subsequently retargeted.
- Extend Lua mock regressions for waiting, wrong class, target change, no automatic commands, explicit re-click, cancellation, stale popup invalidation and GUID substitution. Lint correction: route optional Wrath popup hiding via `_G.StaticPopup_Hide` to avoid a missing-global warning. Status guidance shortened for larger client fonts. Maintain server-side authority and all 47 approved preset codes. No Mod-Naxxramas-Core, Playerbots, SQL, DBC or public collection edits.
- **Next:** check CI, install the new standalone ZIP with the previously created addon/WTF backups, repeat Arndor-from-roster scenario, send UI screenshot and verify no Lua errors. Keep destructive Apply disabled until server safety review.

### 11 October 2026 — single-click website preset loading

- **Owner-requested UX:** clicking a red website preset row immediately loads that code and name into NT1 Import (Page 1). Remove the redundant website-page **Load to import** button; retain **Bot specs** and **Cancel**, with room for the larger in-game UI font. This is **local navigation only**, never a command dispatch or an automatic Apply. The separate Confirm target, Preview and two-stage Apply confirmation are unchanged.
- All / Raid / Solo filters and five-per-page navigation remain. Preserve the selected preset metadata for the local role summary. Lua tests now require one-click Mage and Solo Warrior loading, reject an absent/wrong-class preset, verify the import page opens, and assert that zero server commands are emitted. Saved Builds Page 2 **Load to import** remains intentionally separate and unchanged.
- **Still pending:** review CI at the latest development commit and test the new one-click interaction with Warrior Throgar in WoW 3.3.5a, including /reload, readability, original Bot specs fallback, and the absence of talent changes. PR #5 remains unmerged, and N Addon Collection v2.0.0 is untouched.

### 11 October 2026 — approved Warrior website presets

- Owner supplied **seven** direct Resource Hub `NT1:vanilla:warrior` calculator URLs for level 60. **Solo:** Protection (Tank), Fury (DPS), Arms (DPS); **Raid:** Protection (Tank), Fury Rend Flurry build 01 (DPS), Fury Anger Management build 02 (DPS), Arms (DPS). All seven strings preserved exactly from user-supplied links and structurally checked at 51/51, with unique talent IDs and supported ranks 1–5. These offline checks are NOT proof of talent legality in the server DBC.
- Remove Warrior from the previous class-exclusion guard while retaining **Warlock and Death Knight** exclusions and original Playerbots Bot specs fallback. Total library increases from **40** (unchanged pinned Resource Hub sync) to **47** (40 + 7 user-supplied Warrior links). Paladin remains unavailable for website presets due to absent verified converted links.
- Add new tests for exact Warrior codes, point budgets, 4-Raid/3-Solo filters, 7-entry two-page navigation, Load-to-import without Apply, original Warrior Bot specs button and untouched Mage regression. No C++/SQL/DBC/mod-playerbots changes; no public collection release.
- **Next:** Verify GitHub Actions on the updated PR #5 head; install the corrected standalone test ZIP with the already backed-up MultiBot/WTF files and confirm Warrior preset browser has All 7 (two pages), Raid 4 and Solo 3; check names/variant distinctions and original Bot specs. Keep Apply disabled until server development accepts actual in-game tests.

### 11 October 2026 — first real 3.3.5a preset browser test and UI correction

- **Actual player screenshot received:** MultiBot's Set Talents on Mage bot **Uxel** displayed the correct website preset browser and all three published Mage records (1 Raid, 2 Solo). All/Raid/Solo buttons, original Bot specs, Load to import and Cancel were visibly rendered. The game client UI is scaled/uses a large stylised font; long repeated headings and the bottom status looked unnecessarily bulky. This observation confirms **display of the initial class browser only**, not successful clicks, Save/Import/relog, or actual application.
- **Actual Lua error captured at 11:55:36 local:** `Interface\\FrameXML\\UIPanelTemplates.lua:255: attempt to concatenate a nil value`, from `ScrollFrame_OnLoad` reached when `UI/MultiBotNT1TalentsUI.lua` created a **nameless** `UIPanelScrollFrameTemplate` scroll frame for Page 4. Wrath 3.3.5a's XML template requires a **nonempty global frame name** to build its scrollbar-child name. This could not be caught by earlier minimal mocked frames.
- **Fix:** name the scroll frame `MultiBotNT1BackupScrollFrame`; enforce the XML name requirement in both Lua 5.1 test mocks so this mistake fails CI in future; assert that Page 4 binds the named frame and the scroll child. Trim redundant website presets subheading and bottom status, shorten preset button labels while preserving Raid/Solo/role/variants, shorten backup-page hints and experimental Apply confirmation text. Keep all selection/load actions client-only, not a bot-talent change.
- **Next test after green CI:** install the newly generated PR #5 test ZIP after preserving prior addon/WTF backups; `/reload`; open Mage Uxel preset browser again and confirm no Lua error. Check All=3 / Raid=1 / Solo=2, Page 4 Backup/Import scroll area, imports and saved names, then send screenshots at same UI scale. Keep actual Apply disabled and test only cancel. PR draft/unmerged and N Addon Collection v2.0.0 unchanged.

### 11 October 2026 — NT1 server integration handover accepted

- Server audit: [Mod-Naxxramas-Core draft PR #6](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/pull/6), audited `main` SHA `1e00c5537a1e22d1be7572437c884ca05f4c3337`, audit commit `a359f9b38bda4262821b13c481060425d8c4f8ad`. This is **documentation only**. Source has legacy `.naxxbot talents preview/apply`; `APPLY_READY`, server tokens, projected level-specific rank plans, explicit role contracts, and safe gear automation are **NOT IMPLEMENTED**. Server compilation following the GENERAL-header workaround is still unconfirmed. Earlier Zevon level-60 Random Mage successful apply applies only to an older source revision.
- Server handover's MultiBot PR #5 SHA `6a935f1` is **stale**: the addon branch advanced through `4d6d558`, with a CI-passing safe four-page interface and later roadmap-only commit `d304901`. Use live PR refs and Actions rather than pinning to the earlier audit.
- **Integration boundary now:** existing commands and SAY chat transport remain unchanged. Local code decoding never indicates a server-approved plan. Preview is read-only and **not** authoritative `Apply-ready` even if it says `NT1 valid`. Apply confirmation is client-side only, not a server token. Successful `SendChatMessage` means merely dispatched; inspect actual server response.
- **Client guardrail update:** reject rank 6–9 at syntax level (server permits ranks 1–5), fail closed when UnitClass is unavailable, guard stale confirmation popup callbacks, and correct old Enter-to-Apply README instructions. Show a concise legacy-protocol warning during confirmation: server may reject.
- **Future server protocol (do not invent today):** after a separately approved server PR, consume validated readiness/rejection, issuer-era, target level/class/spec/GUID, applied rank projection and tree totals, requested role, immutable server plan/version/token/expiry. Invalidate readiness when target, code, class, level, active spec, progression or server response changes. Never infer readiness from local parsing or preview send. Define an actual 3.3.5a safe server-to-client response channel and framing before implementing a status parser; never parse unrestricted chat as trusted confirmation.
- **Equipment:** only Random Playerbots in a separate review-approved server design; Alt Bot inventories and equipped items never touched through NT1. Save/browse/import/export/load/filter remain entirely client-only.
- **No server changes in this addon PR.** PR #5 remains draft and N Addon Collection v2.0.0 remains unchanged. Next: recheck CI on new addon head, user-visible WoW client screenshots/scrolling/persistence tests, and request server-side post-fix compilation and reviewed preflight protocol before transport changes.

### Latest validation checkpoint — PR #5 (11 October 2026)

- Latest follow-up commit `4d6d5586900811ab4c70723154466c157ac77950` passes [Lua 5.1 NT1/visibility/consumables regressions and test ZIP packaging, run 38132825282](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38132825282), [Lua lint 38132825309](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38132825309), and [Lua format 38132825322](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38132825322). Artifact `multibot-nt1-talents-test` (ID `11699343446`) is the current test package.
- New automated tests cover two-stage Apply confirmation, Enter-not-Apply, target and code mutation rejection, local points/class/era summaries, website All/Raid/Solo filters, portable backup round-trip, collision confirmation, and missing/truncated backup END marker.
- Automated coverage does **not** verify game-client visuals, manual text selection, scrolling, actual clipboard behavior, WTF persistence after logout/relog, Playerbot interaction, or server-side talent application. Keep `AccessMode=0` during first GUI tests, and no actual Apply without a verified characters database and disposable bot backup. PR #5 remains draft/unmerged.
- No changes made to Naxxramas Core's C++/SQL/DBC, mod-playerbots, original spec bridge, or public N Addon Collection v2.0.0. Exact next tasks are the real client tests above, screenshot/error collection, and server-integration reconciliation only after a verified backend handover.

### CI correction — portable import regression (11 October 2026)

- Initial export/import CI runs [38132623813](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38132623813) and [38132686895](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38132686895) failed at **test-fixture assumptions**, not syntax: the older regression had already deleted `Restoration Test`, and a subsequent assertion compared the remaining Mage named build to a Shaman code. The corrected test uses the retained `Vanilla Fire` build and its actual `mage2` code. The multi-line backup editor is explicitly anchored inside its scroll frame. Re-run CI before acceptance; no in-game tests are claimed.

### Client safeguards and browsing improvements — staged on PR #5 (11 October 2026)

- Apply is now **two deliberate clicks**: button then WoW StaticPopup with bot name, class, expansion and spent points. Pressing Enter in the NT1 field only ends editing. Confirm-time preflight rechecks the live bot target/GUID, code, class and chat limit. Changed/closed dialogs abort without a server mutation. Preview is unchanged/read-only.
- Page 1 includes a locally decoded class / era / points / known website role summary. This is an information display only, **not** server validation or evidence of usable points/ranks.
- Page 3 includes All / Raid / Solo filters; each change resets selection and pagination. Existing original Bot specs fallback remains intact; Warrior now has seven owner-approved website presets, while Warlock and Death Knight remain excluded.
- New Lua mock regression checks for Enter safety, confirmation cancel/changed target/changed code, valid confirmation and Mage filter counts. These controls are unverified in WoW; all server permissions still apply. Test at enlarged UI scale and after /reload.
- Page 4 adds portable plain-text **NMB1 backup and import** for account-wide named NT1 builds. Export includes all valid saved codes (within a 30 KB EditBox safety cap); users copy with Ctrl+A/C, and import via paste. A strict parser checks the header, required END marker and declared record count (to detect truncated copies/pastes), names, NT1 codes, duplicate names and 100-build capacity before mutating SavedVariables. Changed existing names require two consecutive Import clicks; same-name identical codes are left unchanged. Never transmits a server command; on oversized exports use a manual WTF SavedVariables backup. Automated mock tests exercise format rejection, round-trip, conflict confirmation, and UI page navigation.
- **Next:** Verify PR head CI and inspect all four views in actual WoW 3.3.5a, especially multi-line scrolling, export text selection, copy/paste, overwrite confirmation, re-login persistence, font scaling and no Lua errors. Do not merge/release pending actual client acceptance.

### Additional scope clarification — Death Knight exclusion (11 October 2026)

- Project owner explicitly requested Death Knight be excluded from the website-based NT1 talent preset browser for now, alongside Warrior and Warlock. This affects **only the website preset option**, not the original Playerbot Bot specs functionality or the standalone manual NT1 import. Paladin remains unsupported due to absent verified converted website data.
- A fail-closed class check in `ListWebsitePresets` continues blocking Death Knight even if an accidental/future source refresh adds an entry. Lua regression tests inject a temporary Death Knight record and confirm it cannot be listed or opened. The original pinned snapshot contains 40 unchanged converted builds for Druid/Hunter/Mage/Priest/Rogue/Shaman, and seven newly owner-approved Warrior codes have since been added separately.
- The feature remains within draft PR #5 on the existing follow-up branch; GitHub Actions must be rechecked at the new head. **No in-game acceptance claimed.** The public N Addon Collection v2.0.0 remains untouched.

### Post-merge review and follow-up safeguards (11 October 2026)

- Direct GitHub audit confirmed latest main 7bc9baa has successful NT1 package, Lua lint and Lua format workflows (38128977780 / 38128977853 / 38128977806). Prior PR #4 failures are superseded by these passing head results.
- Compared Data/NT1WebsitePresets.lua to the pinned Resource Hub commit b77f25ea948d77488e9b934c8b66bbafe182948f: all 40 entry codes match exactly. The 40 records contain 39 unique codes (one intentional identical code appears in separate published variants); do not deduplicate the published choices.
- Reviewed command size: longest bundled code 144 characters; current presets fit under 255 characters when combined with a normal bot name and command prefix.
- Follow-up branch `fix/nt1-confirm-class-package-audit` hardens the roster **Confirm target** path to check both name and expected class, clears a failed target binding, and avoids carrying a stale preset class into direct NT1 import. Lua regression tests cover wrong-class confirmation and all bundled code lengths.
- Follow-up packaging guard verifies the test ZIP includes the website presets, original spec UI, and every .toc referenced dependency. [Draft PR #5](https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/5) passed its NT1 regression/package run [38129460781](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38129460781), Lua lint [38129460779](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38129460779), and Lua format [38129460771](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38129460771) on code commit cac1a9d9b7b69bf6e28891b91277b88be025d371. The generated test artifact is multibot-nt1-talents-test (11698807107). **CI is green, but real-client testing is pending; this PR is not merged.**
- No change to server code, SQL, DBC, mod-playerbots, original bridge spec apply, or published N Addon Collection v2.0.0.
- **Next steps:** review the follow-up PR and its CI; do not merge without reviewing checks. Then install the approved standalone test artifact with backups, obtain screenshots of all 3 pages, test same-account /reload and full relog storage, and report actual in-client behavior. Server Apply stays experimental until database and disposable-bot rollback are prepared.

### Acceptance checklist — exact next tests

- [x] Account-wide saved NT1 storage and name collisions/overwrite/delete confirmation implemented.
- [x] Two-page import vs Saved Builds view and website class-specific preset browser implemented.
- [x] Original Bot specs option and fallback kept for unsupported/unconverted classes.
- [x] Preserve 40 pinned converted Vanilla NT1 entries and add seven owner-approved Warrior builds (47 total); keep Warlock and Death Knight excluded.
- [x] Main Lua 5.1 syntax, save/browser, NT1 targeting, toolbar and consumables tests passed in [38128866892](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128866892). PR Lua format passed in [38128788059](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128788059); main Lua lint passed in [38128866899](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128866899).
- [x] Latest main workflow [38128977780](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128977780) uploaded artifact multibot-nt1-talents-test (artifact 11698466588), source commit 7bc9baaf9e4f2e8f97c61ce475db2cdea6671dd5. Packaging/upload steps passed; manual archive extraction and in-game validation remain outstanding.
- [ ] Before installation, shut down WoW; back up Interface/AddOns/MultiBot and account WTF SavedVariables (especially MultiBot.lua and separate account data). Keep v4.0.3 for rollback.
- [ ] Page 1: Save two codes under different names, test second-click overwrite and name/input field. Enter in name field must NOT Apply.
- [ ] Page 2: Browse names, five-per-page navigation, Load to import, two-click Delete. Confirm no server messages from browsing or saving.
- [ ] /reload and relog: saved builds persist, including on a different character of the same account, without overwriting old MultiBot config.
- [ ] Mage's bot roster Set Talents shows exactly 3 converted Raid/Solo records. Check Rogue, Hunter, Druid, Priest and Shaman counts. **Warrior should now show 7 entries (All 7 / Raid 4 / Solo 3), with two pages and original Bot specs button.** Warlock and Death Knight remain excluded; Paladin has no approved converted records. These three unavailable classes must retain the original Bot specs menu.
- [ ] Selecting a website preset only loads it; actual target mismatches must fail until correct bot targeted and Confirm target clicked.
- [ ] Test website Browse > Bot specs access to original bridge functionality.
- [ ] Review all three screens with user's enlarged UI font, no overlapping buttons/labels, good page spacing and no Lua errors.
- [ ] Check previous 4.0.3 consumables right-click info and opt-in visibility buttons still work.
- [ ] Do not execute experimental server Apply without verified characters DB and disposable bot backup. Previously observed 51-point success is not verification of all spell/rank/permanence behaviors.

### Rollback and long-term maintenance

The UI and offline preset codes do not require server recompilation or SQL/DBC changes. On client regression, close WoW and restore the original MultiBot folder. Existing WTF SavedVariables should be preserved; restoring an older WTF backup may erase newly named codes. Disabling server talent import prevents future applies but does not undo any previous actual bot talent mutation.

Next after in-game UI acceptance: reconcile website data revisions and keep source SHA and group counts current; consider Raid/Solo filters or search if the preset list grows; handle full-length Wrath NT1 codes by a properly authorised server-side protocol (never truncate to fit chat); add Paladin/TBC/Wrath only once the website publishes verified converted records; separately validate Naxxramas Core importer ownership/persistence/rollback; import standalone MultiBot changes into a *new* collection version only with separate user approval.

## Current task — consumables menu and dungeon information (4.0.3)

**Player request:** Reverse the eight visible dungeon entries from their previous top-to-bottom UBRS-to-Maraudon order, and provide a read-only explanation when right-clicking any dungeon icon.

### Implementation details

- Source: UI/MultiBotConsumablesUI.lua. The internal DUNGEON_PROFILES array remains in the same order and retains the same left-click icon/command associations. The menu grows upward from Consumables, so the new vertical position of each entry is (#DUNGEON_PROFILES - index) * 34. This displays Maraudon first at the top, then Sunken Temple, BRD, Scholomance, Stratholme Undead, Dire Maul, LBRS, ending with UBRS at the bottom. The generic Help icon remains separate.
- Each profile now stores its level cap, protection or wing-specific explanatory text. The doRight handler calls ShowProfileInfo, opening the reusable MULTIBOT_CONSUMABLES_PROFILE_INFO StaticPopup. This action MUST NOT call RunProfile, SendChatMessage or alter bots. The standard tooltip identifies right-click as the information action.
- Descriptions are checked against CosmicCuddle/Mod-Naxxramas-Core, src/Systems/BotRaidConsumables.cpp: PrepareDungeonBot and ResolveNamedProfile.
- Shared bot preparation: eligible class/spec-role elixir, suitable Well Fed/Grilled Squid/Nightfin food, scrolls and level-appropriate healing/mana potions. This is an overview, not a promise that every bot receives every item.
- Server-specific profiles: Maraudon and Sunken Temple cap 54 + Nature Protection; BRD cap 60 + Fire Protection; Scholomance cap 60 + Shadow Protection; Stratholme Undead cap 60 + Shadow Protection (Undead/Service Entrance side required); LBRS cap 60 + Lower side (no special protection); UBRS cap 60 + Upper side, Fire Protection, enhanced supplies; Dire Maul cap 60 auto-detects East (Nature), West (Shadow), North (enhanced supplies).
- Enhanced supplies can include eligible Heavy Runecloth Bandages, Limited Invulnerability Potions, caster/healer oils and Rogue poisons. They are *supplied*, not all directly applied as auras.
- MultiBot.toc updated to 4.0.3. The feature remains a standalone test change and is excluded from the already published N Addon Collection v2.0.0, which stays on the approved MultiBot 4.0 source pin.
- Automated test: tests/test_consumables_profile_info.lua checks every profile's position and command, read-only right-click and appropriate cap/protection. Existing NT1 and default-off setting regressions still run. CI entry point: .github/workflows/nt1-playerbot-talents.yml.

### Exact next task — in-game verification of 4.0.3

1. Confirm GitHub Actions Lua 5.1 test, repository-wide lint and format runs pass on the pull request. After merging, record the final main SHA, main workflow run and downloadable MultiBot test artifact.
2. Exit the WoW client. Back up Interface/AddOns/MultiBot and WTF SavedVariables (keep 4.0.2 available). Install the test ZIP containing exactly one MultiBot directory.
3. Enable Bot Consumables in the main MultiBot configuration bar if it is disabled. Open its dungeon submenu. Confirm top-to-bottom: Maraudon, Sunken Temple, Blackrock Depths, Scholomance, Stratholme Undead, Dire Maul, Lower Blackrock Spire, Upper Blackrock Spire. The separate Help icon remains.
4. Right-click Maraudon: information popup should mention level cap 54 and Nature Protection. Check Sunken (Nature), BRD (Fire), Scholomance and Stratholme Undead (Shadow), Dire Maul (East/West/North), LBRS (no dedicated protection), UBRS (Fire and enhanced extras).
5. Right-click must never send bot consumable commands. Left-click must still send the correct command for the same icon. Only intentionally test the live effects while physically in the correct instance/wing.
6. Check large-font popup wrapping, /reload, configuration visibility toggles, general Help, custom level prompt, NT1 Talents and other MultiBot functionality. Record screenshot and Lua errors.
7. Update this roadmap with real screenshot/test outcomes and precise next task. Do not mark visual tests passed solely from Lua mocks.

**Rollback:** close WoW; restore the backed-up MultiBot 4.0.2 directory. Only restore WTF SavedVariables if needed, because a restore can overwrite newer settings. Read-only right-click has no server effects; previous left-click consumable commands may have applied auras or supplied items, which client rollback cannot undo.

**Current verification:** [PR #3](https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/3) merged at 7903afb2b3145dc27497f953f976a783fac7a11e. Main-branch [Actions 38085599581](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38085599581) passed the NT1, visibility and new consumables info/order Lua 5.1 tests and built the multibot-nt1-talents-test ZIP. PR lint and format passed before merge. **Real-client popup and menu visuals remain unverified.** The experimental server NT1 talent importer is unchanged.

## Current baseline and separation of responsibilities

MultiBot is a bridge-first client addon for AzerothCore Playerbots. Its UI, rosters, commands, inventory and strategies rely on the existing MultiBot bridge for most structured operations. The MultiBot 4.0 fork already includes custom Naxxramas consumables integration in UI/MultiBotConsumablesUI.lua.

The new **NT1 Talents** control is a deliberate server-specific exception that calls the already-existing Naxxramas Core CommandScript command. It is **not** a new general chat command executor, a change to mod-playerbots, or an alteration of the upstream bridge's TALENT_APPLY_V1 protocol.

Server command source: https://github.com/CosmicCuddle/Mod-Naxxramas-Core/blob/main/src/Systems/BotTalentImport.cpp  
Server requirements and experimental test history: https://github.com/CosmicCuddle/Mod-Naxxramas-Core/blob/main/docs/PLAYERBOT-NT1-TALENT-IMPORT.md  
Talent code producer: https://github.com/CosmicCuddle/N-Talent-Calculator-  
Website-compatible codes: https://github.com/CosmicCuddle/Naxxramas-Resource-Hub/tree/main/talents

The v2.0.0 Addon Collection release is already published and must remain unchanged. Its source pin for MultiBot 4.0 is d1606832a083ebf660d67b629b07207b184590dd. The new button is not in that release and must not be imported into it retroactively. An approved future suite version and explicit import PR are required.

## Current work: NT1 Talents button (MultiBot 4.0.1)

The request is one new Talents button, adjacent to MultiBot's existing right-side quest/group/consumables controls. A player targets an online Playerbot and opens the button. The new window shows:

- Name and detected class of the character that was targeted when opened.
- Clear instructions to paste an NT1 build code from N Talent Calculator or the Resource Hub.
- A genuinely formatted example: NT1:vanilla:warrior:3g-1 (this is a single-point illustrative code, not a raid build).
- One paste box, plus Preview, Apply talents and Cancel.
- Preview sends a read-only server command, leaves the dialog open and relies on server chat for results.
- Apply talents, or Enter in the edit box, sends the exact server apply command and closes the box on dispatch. Server chat determines if application actually succeeded.
- Escape and Cancel close without changing talents.

The constructed commands are:

    .naxxbot talents preview <online-botname> <NT1-code>
    .naxxbot talents apply <online-botname> <NT1-code>

Client protections: capture the selected target's name and GUID at dialog opening; refuse apply/preview after a target change, including a changed GUID with the same displayed name. Require an actual player-type game target distinct from the user's character. Reject empty codes, malformed NT1 sections, unknown era/class, duplicated entries and a known mismatch between the code class and targeted character class.

The input may hold up to 2048 characters for validation, matching the server code format maximum, but the complete single SAY chat command must not exceed **255 characters**. The client does not split or truncate a longer code. Longer codes need a future dedicated server-supported transfer; this UI explicitly refuses them. Treat this as a known limitation, not a silent success. No clipboard-reading API is required: players paste manually.

### Exact files in this change

| File | Responsibility |
| --- | --- |
| MultiBot.toc | Version 4.0.1, loads the new UI file after Consumables and before Core/MultiBotInit.lua |
| Core/MultiBotInit.lua | Calls the new single right-toolbar initializer |
| UI/MultiBotNT1TalentsUI.lua | Button, 3.3.5a paste frame, syntax check, target/GUID binding, optional preview and apply |
| tests/test_nt1_bot_talents.lua | Lua 5.1 frame mocks, code validation, selected target safeguards, preview/apply and Escape tests |
| .github/workflows/nt1-playerbot-talents.yml | Targeted Lua 5.1 regression and install-ready test ZIP artifact |
| README.md | Usage, command contract, prerequisites, warning and link to handover |
| ROADMAP.md | This authoritative Naxxramas fork handover |
| docs/ROADMAP.md | Previous fork/upstream bridge migration history, retained intact |

The UI module does not modify UI/MultiBotSpecUI.lua, which continues to provide premade Playerbots specs, nor the bridge, consumables, Playerbots, Individual Progression or core AzerothCore code. This separation is intentional.

## Current feature — optional Naxxramas toolbar buttons (4.0.2)

The 4.0.1 fork showed the right-side NT1 Talents and Bot Consumables controls unconditionally. The player requested two independent visibility controls inside the existing vertical MultiBot configuration bar, **both off by default**. The change follows the existing main-bar on/off and SavedVariables conventions rather than creating separate settings.

### User-visible behavior and source changes

- **Show Bot Consumables** (elixir icon, off by default): enables the original right-side Consumables button and its dungeon profile menu. Disabling hides that button and closes any open consumables menu. Does not change the consumables logic.
- **Show NT1 Talents** (book icon, off by default): enables the right-side NT1 Talents button. Disabling hides it, closes the paste window, and clears input focus without sending a command.
- Both switches can be enabled independently. If exactly one is on it uses right-side x=102; when both are on, Consumables uses x=102 and NT1 x=136. No large unnecessary blank gap.
- Saved keys are ShowBotConsumables and ShowNT1Talents in the *existing* main-bar profile store, restored on addon load and saved on click/logout. Missing keys mean off, including existing users upgrading from 4.0.1. Saved configuration-bar button order and Shift+RightClick swapping remain available.
- NT1 dialog now has width 590 and height 348, with shorter, separated title, target, instructions, example, entry, status and warning. This addresses the overlapping text in the actual player's large-font screenshot. The original near-empty-looking Talent.blp icon is replaced by WoW's stock book icon.
- These are client-side **visibility preferences**; they do not change Naxxramas Core's server-side AccessMode, bot permissions, expansion validation or the NT1 application command.

| File | Responsibility in 4.0.2 |
| --- | --- |
| UI/MultiBotMainUI.lua | Two initially-disabled config toggles, immediate save and dynamic right button visibility |
| Core/MultiBotInit.lua | Apply hidden defaults immediately after constructing right-side custom buttons |
| Core/MultiBotHandler.lua | Restore state from existing mainBar SavedVariables and write at logout |
| UI/MultiBotNT1TalentsUI.lua | Taller, better-spaced paste window and stock book icon |
| MultiBot.toc | Standalone 4.0.2 test version |
| tests/test_naxxramas_button_visibility.lua | Default-off, each combination, popup/menu close, positions, persistence hooks |
| tests/test_nt1_bot_talents.lua | Previous target and input safety plus window sizing/icon regression |
| .github/workflows/nt1-playerbot-talents.yml | Run both Lua 5.1 test scripts and syntax checks |
| README.md | Feature configuration and known limitations |
| ROADMAP.md | Maintainer record, live evidence and next step |

### Recorded 4.0.1 in-game feedback

The user provided screenshots showing the new Talents button and window loaded and correctly targeted Mage **Nelje**. Read-only Preview displayed tree point counts; Apply later returned a server message that **Nelje had 51 spent and 0 unspent points** with the existing grouped random-bot nonpersistent-profile warning. This confirms the experimental command-level test succeeded, **not independently checked talent spells or safe database rollback**. The screenshot also clearly showed overlapping oversized text and an empty-looking small icon.

### Exact next task — in-game verification of 4.0.2

1. Confirm GitHub Actions validation and the main-branch test ZIP after merge; record its exact SHA and run. Do **not** modify the published N Addon Collection v2.0.0 package.
2. Close WoW; back up the MultiBot folder and account/character WTF SavedVariables; extract only the new MultiBot/ folder from the install-ready ZIP.
3. On a fresh config/profile, both custom right-side buttons must be hidden and both new buttons in the *main configuration bar* must be off.
4. Enable **only Consumables**. Its existing elixir button and dungeon menu must work; NT1 must stay hidden.
5. Disable Consumables and enable **only NT1**. Its book icon must be visible in the same first available right-side slot; open the popup and check text no longer overlaps at enlarged UI scale.
6. Enable both simultaneously. Buttons must be adjacent and usable. Disable Consumables with its menu open (menu should close). Disable NT1 with paste window open (window should close, no command sent).
7. Test /reload, full logout and relog with each combination. Toggle settings must persist. Disable both again and confirm persistence; old settings/layout must remain intact.
8. Check config bar Shift+RightClick reorder, existing premade talent-spec controls and consumables help, and verify no Lua errors or misplaced clickable areas.
9. Use **Preview** on a disposable bot if needed. A new actual Apply trial requires characters database and per-bot talent backups, same as the separate server safety notes below. Independently inspect trained talent ranks/spells before calling the server importer fully tested.
10. Send screenshots of the config bar and the refined NT1 window; record results in this document and change the next task accordingly.

**Acceptance:** real-client screenshot, two independently functioning default-off switches, persisted SavedVariables and readable popup. Automated Lua mocks alone do not establish visual success.

### Progress checklist

- [x] Code for two independent default-off config bar toggles, layout and menu cleanup
- [x] Saved-state restoration and immediate write through the existing profile store
- [x] Initial display suppressed on addon construction
- [x] Larger NT1 window with shorter labels and stock icon
- [x] Main [NT1 and visibility CI 38084785531](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38084785531) passed, produced the install-ready test ZIP and preserved existing target/transport tests. Main Lua lint also passed. [PR #2](https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/2) merged. Screenshot and persistence acceptance still pending.
- [ ] New build tested and screenshots reviewed in real WoW client
- [ ] Saved states confirmed after reload/relog
- [ ] Actual 51-point talents and learned spells independently checked when approved

## Server-side status and explicit precautions

Naxxramas Core's importer is experimental. Its AccessMode setting is disabled by default:

    NaxxramasCore.BotTalentImport.AccessMode = 0

Mode 0 disables both commands. Mode 1 enables GM access to preview and apply. Mode 2 permits GM and authorised non-GM player access; the server enforces same-account or actual Playerbots master/group conditions as appropriate. Mode 1/2 **both allow real talent mutation**; there is no safe preview-only active mode. The addon must never claim that showing the popup means the server feature is available or that command dispatch guarantees success.

The server has reported a successful grouped-random-bot NT1 application to disposable random Mage bot Zevon (51 spent, 0 unspent). This was an experimental happy-path screenshot, not proof that all classes, learned spells, full randomisation protection or crash recovery are safe. The server importer can reset/relearn talent ranks and performs only best-effort recovery, not an atomic SQL transaction. Random Playerbots can rerandomise and replace talents even during the same group session. Random bot NT1 profiles are intentionally not saved as persistent desired profiles.

**Before any Apply test**, back up the entire acore_characters database and the original talent data for a disposable controlled bot. Check the required optional characters SQL migration with the Naxxramas Core maintainer notes. Configure the server only in a controlled test environment. Disabling AccessMode later prevents new apply operations but does not undo any previously applied character talents.

The addon update alone does not require recompiling worldserver. The server C++ importer must already be compiled/restarted, enabled in config and have any required optional persistence table installed. Never copy the server command logic to the client or bypass its permission checks.

## Completed implementation ledger

| Milestone | Status / evidence |
| --- | --- |
| Original bridge-first UI work | Preserved upstream architecture and docs/ROADMAP.md migration records |
| Naxxramas consumables integration | Present in current standalone MultiBot 4.0, built against Naxxramas Core BotRaidConsumables.cpp |
| N Addon Collection v2.0.0 | Published; approved pin remains MultiBot 4.0 |
| Naxxramas Core NT1 command | Implemented separately; one experimental grouped random-bot application observed |
| New targeted NT1 Talents button | PR #1 merged as e33e87954cb53e5c8cb21b694faae37653dea180; [main NT1 CI 38083840788](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38083840788) passed; **real client not yet tested** |
| Target-safe code entry and Preview/Apply dispatch | Implemented; Lua 5.1 target, GUID, grammar, no-send/preview/apply and Escape tests **passed** in Actions 38083632251 |
| Packaged MultiBot standalone test ZIP | [Main workflow 38083840788](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38083840788) succeeded with artifact multibot-nt1-talents-test; still requires actual client acceptance |
| Permanent roadmap | This file, with next test and recovery instructions; keep updated with the PR |

## Immediate next task — validate feature in WoW, not only in a Lua mock

1. **Completed CI; next task is client testing.** [PR #1](https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/1) merged as e33e87954cb53e5c8cb21b694faae37653dea180. [Main NT1 build 38083840788](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38083840788) and Lua lint passed. Install the artifact in WoW and validate the live popup; no server mutation has been verified through the new UI.
2. Before replacing the addon, close WoW and back up Interface/AddOns/MultiBot and the account/character WTF SavedVariables. Keep the previous 4.0 build available for rollback.
3. Launch WoW 3.3.5a at the usual UI scale and target a disposable online Playerbot. Click the new NT1 Talents control in the right-hand MultiBot bar. Screenshot the dialog and check layout, example, button placement, focus and error labels.
4. With the importer disabled (AccessMode 0), use Preview and verify Naxxramas Core refuses the command. Check that merely opening the popup never sends a command.
5. If a tested SQL and characters backup is ready, enable mode 1 as GM (or mode 2 for authorised normal players) on a controlled test server. Preview a valid code; confirm the server's read-only talent/point breakdown.
6. Change target before clicking Apply. Verify the popup refuses and sends no command. Retarget the original bot and reopen.
7. Explicitly agree to a disposable-bot application, then press Enter or Apply. Verify server chat response and inspect the bot's actual talents, points, learned spells and behaviour. A "command sent" UI message is *not* proof of a successful server mutation.
8. Verify no incorrect target is affected. Test no target, own player, wrong class, empty and invalid codes, malformed entries, overlength chat commands and Escape/Cancel.
9. Try a real full 51-point exported Vanilla code and a 71-point Wrath code. If too long, ensure the UI displays the safe failure instead of sending truncated data.
10. Repeat at different UI scales and confirm prior premade spec selection, consumables and bridge UI still work. Record failures, screenshots and server logs here.

Exit criteria: client screenshot, accurate Preview result, command dispatch correctness and independently inspected bot talents. Leave the server mutation feature experimental until all permissions, persistence and rollback paths are verified.

## Next tasks after acceptance

P1 — fix UI positioning or localized text if client evidence shows clipping or unreadability. Keep only one right bar button, not duplicated spec buttons.

P2 — investigate reliable long-NT1 transmission only if realistic builds exceed the 255-character SAY envelope. This would require a separately audited addon-message protocol / bridge feature with proper server permission and chunking, not a cosmetic client workaround. No generic arbitrary command sender.

P3 — test alt bots versus grouped random bots for GM and ordinary players. Verify foreign-master and unrelated grouped bots cannot be modified. Test Playerbots rerandomisation, relog and combat/death rejection.

P4 — update version and publish standalone MultiBot only after user approval and real tests; do not replace the N Addon Collection v2.0.0 release or silently add the new code. A subsequent collection release needs its own approved source pin, CI package tests and new tag.

P5 — continue the remaining upstream Chatless follow/attack/stay audit from docs/ROADMAP.md, keeping the bridge first and the Playerbots source untouched.

## Development, test and rollback instructions

Offline: install Lua 5.1 and run

    luac5.1 -p UI/MultiBotNT1TalentsUI.lua
    luac5.1 -p Core/MultiBotInit.lua
    lua5.1 tests/test_nt1_bot_talents.lua

The GitHub Actions workflow creates multibot-nt1-talents-test, with an install-ready ZIP containing one MultiBot/ folder. Unpack that ZIP **directly** into WoW 3.3.5a Interface/AddOns. Do not add an extra repository-named wrapper directory. Use backup copies when replacing original files; do not delete the old working build permanently. No server SQL or DBC changes are bundled in this addon.

Client rollback: exit WoW, restore the old MultiBot directory and WTF SavedVariables as needed, then restart. Server talent rollback after Apply is a different procedure: restore the disposable bot's talent data using the verified characters database backup or the documented core recovery method; disabling the command is not a rollback of completed talent changes.

## Documentation rule — every change

Update this roadmap in the same GitHub PR/commit as changes to source, server command assumptions, addon loading, test scripts or builds. Record changed files, exact version/SHA, what is CI-only versus client-tested, unresolved risks and the concrete next task. Preserve upstream author and licence notices and the independently maintained bridge-migration history. Do not claim success without tests. A chat reset must not prevent the next maintainer from continuing at the next numbered test above.
