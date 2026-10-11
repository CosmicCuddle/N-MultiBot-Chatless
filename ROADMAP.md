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
Next immediate task: download the main-branch artifact multibot-nt1-talents-test from [Actions 38128866892](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128866892), back up MultiBot and WTF SavedVariables, test Import Page 1/Saved Builds Page 2/website Set Talents Page 3 at the player's UI scale, check full relog persistence and send screenshots. CI is not proof of real game appearance.

### Requirements and implemented design

- The existing NT1 Import stays Page 1. Paste code, choose a name, Save code. A changed existing code must be confirmed by clicking Save again. Save never applies to a bot.
- Saved Builds > opens Page 2: alphabetical account-wide named NT1 builds, class/era labels, five entries per page, previous/next navigation, Load to import (returns to Page 1) and two-click Delete. None send a server command.
- Separate account-wide SavedVariables table: MultiBotNT1SavedBuilds, declared in MultiBot.toc, independent of N Talent Calculator and existing MultiBot profiles. Previous builds are never migrated or deleted.
- The original bot-roster Set Talents action offers read-only website presets as a third window view, filtered to the exact class of that roster bot. Raid/Solo, spec, role and variation are visible. Load to import moves the NT1 code to Page 1; it does not Apply.
- Bot specs button on the website page keeps access to the previous bridge-driven Playerbots specialization selector. For classes without converted website records, Set Talents uses the old selector immediately.
- From a bot roster, the user may not actually be targeting that character in-game. Applying is then locked until the user targets that bot and presses Confirm target. Wrong target or class cannot bypass validation.
- Naxxramas Core remains the only authority for applying talents, talent/era/point restrictions, ownership and experimental rollback. No C++/SQL/DBC or Playerbots bridge changes.
- Published N Addon Collection v2.0.0 remains unchanged and does not acquire the new calculator or MultiBot snapshot.

### Exact source of the website presets

Owner's site: https://cosmiccuddle.github.io/Naxxramas-Resource-Hub/  
Repo: https://github.com/CosmicCuddle/Naxxramas-Resource-Hub  
Source: assets/naxx-talent-sets-full-sync.js at commit b77f25ea948d77488e9b934c8b66bbafe182948f. The current approved converted **Vanilla** records total exactly 40: Druid 9, Hunter 8, Mage 3, Priest 7, Rogue 6 and Shaman 7 (Raid and Solo variants). The two supplemental Rogue record links in naxx-talent-set-sync.js already occur in the full-sync dataset; do not double-count them.

**Explicitly exclude Warrior, Warlock, and Death Knight from website presets:** Warrior and Warlock remain unfinished/TO BE CONVERTED on the website; Death Knight is separately excluded by the project owner until further approval. This is a hard exclusion in the class-filtered preset browser even if future snapshot data accidentally contains a Death Knight entry. No verified Vanilla NT1 records for Paladin appear in the approved converted full-sync source. Preserve the original Bot specs list for all excluded/unsupported classes; do not fabricate presets. These are offline bundled website snapshots; WoW cannot fetch arbitrary web pages to update the list at runtime. Changes to the website require a deliberate source-pinned regeneration, review and updated tests.

### Files changed

| Path | Responsibility |
| --- | --- |
| MultiBot.toc | 4.0.4 version, account-wide SavedVariables, website preset data load order |
| Data/NT1WebsitePresets.lua | 40 exact converted website NT1 codes pinned to site commit |
| UI/MultiBotNT1TalentsUI.lua | account-wide name/save/load/delete, two import/storage pages, website class page, explicit target re-confirmation, no auto apply |
| UI/MultiBotSpecUI.lua | integrate website page into existing Set Talents menu while retaining Bot specs access |
| tests/test_nt1_saved_builds.lua | names, overwrite/delete, persistence simulation, 40 class-filtered website records, pages and no server mutation |
| tests/test_nt1_bot_talents.lua | prior target safety and command assertions adapted to larger page window |
| .github/workflows/nt1-playerbot-talents.yml | Lua syntax/tests, website snapshot and bundle artifact |
| README.md | new user instructions, source notes and risks |
| ROADMAP.md | this permanent maintainer handover |

### Client safeguards and browsing improvements — staged on PR #5 (11 October 2026)

- Apply is now **two deliberate clicks**: button then WoW StaticPopup with bot name, class, expansion and spent points. Pressing Enter in the NT1 field only ends editing. Confirm-time preflight rechecks the live bot target/GUID, code, class and chat limit. Changed/closed dialogs abort without a server mutation. Preview is unchanged/read-only.
- Page 1 includes a locally decoded class / era / points / known website role summary. This is an information display only, **not** server validation or evidence of usable points/ranks.
- Page 3 includes All / Raid / Solo filters; each change resets selection and pagination. Existing original Bot specs fallback remains intact; Warrior, Warlock and Death Knight stay excluded from website presets.
- New Lua mock regression checks for Enter safety, confirmation cancel/changed target/changed code, valid confirmation and Mage filter counts. These controls are unverified in WoW; all server permissions still apply. Test at enlarged UI scale and after /reload.
- Page 4 adds portable plain-text **NMB1 backup and import** for account-wide named NT1 builds. Export includes all valid saved codes (within a 30 KB EditBox safety cap); users copy with Ctrl+A/C, and import via paste. A strict parser checks header, names, NT1 codes, duplicate names and 100-build capacity before mutating SavedVariables. Changed existing names require two consecutive Import clicks; same-name identical codes are left unchanged. Never transmits a server command; on oversized exports use a manual WTF SavedVariables backup. Automated mock tests exercise format rejection, round-trip, conflict confirmation, and UI page navigation.
- **Next:** Verify PR head CI and inspect all four views in actual WoW 3.3.5a, especially multi-line scrolling, export text selection, copy/paste, overwrite confirmation, re-login persistence, font scaling and no Lua errors. Do not merge/release pending actual client acceptance.

### Additional scope clarification — Death Knight exclusion (11 October 2026)

- Project owner explicitly requested Death Knight be excluded from the website-based NT1 talent preset browser for now, alongside Warrior and Warlock. This affects **only the website preset option**, not the original Playerbot Bot specs functionality or the standalone manual NT1 import. Paladin remains unsupported due to absent verified converted website data.
- A fail-closed class check in `ListWebsitePresets` now blocks Death Knight even if an accidental/future source refresh adds an entry. Lua regression tests inject a temporary Death Knight record and confirm it cannot be listed or opened. The pinned snapshot still contains exactly 40 unchanged converted builds for Druid/Hunter/Mage/Priest/Rogue/Shaman.
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
- [x] Snapshot of 40 confirmed converted Vanilla NT1 entries pinned, explicitly excluding Warrior, Warlock and Death Knight.
- [x] Main Lua 5.1 syntax, save/browser, NT1 targeting, toolbar and consumables tests passed in [38128866892](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128866892). PR Lua format passed in [38128788059](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128788059); main Lua lint passed in [38128866899](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128866899).
- [x] Latest main workflow [38128977780](https://github.com/CosmicCuddle/N-MultiBot-Chatless/actions/runs/38128977780) uploaded artifact multibot-nt1-talents-test (artifact 11698466588), source commit 7bc9baaf9e4f2e8f97c61ce475db2cdea6671dd5. Packaging/upload steps passed; manual archive extraction and in-game validation remain outstanding.
- [ ] Before installation, shut down WoW; back up Interface/AddOns/MultiBot and account WTF SavedVariables (especially MultiBot.lua and separate account data). Keep v4.0.3 for rollback.
- [ ] Page 1: Save two codes under different names, test second-click overwrite and name/input field. Enter in name field must NOT Apply.
- [ ] Page 2: Browse names, five-per-page navigation, Load to import, two-click Delete. Confirm no server messages from browsing or saving.
- [ ] /reload and relog: saved builds persist, including on a different character of the same account, without overwriting old MultiBot config.
- [ ] Set Talents from a Mage's bot roster menu shows exactly 3 converted Raid/Solo website records. Compare Rogue, Hunter, Druid, Priest and Shaman counts; verify Warrior, Warlock and Death Knight are explicitly excluded from website presets, while Paladin has no converted source records. All four must retain the previous Bot specs menu.
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
