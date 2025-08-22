-- Amazin v1.1.0 (Vanilla/Turtle 1.12)
-- Account-wide SavedVariables: AmazinDB
-- Plays a random built-in emote when:
--   1) You press a configured action slot (cooldown-limited)
--   2) You ENTER Stealth as a Rogue (separate chance + cooldown)
-- Slash commands: /amazin (see help at bottom)

-------------------------------------------------
-- Emote pools
-------------------------------------------------
local EMOTE_TOKENS = {
  "CHARGE","ATTACKTARGET","ROAR","CHEER","FLEX","THREATEN","TAUNT","POINT",
  "GLARE","GROWL","TRAIN","SALUTE","LAUGH","CHUCKLE","SMIRK","READY","FLIRT",
  "KISS","DANCE","BATTLECRY",
}

-- Stealth-flavored emotes (classic client uses English tokens for DoEmote)
local EMOTE_TOKENS_STEALTH = {
  "ROFL",     -- /rofl
  "LAUGH",    -- /lol
  "GIGGLE",   -- /giggle
  "STARE",    -- /stare
  "GRIN",     -- /grin
  "SMIRK",    -- /smirk
  "CHUCKLE",  -- /chuckle
  "WINK",     -- /wink
  "SHUSH",    -- /shush
  "SNICKER",  -- /snicker
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOT = nil
local WATCH_MODE = false
local LAST_EMOTE_TIME = 0
local EMOTE_COOLDOWN = 21  -- seconds

-- Stealth settings (saved)
local stealth_enabled = true          -- enable/disable stealth trigger
local stealth_chance  = 100           -- % chance to fire on entering Stealth
local LAST_STEALTH_EMOTE_TIME = 0
local STEALTH_COOLDOWN = 6            -- seconds between stealth emotes
local wasStealthed = false            -- track state transitions only

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffAmazin:|r " .. text)
  end
end

local function ensureDB()
  if type(AmazinDB) ~= "table" then
    AmazinDB = {}
  end
  return AmazinDB
end

-- One-time lazy load
local _amz_loaded_once = false
local function ensureLoaded()
  if not _amz_loaded_once then
    local db = ensureDB()
    if WATCH_SLOT == nil then WATCH_SLOT = db.slot or nil end
    if db.stealth_enabled == nil then db.stealth_enabled = true end
    if db.stealth_chance  == nil then db.stealth_chance  = 100 end
    if db.stealth_cd      == nil then db.stealth_cd      = STEALTH_COOLDOWN end
    stealth_enabled = db.stealth_enabled
    stealth_chance  = db.stealth_chance
    STEALTH_COOLDOWN = db.stealth_cd
    _amz_loaded_once = true
  end
end

local function tlen(t)
  if t and table.getn then return table.getn(t) end
  return 0
end

local function pick(t)
  local n = tlen(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function performBuiltInEmote(token)
  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("macht ein Kampfgebrüll!", "EMOTE") -- harmless fallback
  end
end

local function doEmoteNow(pool)
  local now = GetTime()
  if now - LAST_EMOTE_TIME < EMOTE_COOLDOWN then return end
  LAST_EMOTE_TIME = now
  local e = pick(pool or EMOTE_TOKENS)
  if e then performBuiltInEmote(e) end
end

local function doStealthEmoteNow()
  local now = GetTime()
  if now - LAST_STEALTH_EMOTE_TIME < STEALTH_COOLDOWN then return end
  LAST_STEALTH_EMOTE_TIME = now
  local e = pick(EMOTE_TOKENS_STEALTH)
  if e then performBuiltInEmote(e) end
end

-------------------------------------------------
-- Stealth detection (Classic 1.12)
-- Locale-agnostic by icon path.
-------------------------------------------------
local STEALTH_ICON = "Interface\\Icons\\Ability_Stealth"

local function playerIsStealthed()
  for i = 1, 40 do
    local tex = UnitBuff("player", i)
    if not tex then break end
    if tex == STEALTH_ICON then
      return true
    end
  end
  return false
end

-------------------------------------------------
-- Hook UseAction (1.12)
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()
  if WATCH_MODE then
    chat("pressed slot " .. tostring(slot))
  end
  if WATCH_SLOT and slot == WATCH_SLOT then
    doEmoteNow(EMOTE_TOKENS)
  end
  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Commands (/amazin)
-------------------------------------------------
SLASH_AMAZIN1 = "/amazin"
SlashCmdList["AMAZIN"] = function(raw)
  ensureLoaded()
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local cmd, rest = string.match(s, "^(%S+)%s*(.-)$")

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then
      WATCH_SLOT = n
      local db = ensureDB()
      db.slot = n
      chat("watching action slot " .. n .. " (saved).")
    else
      chat("usage: /amazin slot <number>")
    end

  elseif cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    chat("watch mode " .. (WATCH_MODE and "ON" or "OFF"))

  elseif cmd == "emote" then
    doEmoteNow(EMOTE_TOKENS)

  elseif cmd == "info" then
    chat("watching slot: " .. (WATCH_SLOT and tostring(WATCH_SLOT) or "none"))
    chat("cooldown: " .. EMOTE_COOLDOWN .. "s")
    chat("emote pool: " .. tlen(EMOTE_TOKENS) .. " tokens")
    chat(("stealth: %s | chance: %d%% | stealth_cd: %ds | pool: %d")
      :format(stealth_enabled and "ON" or "OFF", stealth_chance, STEALTH_COOLDOWN, tlen(EMOTE_TOKENS_STEALTH)))

  elseif cmd == "timer" then
    local remain = EMOTE_COOLDOWN - (GetTime() - LAST_EMOTE_TIME)
    if remain < 0 then remain = 0 end
    chat("time left: " .. string.format("%.1f", remain) .. "s")

  elseif cmd == "reset" then
    WATCH_SLOT = nil
    local db = ensureDB()
    db.slot = nil
    chat("cleared saved slot.")

  elseif cmd == "save" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.stealth_enabled = stealth_enabled
    db.stealth_chance  = stealth_chance
    db.stealth_cd      = STEALTH_COOLDOWN
    chat("saved now.")

  elseif cmd == "debug" then
    local t = type(AmazinDB)
    local v = (t == "table") and tostring(AmazinDB.slot) or "n/a"
    chat("type(AmazinDB)=" .. t .. " | SV slot=" .. v .. " | WATCH_SLOT=" .. tostring(WATCH_SLOT))

  elseif cmd == "stealth" then
    local arg = string.lower(rest or "")
    if arg == "on" or arg == "off" then
      stealth_enabled = (arg == "on")
      ensureDB().stealth_enabled = stealth_enabled
      chat("stealth trigger " .. (stealth_enabled and "ON" or "OFF"))
    else
      chat("usage: /amazin stealth on|off")
    end

  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 100 then
      stealth_chance = math.floor(n + 0.5)
      ensureDB().stealth_chance = stealth_chance
      chat("stealth emote chance set to " .. stealth_chance .. "%")
    else
      chat("usage: /amazin chance <0-100>")
    end

  elseif cmd == "scd" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 120 then
      STEALTH_COOLDOWN = math.floor(n + 0.5)
      ensureDB().stealth_cd = STEALTH_COOLDOWN
      chat("stealth emote cooldown set to " .. STEALTH_COOLDOWN .. "s")
    else
      chat("usage: /amazin scd <0-120>")
    end

  else
    chat("/amazin slot <n> | watch | emote | info | timer | reset | save | debug")
    chat("/amazin stealth on|off | chance <0-100> | scd <seconds>")
  end
end

-------------------------------------------------
-- Init / Save / RNG + Stealth watcher
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent(
