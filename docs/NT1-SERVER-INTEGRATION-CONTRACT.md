# NT1 Playerbot — Client / Server Integration Contract

**Maintainer checkpoint:** 11 October 2026. This document records the approved boundary for MultiBot v4.0.4, not a deployed server handshake. Do not implement proposed fields as though the server already sends them.

## Authoritative upstream references

- Server repository: https://github.com/CosmicCuddle/Mod-Naxxramas-Core
- Server integration audit: draft https://github.com/CosmicCuddle/Mod-Naxxramas-Core/pull/6 (audit commit `a359f9b38bda4262821b13c481060425d8c4f8ad` against main `1e00c5537a1e22d1be7572437c884ca05f4c3337`).
- Addon work: draft https://github.com/CosmicCuddle/N-MultiBot-Chatless/pull/5. Inspect PR HEAD rather than relying on the older `6a935f1` snapshot in the server audit.
- Implementation: `UI/MultiBotNT1TalentsUI.lua`; product integration/next actions: root `ROADMAP.md`.

## Current supported transport (legacy, unstructured)

```text
.naxxbot talents preview <online-bot-name> <NT1-code>
.naxxbot talents apply <online-bot-name> <NT1-code>
```

- Addon dispatches these via `SendChatMessage(command, "SAY")`, **never** the original bot whisper or a generic privileged-command bridge. The command must fit the conservative 255-character 3.3.5a message envelope. Do not truncate, split, silently reroute or claim direct server invocation.
- Client locally checks the NT1 format, known class, talent rank 1–5, duplicate code tokens, target identity/GUID when present, and full command size. This is **not** DBC verification, ownership authority, IP unlock proof, or level-specific validation.
- The user explicitly presses Preview for read-only server validation. Current Preview may report a valid code while a subsequent Apply is denied by additional server-side preconditions. Therefore **Preview ≠ APPLY_READY**.
- The user explicitly presses Apply and confirms a separate StaticPopup. A repeat check of live target and unchanged code occurs on confirmation. A successful `SendChatMessage` means **only that the request was dispatched**, not that talents changed.
- Code browser, saved build load/delete/save, import/export, All/Raid/Solo filters, and original Bot specs menu **must never dispatch Apply**.
- Config `NaxxramasCore.BotTalentImport.AccessMode = 0` denies both server commands by default; an addon cannot enable it. A mode of 1/2 permits experimental Apply subject to server checks. The Alt Bot human-character name allowlist defaults to empty.
- The addon has **no authenticated or structured response API** today; do not fake `APPLY_SUCCEEDED` by parsing its own dispatch or assuming that generic visible chat is trustworthy.

## Status and implementation boundaries

| Capability | State |
| --- | --- |
| Legacy NT1 Preview / Apply commands | Implemented in server, Apply experimental |
| Local import-window confirmation and build summary | Implemented in addon PR #5; not yet in-game verified |
| Named Saved Builds / NMB1 text backup and website filters | Implemented in addon PR #5; not yet in-game verified |
| Server-backed APPLY_READY / APPLY_BLOCKED / APPLY_SUCCEEDED | Proposed, not implemented |
| Short-lived server-bound confirmation token, exact applied plan checksum | Proposed, not implemented |
| Level-30 projection from level-60 source build | Proposed, not implemented |
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

**MultiBot only:** four-page UI, safe syntax hints, selection/filters, local account SavedVariables backups, deliberate request confirmation, display of future authoritative response fields, original spec fallback. Website presets for **Warrior are now owner-approved** as seven direct Vanilla calculator links (3 Solo, 4 Raid; each 51 talent points), alongside the original 40 pinned entries. **Warlock and Death Knight remain excluded** until separate owner approval; Paladin has no approved website presets. This does not restrict manual NT1 or original Bot specs (including the Warrior Bot specs button).

**Mod-Naxxramas-Core only:** parsing loaded Talent.dbc/Spell.dbc, tier/prerequisite/full budget legality, target control, online/master/group checks, Alt Bot allowlist, issuing-human Individual Progression stages 8/13, server readiness/projection token enforcement, talent changes, equipment provenance and rollback. Alt Bot equipment/bags/earned items must not be changed by NT1.

## Test gates

1. **Offline addon CI:** Lua 5.1 syntax/transport guard, no Enter Apply, dialog cancel/stale target/code safety, website filtering and class exclusions, account-wide SavedVariables fixture, export/import corruption/overwrite, packaging/lint/format.
2. **In-game UI:** test PR #5 standalone ZIP with AddOns/MultiBot and account WTF backups, larger UI scale, all four pages, ESC, popup confirmation cancel, class/target mismatch, /reload, full relog and original Bot specs. Test in mode 0 with no live Apply.
3. **Server integration (separate PR):** demand observed post-GENERAL-header-fix compilation and server-owned preflight protocol, disposable-bot baseline and verified `acore_characters` rollback before any destructive Apply. Source's earlier Zevon 51/51 success does not validate newer checks.
4. **Release:** no PR merges or N Addon Collection v2.0.0 changes absent explicit owner approval and actual client acceptance.

**Outstanding question for server maintainers:** what exact authenticated/framed message mechanism and complete schema can carry Preview readiness/plan/role safely to 3.3.5a clients within transport limits? Maintain today's command semantics until resolved.
