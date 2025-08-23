-- Amazin v1.2.4 (Vanilla/Turtle 1.12, Lua 5.0-safe)
-- SavedVariables: AmazinDB
-- Plays a random stealth-style emote when you press your watched Stealth action bar slot.

-------------------------------------------------
-- Stealth emote pool
-------------------------------------------------
local EMOTE_TOKENS_STEALTH = {
  "ROFL","LAUGH","GIGGLE","STARE","GRIN","SMIRK","CHUCKLE","WINK","SHUSH","SNICKER",
}

-------------------------------------------------
-- State
-------------------------------------------------
local WATCH_SLOT = nil
local WATCH_MODE = false
local LAST_STEALTH_EMOTE_TIME = 0
local STEALTH_COOLDOWN = 6   -- seconds
local stealth_chance = 100   -- % chance to fire

-------------------------------------------------
-- Helpers (Lua 5.0)
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

local _amz_loaded_once = false
local function ensureLoaded()
  if not _amz_loaded_once then
    local db = ensureDB()
    WATCH_SLOT = db.slot or WATCH_SLOT
    if db.stealth_cd then STEALTH_COOLDOWN = db.stealth_cd end
    if db.stealth_chance then stealth_chance = db.stealth_chance end
    _amz_loaded_once = true
  end
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function performBuiltInEmote(token)
  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("kichert leise...", "EMOTE") -- fallback
  end
end

local function doStealthEmoteNow()
  local now = GetTime()
  if now - LAST_STEALTH_EMOTE_TIME < STEALTH_COOLDOWN then return end
  LAST_STEALTH_EMOTE_TIME = now
  if math.random(1, 100) <= stealth_chance then
    local e = pick(EMOTE_TOKENS_STEALTH)
    if e then performBuiltInEmote(e) end
  end
end

-- Lua 5.0-safe command splitter (no string.match)
local function split_cmd(raw)
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then cmd = "" rest = "" end
  return cmd, rest
end

-- Rested XP reporter
local function reportRestedXP()
  local r = GetXPExhaustion()
  if not r then
    chat("No rest.")
    return
  end
  local m = UnitXPMax("player")
  if not m or m == 0 then
    chat("No XP data.")
    return
  end
  local bubbles = math.floor((r * 20) / m + 0.5)
  if bubbles > 30 then bubbles = 30 end
  chat("Rest: " .. tostring(bubbles) .. " bubbles (" .. tostring(r) .. " XP)")
end

-------------------------------------------------
-- Hook UseAction
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()
  if WATCH_MODE then
    chat("pressed slot " .. tostring(slot))
  end
  if WATCH_SLOT and slot == WATCH_SLOT then
    doStealthEmoteNow()
  end
  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Commands (/amazin)
-------------------------------------------------
SLASH_AMAZIN1 = "/amazin"
SlashCmdList["AMAZIN"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then
      WATCH_SLOT = n
      ensureDB().slot = n
      chat("watching slot " .. n .. " (saved).")
    else
      chat("usage: /amazin slot <number>")
    end

  elseif cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    chat("watch mode " .. (WATCH_MODE and "ON" or "OFF"))

  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 100 then
      stealth_chance = n
      ensureDB().stealth_chance = n
      chat("stealth emote chance set to " .. n .. "%")
    else
      chat("usage: /amazin chance <0-100>")
    end

  elseif cmd == "scd" then
    local n = tonumber(rest)
    if n and n >= 0 and n <= 60 then
      STEALTH_COOLDOWN = n
      ensureDB().stealth_cd = n
      chat("stealth cooldown set to " .. n .. "s")
    else
      chat("usage: /amazin scd <0-60>")
    end

  elseif cmd == "rexp" then
    reportRestedXP()

  elseif cmd == "info" then
    chat("watching slot: " .. (WATCH_SLOT and tostring(WATCH_SLOT) or "none"))
    chat("stealth chance: " .. tostring(stealth_chance) ..
        "% | cooldown: " .. tostring(STEALTH_COOLDOWN) ..
        "s | pool: " .. tostring(table.getn(EMOTE_TOKENS_STEALTH)) .. " emotes")

  elseif cmd == "reset" then
    WATCH_SLOT = nil
    ensureDB().slot = nil
    chat("cleared saved slot.")

  elseif cmd == "save" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.stealth_chance = stealth_chance
    db.stealth_cd = STEALTH_COOLDOWN
    chat("saved now.")

  else
    chat("/amazin slot <n> | watch | chance <0-100> | scd <seconds> | rexp | info | reset | save")
  end
end

-------------------------------------------------
-- Init / RNG
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000)); math.random()
  elseif event == "PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slot = WATCH_SLOT
    db.stealth_chance = stealth_chance
    db.stealth_cd = STEALTH_COOLDOWN
  end
end)
