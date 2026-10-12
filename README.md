<p align="center">
  <img width="1024" height="1024" alt="MultiBot Chatless" src="https://github.com/user-attachments/assets/08aa1768-f5c2-49ce-9fe0-a22adb184ce7" />
</p>

<div align="center">

# MultiBot Chatless

### Bridge-first Playerbots control for World of Warcraft 3.3.5a

<strong>MultiBot Chatless</strong> is a client addon for AzerothCore `mod-playerbots`.
It keeps the familiar MultiBot UI while moving more bot reads and actions away from automatic chat commands and into a structured server bridge.

<br>

<img alt="WoW Version" src="https://img.shields.io/badge/client-WotLK%203.3.5a-lightgrey" />
<img alt="Architecture" src="https://img.shields.io/badge/architecture-bridge--first-success" />
<img alt="Status" src="https://img.shields.io/badge/status-mostly%20chatless-blue" />

</div>

---

## About This Fork

This repository is a modified fork of [Wishmaster117/MultiBot-Chatless](https://github.com/Wishmaster117/MultiBot-Chatless), based on the original MultiBot addon by Nico Löbbert.

**Fork modifications are maintained by CosmicCuddle.**

**Fork updates — 2–10 October 2026:** this fork adds Naxxramas server-specific Consumables and NT1 Playerbot talent import controls while preserving the upstream MultiBot Chatless code and GPLv3 license.

### Naxxramas Bot Consumables Integration

This fork adds a **Consumables** control to MultiBot for the custom Naxxramas bot consumables system.

The consumables controls require the server-side `BotRaidConsumables.cpp` system from:

- [CosmicCuddle/Mod-Naxxramas-Core](https://github.com/CosmicCuddle/Mod-Naxxramas-Core)
- [BotRaidConsumables.cpp](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/blob/main/src/Systems/BotRaidConsumables.cpp)

Without that server-side system, the custom consumables buttons will not function because the server will not provide the required `.bot consumables ...` commands.

The Naxxramas consumables UI provides:

- named dungeon profiles for Maraudon, Sunken Temple, Blackrock Depths, Scholomance, Stratholme Undead, Dire Maul, Lower Blackrock Spire and Upper Blackrock Spire;
- a custom consumable level input from **1–54** for non-raid dungeons;
- MultiBot-style tooltips and a help panel explaining the consumable system;
- the normal MultiBot Shift + Right-click button swapping behaviour for the main Consumables button.

The rest of MultiBot Chatless continues to use the upstream `mod-multibot-bridge` architecture. The custom Naxxramas consumables controls are an additional server-specific integration and use the commands supplied by `Mod-Naxxramas-Core`.

---


### NT1 Talent Builds — Naxxramas Bot Import (MultiBot 4.0.4 development)

The fork includes **one NT1 Talents button** on the right-hand MultiBot bar, near Consumables. **Both NT1 Talents and Bot Consumables are hidden by default.** Open MultiBot's existing main configuration bar and enable the corresponding book or elixir icon individually; each choice is saved across `/reload` and game restarts. Disabling either hides its right-side button and closes any open submenu/dialog. The visible buttons occupy adjacent slots without a gap when only one is enabled. Target an online bot, click the button and paste an NT1 code copied from [N Talent Calculator](https://github.com/CosmicCuddle/N-Talent-Calculator-) or the [Resource Hub calculator](https://github.com/CosmicCuddle/Naxxramas-Resource-Hub/tree/main/talents).

The refined, taller window avoids overlapping text at enlarged UI scale. It names the selected character, displays the example **NT1:vanilla:warrior:3g-1**, and provides **Preview**, **Apply talents**, and **Cancel**. Pressing **Enter** in the paste box only removes keyboard focus; **it never sends Apply**. Preview is read-only and **does not prove Apply eligibility**. Apply requires a second confirmation dialog, then dispatches an experimental request; the server may still reject it. If the target or code changes during confirmation, the addon refuses to send. **A dispatched message is not server-confirmed success.**

The server must already have [Naxxramas Core's BotTalentImport system](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/blob/main/docs/PLAYERBOT-NT1-TALENT-IMPORT.md) compiled and restarted. Its command interface is:

    .naxxbot talents preview <online-botname> <NT1-code>
    .naxxbot talents apply <online-botname> <NT1-code>

**The server decides whether NT1 Preview and Apply are permitted** via `NaxxramasCore.BotTalentImport.AccessMode`; MultiBot retains both controls and never changes that configuration. The server's merged source now supports **0** (disabled, default), **1** (GM preview and experimental Apply), **2** (authorised ordinary players and GMs; preview and experimental Apply), **3** (GM-only read-only; Apply denied) and **4** (authorised ordinary players and GMs read-only; Apply denied). Modes **1/2 can reset bot talents**. Modes **3/4 only become available on your running server after that module revision has been built and restarted**; older binaries may reject mode 4 entirely. Before any destructive Apply, preserve a restorable characters database backup and disposable bot snapshot; Random Playerbots may rerandomise imported talents.

**Server-only read-only operations (not yet exposed as new MultiBot buttons):** `.naxxbot talents project <bot> <NT1L1-code>` projects an explicitly authored ordered rank plan; `.naxxbot talents repairpreview <altbot> <NT1-code>` inspects an Alt Bot's current state against a proposal; and `.naxxbot talents safetypreview <altbot>` inspects Alt Bot equipment/pet/talent risks without a code. The two Alt Bot diagnostics require the issuing human character in `AltBotAllowedPlayers`, and reject Random Playerbots; non-GMs additionally need direct control. These return descriptive server chat text, **not authenticated Apply-ready/success receipts**. They are not interchangeable with standard `NT1` final-rank presets; never assume the merged source was deployed without confirming the server binary. See [NT1 client/server contract](docs/NT1-SERVER-INTEGRATION-CONTRACT.md) for the current detailed compatibility status.

The popup uses the server's separate NT1 command, not the existing premade Playerbots Set talents/Bridge feature. It refuses malformed or empty input, wrong known class, changed target, and anything exceeding one conservative **255-character 3.3.5a chat command**, avoiding silently truncated builds. A longer build will need a future supported transport mechanism.

**Dungeon Consumables (4.0.3 test):** The dungeon-profile bar now reads **Maraudon at the top** through **Upper Blackrock Spire at the bottom** (closest to the Consumables main icon). **Left-click** continues to request the same server consumables profile. **Right-click** any dungeon icon for a read-only overview of its level cap, common role-based elixirs/food/scrolls/potions and the dungeon-specific protection or supplies. Dire Maul shows East/West/North differences; UBRS has Fire Protection and additional consumable supplies. The right-click overview is approximate, not a live report of exactly which items a particular bot received; the server applies only what is eligible for the bot's class, spec, level and physical dungeon/wing. The general Help button remains available.

### Saved NT1 Builds and Website Presets — MultiBot 4.0.4 Test

**Current visual checkpoint (draft PR #5; not released):** The **Page 1 NT1 Talent Import**, **Page 2 Saved Builds** and **Page 3 Website Class Presets** have been shown in the owner's WoW 3.3.5a client; the new **Page 4 Backup/Import** dark bordered editor, heading, top status, scrollbar and footer have also passed a real-client screenshot readability/overlap review. Page 1's status/name-label contrast was corrected, and the original bot Talent inspection button was fixed after an observed nil-field Lua error; the owner confirmed the corrected Talent window opens. Website preset rows use dark Wrath-style list items with gold **Raid** and blue **Solo** indicators, not solid-red build buttons. These are **UI-only checkpoints**, not permission to run experimental final Apply or evidence of server-confirmed talent changes. The owner explicitly deferred manual NMB1 export/import/overwrite testing; automated Lua 5.1 regression coverage exists, but in-game NMB1 data restoration is not accepted. The latest Page 2 footer tweak and some long-data/other-class cases have not been exhaustively rechecked. Keep PR #5 in draft, preserve the existing addon and `WTF` SavedVariables backups for rollback, and leave the published N Addon Collection v2.0.0 untouched.

**NT1 Import is Page 1.** Enter or paste an NT1 code and a name into the new **Save As** field, then click **Save code**. Existing names cannot be overwritten without a second confirming click. **Saved builds >** opens Page 2. It shows saved names, class and era (five per page), lets you load a chosen code back to Page 1, and requires a second click to delete. The **Backup / Import** button opens Page 4: **Export all** produces an NMB1 text backup that you copy using Ctrl+A then Ctrl+C. To restore builds, paste that text and click **Import pasted**. Import validates the entire backup, including its END marker and record count, and requires a second click before replacing conflicting names. For backups larger than 30 KB, copy the account WTF SavedVariables file manually instead; the addon refuses silent text truncation. Saved NT1 codes are **account-wide** in \`MultiBotNT1SavedBuilds\` (part of the MultiBot SavedVariables); they persist across game restarts and are independent of N Talent Calculator and MultiBot's main settings. Save, browse, load and delete do **not** issue server commands. Preview remains read-only; the class/era/point count is decoded **locally** and is not a server-approved level-adjusted projection. Apply now requires clicking **Apply talents**, then confirming the bot/class/era/locally selected points in a separate dialog. Pressing Enter inside the NT1 code field never sends Apply.

**Existing bot's Set Talents button now shows website presets for that bot's class** as a separate third view, with Raid/Solo descriptions and variants, plus **All / Raid / Solo** filters. **Clicking a dark website preset row loads that build straight into the NT1 Import editor**; no second Load button is needed. The code and build name are filled in locally, but **no Preview or Apply command is sent**. Target confirmation, Preview and Apply remain separate steps. The **Bot specs** button returns to the existing bridge/Playerbots specialization menu, which remains supported. The bundled Vanilla NT1 presets now total **54**: Druid (9), Hunter (8), Mage (5), Priest (7), Rogue (6), Shaman (7), Warrior (7), **Warlock (5)**. The seven previously approved Warrior builds remain unchanged (3 Solo, 4 Raid). The seven newly supplied builds are **Warlock Raid Affliction and Demonology, Warlock Solo Affliction/Demonology/Destruction, and Mage Solo Arcane and Fire**. All spend 51 points; actual server-side DBC/legal-build validation is separate. **Death Knight remains explicitly excluded**; Paladin has no approved converted website codes. These two classes still open the original Bot specs menu immediately. Other website-enabled classes, including Warrior and Warlock, retain the **Bot specs** button. These are **offline snapshots**: 40 exact records pinned to the earlier full-sync source commit, 7 Warrior links, and 7 Warlock/Mage links supplied by the project owner on 11 October 2026. See [ROADMAP.md](ROADMAP.md) for source lineage and safe update rules.

**Protected one-click Apply targeting:** The **Apply talents** button now attempts an exact-name target for the roster bot using WoW 3.3.5a's hardware-click-only `SecureActionButtonTemplate` and `/targetexact BotName`. This works only if the correct unit is targetable and the secure UI action is allowed; it is configured outside combat. If it cannot find the bot, the existing quiet guidance tells you who to target rather than repeatedly showing red errors. **The target's class/name/previously confirmed GUID are checked after the click, and a separate confirmation is still required** before any Apply command is dispatched. Opening a build or target switching by itself never applies talents. Preview remains read-only and can still ask you to select the right target. The importer detects the correct bot on target change and displays **Target verified**. Click Preview or Apply again to proceed; target switching itself **never** sends a command or automatically opens Apply. The optional **Check target** button uses the same checks. Wrong class/GUID and other invalid requests still fail safely. Apply retains its separate confirmation and server authorisation.

**Observed Wrath 3.3.5a compatibility fixes:** The Page 4 backup editor requires a **named** `UIPanelScrollFrameTemplate`; this correction is now visible in an in-game screenshot without the prior template Lua error. A separate older bot Talent-button nil lookup was also fixed and retested by the owner. The client still needs a separately authorised server-side integration/rollback exercise before actual NT1 Apply could be considered proven.

For installation, detailed tests, risks and rollback, see the [maintainer ROADMAP](ROADMAP.md). The existing public [N Addon Collection v2.0.0](https://github.com/CosmicCuddle/N-Addon-Collection/releases/tag/v2.0.0) is unchanged and still contains approved MultiBot 4.0.

## Companion Bridge Required

This repository contains the **client addon**.

For the bridge-first features you also need:

### [`mod-multibot-bridge`](https://github.com/Wishmaster117/mod-multibot-bridge)

Install the addon as:

```text
World of Warcraft/Interface/AddOns/MultiBot
```

The folder must be named `MultiBot`.

---

# What the Addon Does

MultiBot Chatless provides a UI for controlling, inspecting and managing Playerbots without flooding normal gameplay with automatic bot chat replies.

The addon still supports intentional manual Playerbots commands where they are useful, but the main direction is:

```text
UI action
  -> structured addon message
  -> mod-multibot-bridge
  -> validated server-side action/read
  -> structured result
  -> authoritative UI refresh
```

The project is currently **bridge-first / mostly chatless** rather than fully chatless. Remaining automatic chat paths are migrated only after targeted audit and runtime validation.

---

# Main Features

| Area | Current behavior |
| --- | --- |
| **Bot rosters** | My Bots / Altbots, Group, Guild, Friends and Favorites with online/offline presence and structured lifecycle handling. |
| **Bot connect / disconnect** | `ALT_ROSTER_V1`, `BOT_LIFECYCLE_V1` and `BOT_TARGET_RESOLVE_V1` provide structured discovery, target resolution and lifecycle control. Offline EveryBars stay collapsed; online EveryBars expand consistently. |
| **Bot state & strategies** | Framed bot-state reads and structured strategy mutations for migrated controls, including Warlock selectors. |
| **Inventory** | Bag-aware exact inventory for Backpack, Bag 1..4 and Keyring, including empty slots and container filtering. |
| **Item movement** | Whole-stack drag/drop between supported physical inventory slots through the Bridge. |
| **Equipment** | Structured equip and unequip workflows with authoritative refresh. |
| **Trade & item use** | Exact-item Trade, item use and item destruction through dedicated structured actions. |
| **Vendor** | Single-item sale, bulk Sell Vendor, Buyback and Open Items bridge workflows. |
| **Bank / Guild Bank** | Bridge-backed views and actions; exact physical BANK/GBANK deposits are implemented. |
| **Talents** | Premade specialization apply and editable custom talent apply with server verification. |
| **Naxxramas NT1 Talents** | Selected-bot NT1 paste, server Preview, and experimental Apply through Naxxramas Core, with target and chat-payload safety checks. |
| **Glyphs** | Glyph display and apply-related workflows integrated with the character UI. |
| **Professions** | Profession recipe browsing/crafting plus targeted item recipes. |
| **Enchanting** | Dedicated Enchanting Trade Service using the native WoW Trade workflow. |
| **Quests** | Bridge-backed quest list and structured bot quest abandon. Native quest sharing remains available. |
| **Loot** | Structured loot profiles and exact persistent always-loot item add/remove. |
| **Group tools** | Formation, Roll, RTI, Pull Control, Disperse and other migrated group controls. |
| **Naxxramas consumables** | Fork-specific dungeon consumable controls backed by `Mod-Naxxramas-Core` and `BotRaidConsumables.cpp`. |
| **Character information** | Bot skills, reputations, currencies/emblems, spellbook, stats and PvP stats. |
| **Outfits** | Outfit listing and actions through the Bridge. |
| **SelfBot** | Dedicated enable/disable, strategy and selected action support. |
| **Localization** | Eight runtime locales: `enUS`, `enGB`, `frFR`, `esES`, `deDE`, `ruRU`, `zhCN` and `koKR`. |

---

# Recent Milestone — Alt Roster & Bot Lifecycle

The roster/lifecycle work was merged and post-merge audited on **30 August 2026**.

It standardizes lifecycle behavior across:

- My Bots / Altbots;
- Group;
- Guild;
- Friends;
- Favorites.

User-facing behavior now follows the same rule everywhere:

- **offline bot** → EveryBar collapsed;
- **online bot** → EveryBar expanded;
- roster-specific UI state must not leak into another roster.

The companion Bridge also gained the server-side lifecycle authorization and hardening required for these flows.

---

# Bridge Capabilities

The addon negotiates feature capabilities with the Bridge before using newer paths.

Important current capabilities include:

```text
STATE_FRAMING_V1
STRATEGY_MUTATION_V1
OUTFIT_V1
INVENTORY_V1
INVENTORY_EXACT_V1
ITEM_MOVE_V1
ITEM_EQUIP_V1
ITEM_UNEQUIP_V1
ITEM_TRADE_V1
ITEM_USE_V1
ITEM_SELL_SINGLE_V1
VENDOR_BUYBACK_V1
INVENTORY_BULK_SELL_V1
INVENTORY_OPEN_V1
ITEM_DEPOSIT_EXACT_V1
GROUP_ROLL_V1
ENCHANT_TRADE_V1
CRAFT_RECIPE_TARGET_V1
QUEST_ABANDON_V1
LOOT_RULE_ITEM_V1
TALENT_APPLY_V1
TALENT_SPEC_APPLY_V1
SELF_BOT_V1
SELF_STRATEGY_V1
SELF_ACTION_V1
ALT_ROSTER_V1
BOT_LIFECYCLE_V1
BOT_TARGET_RESOLVE_V1
```

The exact protocol is an implementation detail of the addon and Bridge. The normal user experience should remain UI-driven.

---

# Compatibility & Legacy Chat

The addon deliberately keeps some manual Playerbots commands for diagnostics and explicit gameplay use.

Automatic compatibility fallback is disabled by default:

```lua
MultiBot.allowLegacyChatFallback = false
```

When a migrated Bridge feature is available, the addon should prefer the structured path and wait for authoritative server state instead of pretending an action succeeded locally.

---

# Installation

1. Install and configure AzerothCore with `mod-playerbots`.
2. Install [`mod-multibot-bridge`](https://github.com/Wishmaster117/mod-multibot-bridge) on the server and rebuild AzerothCore.

### Naxxramas consumables requirement

To use the custom **Consumables** controls in this fork, the server must also include [`Mod-Naxxramas-Core`](https://github.com/CosmicCuddle/Mod-Naxxramas-Core) with [`src/Systems/BotRaidConsumables.cpp`](https://github.com/CosmicCuddle/Mod-Naxxramas-Core/blob/main/src/Systems/BotRaidConsumables.cpp) compiled and loaded.

This requirement applies specifically to the Naxxramas consumables controls; the normal MultiBot Chatless features continue to depend on the upstream bridge as documented above.

3. Copy or clone this repository as:

```text
World of Warcraft/Interface/AddOns/MultiBot
```

4. Start the server and log into the WoW 3.3.5a client.
5. Confirm the addon and Bridge handshake successfully.

---

# Usage

Open MultiBot with any of these slash commands:

```text
/multibot
/mbot
/mb
```

You can also open the addon from its minimap button.

When the Bridge is available, supported UI actions automatically use the structured bridge-first path; you do not need to type protocol commands manually.

---

# Current Status

The major read paths and a large part of the action surface are now bridge-first and runtime validated.

The project is **not declared fully chatless yet**. Remaining `SendChatMessage` paths are handled family by family so that useful manual commands are not removed accidentally and legacy compatibility is not broken without testing.

The next normal roadmap item is a targeted audit of collective:

```text
follow
attack
stay
```

No generic arbitrary Playerbots command executor is planned.

Detailed development history, audits, deferred work and technical residuals are tracked in the project documentation.

---

# Documentation

- [`ROADMAP.md`](ROADMAP.md) — current Naxxramas fork development handover: target feature, source paths, prerequisites, backups, exact next task and testing status.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — retained bridge-migration history, audits and upstream backlog.
- [`docs/DEBUG_RUNBOOK.md`](docs/DEBUG_RUNBOOK.md) — in-game debug commands, observability guidance and bug-report procedure.

---

# Deferred / Lower-Priority Work

The active roadmap currently keeps these items outside the next normal feature batch:

- exact BANK withdrawal (P3B);
- exact Guild Bank withdrawal (P3C);
- dedicated localized `SOURCE_STALE` UI text;
- moving/re-equipping the equipped bag objects themselves (`BAG_MOVE`);
- `SELL_GREY` follow-up;
- final real Firestone/Spellstone `TEMP_ENCHANTMENT_SLOT` revalidation;
- remaining Warlock LuaLint warnings;
- selected lifecycle/idempotence hardening for older pending-command flows.

---

# Credits

- **Original MultiBot author:** Nico Löbbert
- **MultiBot Chatless maintainer:** Wishmaster117 / TheWarlock
- **Naxxramas fork additions:** CosmicCuddle

MultiBot Chatless builds on the AzerothCore and `mod-playerbots` ecosystem.

Special thanks to **Macx-Lio** for the original MultiBot Module that this project builds upon.

The project also retains attribution for the external **Jellypowered** bridge work that was audited and selectively adapted during the chatless migration. Details and commit references are preserved in the project roadmap.

---

# Troubleshooting

### The addon does not load

Confirm the folder is named exactly:

```text
MultiBot
```

and is located under:

```text
World of Warcraft/Interface/AddOns/
```

### Bridge features are unavailable

Confirm `mod-multibot-bridge` is installed, configured, compiled and loaded by the same AzerothCore server used by the client.

### I still see some Playerbots chat

That does not automatically mean the Bridge is broken. Manual commands and a small number of intentionally retained or not-yet-migrated paths still exist while the project remains **mostly chatless**.
