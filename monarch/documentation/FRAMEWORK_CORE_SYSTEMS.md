# Monarch Framework - Core Systems


## Player Meta Functions

Functions attached to the Player entity that can be called with `ply:FunctionName()`

### Core Player Functions

#### ply:Notify(message, kind, length)
Display a notification to the player.
- **Parameters:**
  - `message` (string): Message to display
  - `kind` (number): Optional. 0=generic, 1=error, 2=undo, 3=hint (default: 0)
  - `length` (number): Optional. Duration in seconds (default: 3)
- **Returns:** None
- **Realm:** Shared (works on both client and server)
- **Example:**
```lua
ply:Notify("Welcome to the server!", 0, 5)
ply:Notify("Error: Invalid input", 1, 3)
```

---


## Money System

### ply:GetMoney()
Get the player's current money amount.
- **Returns:** number - Current money amount
- **Realm:** Shared
- **Example:**
```lua
local money = ply:GetMoney()
print("Player has $" .. money)
```

### ply:AddMoney(amount, reason)
Add money to the player's account.
- **Parameters:**
  - `amount` (number): Amount to add (must be positive)
  - `reason` (string): Optional. Reason for the money gain (shown in notification)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:AddMoney(500, "Quest reward")
ply:AddMoney(1000, "Salary payment")
```

### ply:TakeMoney(amount, reason)
Remove money from the player's account.
- **Parameters:**
  - `amount` (number): Amount to remove (must be positive)
  - `reason` (string): Optional. Reason for the money loss
- **Returns:** boolean - True if successful (false if insufficient funds)
- **Realm:** Server only
- **Example:**
```lua
if ply:TakeMoney(250, "Shop purchase") then
    -- Purchase successful
else
    ply:Notify("You don't have enough money!", 1)
end
```

### ply:SetMoney(amount)
Set the player's money to a specific amount.
- **Parameters:**
  - `amount` (number): New money amount (must be non-negative)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:SetMoney(5000)
```

### ply:CanAfford(amount)
Check if the player can afford a specific amount.
- **Parameters:**
  - `amount` (number): Amount to check
- **Returns:** boolean - True if player has enough money
- **Realm:** Shared
- **Example:**
```lua
if ply:CanAfford(1000) then
    ply:TakeMoney(1000, "Item purchase")
    -- Give item
else
    ply:Notify("Insufficient funds!", 1)
end
```

---


## XP System ---> DEPRECATED. No longer used in the base framework.

### ply:GetXP()
Get the player's current XP amount.
- **Returns:** number - Current XP amount
- **Realm:** Shared
- **Example:**
```lua
local xp = ply:GetXP()
```

### ply:AddXP(amount, reason)
Add XP to the player.
- **Parameters:**
  - `amount` (number): Amount of XP to add
  - `reason` (string): Optional. Reason for XP gain
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:AddXP(100, "Completed quest")
```

### ply:TakeXP(amount, reason)
Remove XP from the player.
- **Parameters:**
  - `amount` (number): Amount of XP to remove
  - `reason` (string): Optional. Reason for XP loss
- **Returns:** boolean - True if successful (false if insufficient XP)
- **Realm:** Server only
- **Example:**
```lua
ply:TakeXP(50, "Death penalty")
```

### ply:SetXP(amount)
Set the player's XP to a specific amount.
- **Parameters:**
  - `amount` (number): New XP amount
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:SetXP(1000)
```

---


## Character System

### ply:GetCharID()
Get the player's active character ID.
- **Returns:** number/nil - Character ID or nil if no active character
- **Realm:** Shared
- **Example:**
```lua
local charID = ply:GetCharID()
if charID then
    print("Character ID: " .. charID)
end
```

### ply:GetCharData()
Get the player's complete character data table.
- **Returns:** table - Character data table (empty if no active character)
- **Realm:** Shared
- **Example:**
```lua
local charData = ply:GetCharData()
print("Name:", charData.name)
print("Model:", charData.model)
```

### ply:HasActiveChar()
Check if the player has an active character.
- **Returns:** boolean - True if player has an active character
- **Realm:** Shared
- **Example:**
```lua
if not ply:HasActiveChar() then
    ply:Notify("You must create a character first!")
    return
end
```

### ply:GetCharModel()
Get the player's character model path.
- **Returns:** string - Model path
- **Realm:** Shared
- **Example:**
```lua
local model = ply:GetCharModel()
```

### ply:GetCharSkin()
Get the player's character skin number.
- **Returns:** number - Skin number (default: 0)
- **Realm:** Shared
- **Example:**
```lua
local skin = ply:GetCharSkin()
```

### ply:IsFemaleChar()
Check if the player's character is female.
- **Returns:** boolean - True if character is female
- **Realm:** Shared
- **Example:**
```lua
if ply:IsFemaleChar() then
    -- Female-specific logic
end
```

### Physical Description Functions

#### ply:GetHeight()
Get character height description.
- **Returns:** string - Height description
- **Realm:** Shared

#### ply:GetWeight()
Get character weight description.
- **Returns:** string - Weight description
- **Realm:** Shared

#### ply:GetHairColor()
Get character hair color.
- **Returns:** string - Hair color
- **Realm:** Shared

#### ply:GetEyeColor()
Get character eye color.
- **Returns:** string - Eye color
- **Realm:** Shared

#### ply:GetAge()
Get character age.
- **Returns:** number - Age (default: 0)
- **Realm:** Shared

#### ply:GetPhysicalDescription()
Get all physical description data at once.
- **Returns:** table - Table containing height, weight, hair, eyes, age
- **Realm:** Shared
- **Example:**
```lua
local desc = ply:GetPhysicalDescription()
print("Age:", desc.age)
print("Height:", desc.height)
print("Hair:", desc.hair)
```

---


## Name System

### ply:GetRPName()
Get the player's current roleplay name (includes temporary names).
- **Returns:** string - Current RP name
- **Realm:** Shared
- **Example:**
```lua
local name = ply:GetRPName()
```

### ply:GetBaseRPName()
Get the player's base RP name (ignores temporary names).
- **Returns:** string - Base RP name
- **Realm:** Shared
- **Example:**
```lua
local baseName = ply:GetBaseRPName()
```

### ply:GetCharName()
Get the character's saved database name.
- **Returns:** string - Character name from database
- **Realm:** Shared
- **Example:**
```lua
local charName = ply:GetCharName()
```

### ply:SetRPName(name, saveToDb)
Set the player's RP name.
- **Parameters:**
  - `name` (string): New RP name
  - `saveToDb` (boolean): Optional. If true, saves permanently to database (default: false)
- **Returns:** None
- **Realm:** Shared (but database save only works server-side)
- **Example:**
```lua
-- Temporary name
ply:SetRPName("John Smith")

-- Permanent name (saved to database)
ply:SetRPName("John Smith", true)
```

### ply:SetTempRPName(tempName, prefix, suffix)
Set a temporary RP name with optional prefix/suffix.
- **Parameters:**
  - `tempName` (string): Temporary name
  - `prefix` (string): Optional. Prefix to add before name
  - `suffix` (string): Optional. Suffix to add after name
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:SetTempRPName("Smith", "Dr.", "MD")
-- Results in: "Dr. Smith MD"

ply:SetTempRPName("John Doe")
-- Results in: "John Doe"
```

### ply:RestoreRPName()
Restore the player's original RP name (remove temporary name).
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:RestoreRPName()
```

### ply:HasTempRPName()
Check if the player has a temporary RP name active.
- **Returns:** boolean - True if temporary name is set
- **Realm:** Shared
- **Example:**
```lua
if ply:HasTempRPName() then
    print("Player has a temporary name")
end
```

### ply:RequestTempRPName(newName)
Request a temporary RP name change (realm-safe).
- **Parameters:**
  - `newName` (string): New temporary name
- **Returns:** boolean - True if request was sent/processed
- **Realm:** Shared
- **Example:**
```lua
ply:RequestTempRPName("Disguised Person")
```

---


## Time System

The time system manages in-game time cycles, allowing for dynamic day/night cycles.

### Monarch.Time.GetFormatted(use24Hour)
Get the current in-game time as a formatted string.
- **Parameters:**
  - `use24Hour` (boolean): Optional. Use 24-hour format (default: false = 12-hour with AM/PM)
- **Returns:** string - Formatted time string
- **Realm:** Shared
- **Example:**
```lua
local time12 = Monarch.Time.GetFormatted()
-- Returns: "03:45 PM"

local time24 = Monarch.Time.GetFormatted(true)
-- Returns: "15:45"
```

### Monarch.Time.GetHour()
Get the current in-game hour (0-23).
- **Returns:** number - Current hour
- **Realm:** Shared
- **Example:**
```lua
local hour = Monarch.Time.GetHour()
print("Current hour:", hour) -- e.g., 15
```

### Monarch.Time.GetMinute()
Get the current in-game minute (0-59).
- **Returns:** number - Current minute
- **Realm:** Shared
- **Example:**
```lua
local minute = Monarch.Time.GetMinute()
print("Current minute:", minute) -- e.g., 45
```

### Monarch.Time.GetTime()
Get both hour and minute as a table.
- **Returns:** table - Table with 'hour' and 'minute' keys
- **Realm:** Shared
- **Example:**
```lua
local time = Monarch.Time.GetTime()
print(string.format("Time: %02d:%02d", time.hour, time.minute))
```

### Monarch.Time.IsDaytime()
Check if it's currently daytime (6 AM - 6 PM).
- **Returns:** boolean - True if daytime
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Time.IsDaytime() then
    print("The sun is out!")
else
    print("It's nighttime")
end
```

### Monarch.Time.IsNighttime()
Check if it's currently nighttime (6 PM - 6 AM).
- **Returns:** boolean - True if nighttime
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Time.IsNighttime() then
    -- Enable night vision
    -- Spawn nocturnal creatures
end
```

### Monarch.Time.GetPeriod()
Get a descriptive time period.
- **Returns:** string - Time period ("Morning", "Afternoon", "Evening", or "Night")
- **Realm:** Shared
- **Example:**
```lua
local period = Monarch.Time.GetPeriod()
ply:Notify("Good " .. period .. "!", 0)
-- Returns: "Good Morning!", "Good Afternoon!", etc.
```

### Monarch.Time.SetTime(hour, minute)
*Server only* - Set the current in-game time.
- **Parameters:**
  - `hour` (number): Hour to set (0-23)
  - `minute` (number): Optional. Minute to set (0-59, default: 0)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
-- Set to 3:45 PM
Monarch.Time.SetTime(15, 45)

-- Set to midnight
Monarch.Time.SetTime(0, 0)

-- Set to noon
Monarch.Time.SetTime(12, 0)
```

### Monarch.Time.SetCycleDuration(seconds)
*Server only* - Set the duration of a full day/night cycle.
- **Parameters:**
  - `seconds` (number): Duration in real-world seconds
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
-- 30 minute cycle
Monarch.Time.SetCycleDuration(1800)

-- 1 hour cycle
Monarch.Time.SetCycleDuration(3600)

-- 10 minute cycle (fast)
Monarch.Time.SetCycleDuration(600)
```

**Default:** 2400 seconds (40 minutes)

### Monarch.Time.RealToGameTime(realSeconds)
Convert real-world seconds to in-game time.
- **Parameters:**
  - `realSeconds` (number): Real-world seconds
- **Returns:** number - Equivalent in-game seconds
- **Realm:** Shared
- **Example:**
```lua
-- How long is 5 real seconds in game time?
local gameSeconds = Monarch.Time.RealToGameTime(5)
print("5 real seconds = " .. gameSeconds .. " game seconds")
```

### Monarch.Time.GameToRealTime(gameSeconds)
Convert in-game seconds to real-world seconds.
- **Parameters:**
  - `gameSeconds` (number): In-game seconds
- **Returns:** number - Equivalent real-world seconds
- **Realm:** Shared
- **Example:**
```lua
-- How long is 1 game hour in real time?
local realSeconds = Monarch.Time.GameToRealTime(3600)
print("1 game hour = " .. realSeconds .. " real seconds")
```

### Monarch.Time.Get() (Legacy)
Backward compatibility function for getting formatted time.
- **Returns:** string - Formatted 12-hour time with AM/PM
- **Realm:** Shared
- **Example:**
```lua
local time = Monarch.Time.Get()
-- Returns: "03:45 PM"
```

### Time System Examples

#### Dynamic Lighting Based on Time
```lua
if CLIENT then
    hook.Add("RenderScreenspaceEffects", "DynamicDayNight", function()
        local hour = Monarch.Time.GetHour()
        local darkness = 0
        
        -- Calculate darkness level
        if hour >= 0 and hour < 6 then
            darkness = 0.7 -- Very dark at night
        elseif hour >= 6 and hour < 8 then
            darkness = 0.3 -- Dawn
        elseif hour >= 8 and hour < 18 then
            darkness = 0 -- Daytime
        elseif hour >= 18 and hour < 20 then
            darkness = 0.3 -- Dusk
        else
            darkness = 0.7 -- Night
        end
        
        -- Apply color modify
        local tab = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = -darkness,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1 - (darkness * 0.5),
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }
        DrawColorModify(tab)
    end)
end
```

#### Time-Based Shop Hours
```lua
function CanAccessShop(ply)
    local hour = Monarch.Time.GetHour()
    local period = Monarch.Time.GetPeriod()
    
    -- Shop open 8 AM - 8 PM
    if hour >= 8 and hour < 20 then
        return true
    else
        ply:Notify("The shop is closed. Open hours: 8:00 AM - 8:00 PM", 1)
        ply:Notify("Current time: " .. Monarch.Time.GetFormatted(), 0)
        return false
    end
end
```

#### Time-Based Salary System
```lua
-- Give salary every in-game hour
local lastSalaryHour = -1

hook.Add("Think", "HourlySalary", function()
    local currentHour = Monarch.Time.GetHour()
    
    if currentHour ~= lastSalaryHour then
        lastSalaryHour = currentHour
        
        for _, ply in player.Iterator() do
            if ply:Alive() and ply:HasActiveChar() then
                local salary = 50 -- Base salary
                ply:AddMoney(salary, "Hourly salary")
            end
        end
    end
end)
```

#### Time Command
```lua
Monarch.RegisterChatCommand("/time", {
    callback = function(ply, args)
        local time = Monarch.Time.GetFormatted()
        local period = Monarch.Time.GetPeriod()
        local isDaytime = Monarch.Time.IsDaytime()
        
        ply:Notify("Current time: " .. time, 0, 5)
        ply:Notify(period .. " - " .. (isDaytime and "Daytime" or "Nighttime"), 0, 5)
    end
})

-- Admin set time command
Monarch.RegisterChatCommand("/settime", {
    adminOnly = true,
    takeArgs = true,
    callback = function(ply, args)
        if not args[1] then
            ply:Notify("Usage: /settime <hour> [minute]", 1)
            return
        end
        
        local hour = tonumber(args[1])
        local minute = tonumber(args[2]) or 0
        
        if not hour or hour < 0 or hour > 23 then
            ply:Notify("Hour must be between 0 and 23", 1)
            return
        end
        
        if Monarch.Time.SetTime(hour, minute) then
            ply:Notify(string.format("Time set to %02d:%02d", hour, minute), 0)
        end
    end
})
```


