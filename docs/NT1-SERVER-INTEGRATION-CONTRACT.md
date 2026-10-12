# NT1 Playerbot — Client / Server Integration Contract

**Maintainer checkpoint:** 12 October 2026 — verified against **Mod-Naxxramas-Core `main` at `69a91be2ded62f6cdccf7ca6e7119ebdcc45e81b`**, after merged server PRs #14, #15 and #16. **This is repository/source review, NOT confirmation the operator has pulled, rebuilt or restarted the new Worldserver binary.** The operator's last reported installed source was `969f0429b4f02d8ba64ee83ecf4c91323e474bdd`, with binary provenance unverified. MultiBot 4.0.4 draft PR #5 remains unreleased. Do not assume this server supplies a structured client handshake or that experimental Apply/rollback has passed.

## Authoritative upstream references

- Server repository: https://github.com/CosmicCuddle/Mod-Naxxramas-Core
- Server integration history: [merged read-only integration #14](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/pull/14), [merged AccessMode 4 #15](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/pull/15), [merged ten-class read-only safety #16](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/pull/16). An earlier, separate draft [server documentation PR #6](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/pull/6) predates these and is **not** the current implementation.
- Addon work: draft https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/5. Inspect PR HEAD rather than relying on the older `6a935f1` snapshot in the server audit.
- Implementation: `UI/MultiBotNT1TalentsUI.lua`; product integration/next actions: root `ROADMAP.md`.

## Current MultiBot transport (single SAY commands, no structured acknowledgement)

```text
.naxxbot talents preview <online-bot-name> <NT1-code>
.naxxbot talents apply <online-bot-name> <NT1-code>
```

**Additional read-only commands in the newly merged server source (Safety Inspection is now optionally wired in draft MultiBot PR #5):**

```text
.naxxbot talents project <online-bot-name> <NT1L1-code>
.naxxbot talents repairpreview <online-altbot-name> <NT1-code>
.naxxbot talents safetypreview <online-altbot-name>
```

- `project` uses an **explicitly authored NT1L1 rank-purchase sequence**, not an ordinary final-rank NT1 preset. Read-only projection can show a lower-level candidate; **no projection Apply command exists**. Never derive an NT1L1 ordering by sorting an existing website NT1 code.
- `repairpreview` reads an existing Alt Bot's protected/current talent state while checking a proposed NT1 code; `safetypreview` is a **no-code** Alt Bot risk diagnosis for both talent specs, pets and equipped items. Both are read-only, reject Random Playerbots, and require the **issuing human character** to be in `NaxxramasCore.BotTalentImport.AltBotAllowedPlayers`, including GMs. An eligible non-GM must directly control the bot. **Draft PR #5 now offers a manually clicked `Safety Inspection` button on Page 1; it sends `safetypreview` only. `repairpreview` and `project` still have no UI buttons.**
- The current server returns human-facing chat messages. **No authenticated machine-readable receipt, APPLY_READY token, expiry-bound plan ID or safe projected Apply API was introduced.** Do not implement client-side parsing that treats those messages as an authenticated permission or success signal.

- MultiBot dispatches Preview, Apply and **explicitly clicked Safety Inspection only**, not `project` or `repairpreview`, via `SendChatMessage(command, "SAY")`, **never** the original bot whisper or a generic privileged-command bridge. The command must fit the conservative 255-character 3.3.5a message envelope. Do not truncate, split, silently reroute or claim direct server invocation.
- Client locally checks the NT1 format, known class, talent rank 1–5, duplicate code tokens, target identity/GUID when present, and full command size. This is **not** DBC verification, ownership authority, IP unlock proof, or level-specific validation.
- The user explicitly presses Preview for read-only server validation. Current Preview may report a valid code while a subsequent Apply is denied by additional server-side preconditions. Therefore **Preview ≠ APPLY_READY**.
- Apply's user hardware click may first attempt `/targetexact <roster-bot-name>` through a WoW 3.3.5a `SecureActionButtonTemplate` macro (strictly validated name, configured out of combat). This is a target-selection convenience only: match live name/class, any previously bound GUID, and unchanged NT1 code before the separate StaticPopup; failure falls back to manual targeting instructions. No insecure targeting function is used, and selecting a bot without a click never triggers the macro. Hardware-click targeting and cancel were owner-confirmed for the tested bot in an earlier development ZIP; they do not establish general-combat readiness or server-side Apply success.
- The user explicitly presses Apply and confirms a separate StaticPopup. A repeat check of live target and unchanged code occurs on confirmation. A successful `SendChatMessage` means **only that the request was dispatched**, not that talents changed.
- Code browser, saved build load/delete/save, import/export, All/Raid/Solo filters, and original Bot specs menu **must never dispatch Apply**.
- **The server alone controls command permission** through `NaxxramasCore.BotTalentImport.AccessMode`. The addon keeps its Preview and Apply controls, does not change server configuration and cannot claim that request dispatch equals server acceptance.
  
  | AccessMode | Server permission at the merged source (once compiled/deployed) |
  | --- | --- |
  | `0` | Disabled (**distributed default**) |
  | `1` | GM commands; read-only diagnostics and **experimental destructive Apply** |
  | `2` | GMs plus eligible ordinary players; diagnostics and **experimental destructive Apply** |
  | `3` | GM **read-only** diagnostics and projection; **Apply blocked** |
  | `4` | GMs plus eligible ordinary players **read-only** diagnostics and projection; **Apply blocked** |

- Modes 3/4 have explicit Apply refusal at multiple server checkpoints; **no addon-side access-mode toggle or hard-disabling of the Apply button is desired**. The default `AltBotAllowedPlayers = ""` denies Alt Bot repair/safety inspection even in a read-only mode. The latest merged C++ source does **not** prove the live binary already supports mode 4. The last operator-reported live mode was `2`, which allows experimental Apply; do not alter that setting automatically or assume it is safe for testing.

- The addon has **no authenticated or structured response API** today; do not fake `APPLY_SUCCEEDED` by parsing its own dispatch or assuming that generic visible chat is trustworthy.

## Status and implementation boundaries

| Capability | State |
| --- | --- |
| Legacy NT1 Preview / Apply commands | Signatures unchanged in merged server C++; MultiBot sends exactly these. Modes 1/2 may Apply experimentally; 3/4 deny Apply |
| Local import-window confirmation and build summary | Implemented in draft PR #5; layout confirmed in WoW screenshots; target/cancel observed for tested cases; final Apply not tested |
| Optional Safety Inspection button | **New in draft PR #5; awaits in-game visual/runtime verification**. One deliberate click on Page 1 sends `safetypreview <bound-altbot>` after name/class/GUID checks, without an NT1 code; server authorises allowlist/mode/Alt type; no success inference |
| Named Saved Builds / NMB1 text backup and website filters | Website filters and Saved Builds basic save/load/relog confirmed in-game; Page 4 empty-editor appearance reviewed; manual NMB1 transfer deferred |
| Server-backed APPLY_READY / APPLY_BLOCKED / APPLY_SUCCEEDED | Proposed, not implemented |
| Short-lived server-bound confirmation token, exact applied plan checksum | Proposed, not implemented |
| Read-only level-adaptive projection | **Implemented in merged C++ as `project` for authored `NT1L1` codes only**, not standard website `NT1`, not auto-Apply; deployed-runtime acceptance unverified |
| Cross-class read-only Alt Bot safety | **Implemented in merged C++ as `safetypreview`**, plus enhanced `repairpreview`; needs C++ compilation and authorised in-game verification; no gear/pet/spec change or repair | 
| Explicit role selection and secure Random Bot equipment changes | Proposed, not implemented |
| Guaranteed rollback and maintenance-safe talent persistence | Not established |

## Future handshake — requirements only, do not wire to guessed fields

When server PR review defines a secure framed protocol, display:

1. Server-verified bot identity, class, target level and active spec; issuer's Individual Progression era (Vanilla/TBC/WotLK).
2. Source preset/build identifier, requested explicit role (including `cat` or `bear` for Feral), planned talent ranks/three-tree point totals, spent/available points and projected level.
3. Explicit `APPLY_READY` or `APPLY_BLOCKED` with clear reason and immutable server-side plan identifier, expiry and authority/ownership checks; never generate this token client-side.
4. One-time Apply confirmation, valid only for same authenticated issuer, online bot, spec, code, level, progression, role and plan version. Server revalidates before mutating. Client changes invalidate confirmation.
5. Server-confirmed `APPLY_SUCCEEDED`, `APPLY_BLOCKED`, `APPLY_FAILED` or a recovery-needed status. Include `GEAR_UNCHANGED` reason if relevant, without implying gear was modified.
6. An explicitly reviewed method for carrying this metadata within WoW 3.3.5a limits. Avoid spoofable arbitrary chat text, chat-command injection and oversized single-message transport.

Do not submit a new command format, project talent steps in Lua or claim an official Preview/Apply-ready API without a reviewed and tested server counterpart.

## Distinct project responsibilities

**MultiBot only:** four-page UI, safe syntax hints, selection/filters, local account SavedVariables backups, deliberate request confirmation, display of future authoritative response fields, original spec fallback. Website presets total **54**: 40 pinned original Vanilla records, 7 owner-approved Warrior (3 Solo/4 Raid), plus 5 newly owner-approved Warlock (3 Solo/2 Raid) and 2 Mage Solo (Arcane/Fire) from the uploaded 11 October 2026 talent list; each build contains 51 locally encoded points. **Death Knight remains excluded**; Paladin has no approved website presets. This does not restrict manual NT1 or original Bot specs (including the Warrior Bot specs button).

**Mod-Naxxramas-Core only:** parsing actual Talent.dbc/Spell.dbc, tier/prerequisite/full point-budget legality, online ownership/master/group checks, Alt Bot allowlist, issuing-human Individual Progression stages 8/13, server-side read-only previews, experimental talent Apply (modes 1/2 only), original-spec checks and fail-closed equipment/pet risk guards. **Future authenticated readiness tokens, guaranteed rollback, automatic gear handling and protected repair Apply do not exist.** Alt Bot equipment/bags/earned items must not be silently changed by NT1.

## New optional Safety Inspection — client wiring rules

- **Explicit user action only:** new `Safety Inspection` button at Page 1 x=34, y=150, width=184, in the spare second row of the Save As panel. Footer Preview, secure Apply, Cancel and Saved Builds buttons retain their tested positions. Tooltip describes **read-only**, **Alt Bot** requirements and the updated server. It does not add a fifth page or new SavedVariables fields.
- **Wire format:** `.naxxbot talents safetypreview <online-altbotname>` via one **SAY** chat message of at most 255 bytes. No NT1 code is read or appended, even when the editor contains one. The command itself is no-code and cannot mutate talent, gear or pet state according to reviewed server C++ source. Browser navigation, opening the window and target-change events **never auto-dispatch** it.
- **Client checks:** selected player target, known class, exact expected name/class and previous GUID when known, plus strictly 2–12 ASCII-letter command-name. If the wrong target is selected, present guidance; after manual targeting the user must click again. Same-name different-GUID and same-GUID different-class are rejected without dispatch.
- **Server checks remain decisive:** `AccessMode`, online-bot validity, non-GM direct control, Random Bot rejection and **issuing human** `AltBotAllowedPlayers` requirement even for GM. The addon has no capability detection or authenticated receipt. After sending, it says **request sent** and directs user to server chat; unknown command or access denial must not be misrepresented as success.
- **Status:** new UI button is **unverified in the live client**. Regressions check only local command construction, null/wrong/class/GUID target safety and absence of Preview/Apply traffic. Test in-game only **after** the merged server revision is confirmed compiled and deployed, and without using Apply. `repairpreview` is deliberately **not exposed** this batch: it needs a proposed NT1 build and a more involved explicit compatibility/recovery UI, so keep the validated Page 1 layout uncluttered.
- **Scope:** no client-side enable/disable gates based on modes, server updates, SQL/DBC edits, preset changes, SavedVariables schema changes, module startup/restart or public release.

## Test gates

1. **Offline addon CI:** Lua 5.1 syntax/transport guard, no Enter Apply, dialog cancel/stale target/code safety, website filtering and class exclusions, account-wide SavedVariables fixture, export/import corruption/overwrite, packaging/lint/format.
2. **In-game UI:** test PR #5 standalone ZIP with AddOns/MultiBot and account WTF backups, larger UI scale, all four pages, ESC, popup confirmation cancel, class/target mismatch, /reload, full relog and original Bot specs. Test in mode 0 with no live Apply.
3. **Server integration (separate workstream):** server #14/#15/#16 are now **merged into `main`**, but the operator's last recorded installed revision predates them. Before relying on modes 3/4 or new commands, obtain **explicit approval**, preserve module/config/executable backups, perform one reviewed C++ build/restart against the installed compatible AzerothCore/Playerbots/IP sources and verify read-only behaviour in-game. For any future destructive Apply, independently rehearse an isolated **`acore_characters` restore** on a disposable bot; the previous Zevon 51/51 happy path does not prove rollback or all-class safety. No server deployment is authorised by this document.
4. **Release:** no PR merges or N Addon Collection v2.0.0 changes absent explicit owner approval and actual client acceptance.

**Outstanding server-to-client question:** what authenticated/framed message schema can provide Preview readiness, plan identity, role and confirmed Apply outcome within the 3.3.5a limits? The newly merged read-only diagnostics are **human chat reports, not this protocol**. Maintain existing MultiBot Preview/Apply commands until such a protocol is implemented and independently reviewed.
