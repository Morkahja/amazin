Gotcha—here’s a complete README you can drop in.


---

Amazin (WoW 1.12 / Turtle WoW)

Amazin fires a built-in emote when you press your Stealth button (by watching its action-bar slot). It’s Lua 5.0–safe, lightweight, and includes cooldown, chance control, a debug “watch” mode, and a rested XP reporter.

Works on German clients (uses English DoEmote tokens internally).


---

What it does

Stealth press → emote: When you press the configured action slot (your Stealth button), Amazin plays a random stealth-flavored emote (e.g., /rofl, /giggle, /stare, /grin, /smirk).

Cooldown: Prevents spam if you tap the button repeatedly.

Chance %: Optional probability so it doesn’t fire every time.

Rested XP: /amazin rexp prints rested XP in bubbles (max 30 = 1.5 levels) and raw XP.

Watch mode: Temporarily prints which slot you pressed to help you find the Stealth slot ID.


> Design choice: No aura/icon detection (Classic 1.12 icon checks are unreliable). Trigger is only the watched slot press.




---

Files & Install

Interface/
└─ AddOns/
   └─ Amazin/
      ├─ Amazin.toc
      └─ Amazin.lua

1. Copy the folder to Interface\AddOns\.


2. Enable Amazin on the character select AddOns screen.



Amazin.toc

## Interface: 11200
## Title: Amazin
## Version: 1.2.4
## Notes: Stealth emotes on watched slot + rested XP reporter. Commands: /amazin slot, watch, chance, scd, rexp, info, reset, save
## SavedVariables: AmazinDB

Amazin.lua


---

Quick setup (first time)

1. Put Stealth on an action-bar slot (e.g., slot 3).


2. /amazin watch → press your Stealth button → note the printed slot number.


3. /amazin slot <n> (e.g., /amazin slot 3)


4. /amazin watch again to turn watch mode OFF.



Done. Each time you press that slot, Amazin may play an emote (respecting cooldown & chance).


---

Commands (all start with /amazin)

Command	What it does	Example

slot <n>	Set the watched action slot (saved).	/amazin slot 3
watch	Toggle debug: prints pressed slot N on any action.	/amazin watch
chance <0-100>	Set % chance to emote on press (default 100).	/amazin chance 60
scd <seconds>	Set stealth emote cooldown (default 6, max 60).	/amazin scd 10
rexp	Print rested XP (bubbles + raw XP).	/amazin rexp
info	Show current settings.	/amazin info
reset	Clear saved slot.	/amazin reset
save	Manually save settings.	/amazin save



---

Emote pool (edit if you want)

Amazin uses built-in emotes (no custom text). Default pool in Amazin.lua:

ROFL, LAUGH, GIGGLE, STARE, GRIN, SMIRK, CHUCKLE, WINK, SHUSH, SNICKER

> Token → slash mapping examples:
LAUGH = /lol, ROFL = /rofl, GIGGLE = /giggle, STARE = /stare, GRIN = /grin, etc.
On German clients, DoEmote("LAUGH") still works (tokens stay English).



To customize: open Amazin.lua, edit EMOTE_TOKENS_STEALTH.


---

How it works (technical)

Hooks UseAction(slot, ...) (Classic 1.12 API).

If slot == WATCH_SLOT, it checks cooldown & chance, then calls DoEmote(token).

Uses account-wide SavedVariables AmazinDB:

slot (number) — watched action slot

stealth_chance (0–100) — % chance to emote

stealth_cd (seconds) — stealth emote cooldown



No frames/timers running constantly; it’s basically idle until you press an action.


---

Limitations / Intentional behavior

Only slot press trigger. No buff/icon scan (historically unreliable in 1.12).

SAY/YELL blocked: Classic/Turtle block addon-driven /say and /yell in open world. EMOTE is allowed, hence Amazin uses DoEmote.

Bar changes: If you move Stealth to another slot or switch bar pages/layouts, update /amazin slot <n> accordingly.



---

Troubleshooting

“Nothing happens.”

/amazin info → check slot, cooldown, chance.

Ensure your Stealth button is really in that slot. Use /amazin watch to confirm.

If chance is low or cooldown is long, it might just be waiting.


Slot number confusion.

Turn on /amazin watch, press the button you expect to be Stealth, read the printed pressed slot N.


Weird chat errors (Lua).

Make sure the file is saved as ANSI or UTF-8 (no BOM).

Amazin avoids string.match and :format (Lua 5.0 quirks), so you shouldn’t see those errors on the shipped version.


Conflicts.

If another addon replaces UseAction, load order can matter. Amazin wraps the original; most setups are fine.




---

Performance

Negligible. Only hooks UseAction, does a few integer checks and a random pick. No per-frame work.


---

Compatibility

Client: 1.12 (Vanilla/Turtle).

Locale: All. Tokens are English internally, which work on DE/other clients.

Class: Built for Rogue Stealth use, but technically watches any slot you point it at.



---

Changelog (highlights)

1.2.4 — Added /amazin rexp rested XP reporter; README polish.

1.2.3 — Removed string.format usage to avoid encoding oddities; pure concatenation.

1.2.2 — Removed string.match; Lua 5.0-safe command parser; balanced ends.

1.2.1 — Fixed info display to use string.format (later replaced).

1.2.0 — Simplified to Stealth-only via watched slot.

1.1.x — Earlier versions with aura/icon detection and general emote pool (dropped).

1.0.0 — Initial slot-based emote idea.



---

License

MIT. Use it, fork it, ship it. Attribution appreciated.
