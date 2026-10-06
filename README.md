# Tukui for WoW Forever

**Unofficial fork** of [Tukui](https://github.com/tukui-org/Tukui) (based on **v20.463**) adapted for the
**WoW Forever** client (`wow_classic_beta`, client **1.60.1**, game type *Camelot*, interface **16001**).

WoW Forever runs Classic content on the modern game engine, with all of its new rules: secret values,
stricter taint checks, Blizzard's aura containers, a new loot history API and more. Stock Tukui doesn't
load there (the client only accepts `*-Camelot.toc`) and throws a lot of errors once it does. This fork
fixes that.


> This is not an official Tukui release and is not supported by the Tukui team.
> Please don't report problems of this fork to the original authors — open an issue here instead.

## What's changed

- Loads on WoW Forever (`Tukui-Camelot.toc`, Camelot is treated as the retail code path).
- Unit frames, tags, tooltips and nameplates handle secret values instead of erroring.
- Buffs/debuffs (unit frames, raid frames, top-right player auras) use Blizzard's aura containers.
- Many fixes for "AddOn blocked" / taint problems (action bars, spellbook, bags, bank, world map, chat).
- Chat: copy window with scrolling, whisper to players with Cyrillic surnames, secret messages.
- Bags: Tukui-style bag bar, working sort button. Loot: who rolled what, roll winner display.
- Settings load correctly on the first login, durability and loot texts localized.

Full list: see the commits on the `forever` branch and the [releases](../../releases).

Known limitations (Blizzard restrictions on this client): short chat channel names and clickable URLs in
chat are disabled, the world map is Blizzard's default one (Tukui only adds coordinates).

## Install

1. Download `Tukui-<version>.zip` from [Releases](../../releases).
2. Delete the old `Interface\AddOns\Tukui` folder.
3. Extract the zip into `World of Warcraft\_classic_beta_\Interface\AddOns\`.
4. Restart the game completely (not just `/reload`).

## Issues are welcome

Found a bug or a Lua error? Please [open an issue](../../issues/new). Helpful details:

- client build (e.g. `1.60.1.70170`) and Tukui version from the addon list;
- the full Lua error text (with *Stack* and *Locals*) — enable errors with `/console scriptErrors 1`;
- what you did right before it, and a screenshot if it's visual;
- for "AddOn blocked" messages: `/console taintLog 2`, reproduce, exit the game and attach the part of
  `Logs\taint.log` around the blocked action;
- other addons you use (Questie, DBM, ...).

Feature requests and ideas are welcome too.

## Want to help? Welcome!

Contributions are very welcome — Lua fixes, testing on other classes, translations, ideas.

1. Fork this repository and branch off `forever`.
2. Keep changes focused; describe in the PR what was broken and how you tested it in game.
3. A few rules that matter on this client:
   - don't `hooksecurefunc` Blizzard **object methods** that Blizzard calls from secure code
     (they break: "attempt to call a nil value") — use events, `HookScript` or polling;
   - don't write addon values into Blizzard globals, mixins or frame fields that Blizzard reads (taint);
   - never compare, do math on, measure or index tables with secret values (`issecretvalue`).

Blizzard UI source for this client: [Gethe/wow-ui-source, branch `forever`](https://github.com/Gethe/wow-ui-source/tree/forever).

## Credits and license

Tukui is made by Tukz and the Tukui team — [tukui.org](https://www.tukui.org). All credit for the UI goes
to them. oUF and other bundled libraries belong to their authors (see `Tukui/Licenses`).
This fork only contains compatibility changes for WoW Forever. The original Tukui license applies.
