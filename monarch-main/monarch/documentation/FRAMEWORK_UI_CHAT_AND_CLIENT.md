# Monarch Framework - UI, Chat, and Client Systems


## Chat Commands

### Monarch.RegisterChatCommand(command, config)
Register a new chat command.
- **Parameters:**
  - `command` (string): Command trigger (e.g., "/give")
  - `config` (table): Configuration table with fields:
    - `callback` (function): Function to call
    - `adminOnly` (boolean): Optional. Require admin
    - `hideMessage` (boolean): Optional. Hide the command message
    - `takeArgs` (boolean): Optional. Pass arguments to callback
- **Returns:** None
- **Realm:** Shared
- **Example:**
```lua
Monarch.RegisterChatCommand("/heal", {
    callback = function(ply, args)
        ply:SetHealth(100)
        ply:Notify("You've been healed!")
    end,
    adminOnly = true,
    takeArgs = true
})
```

### Monarch.FindPlayer(info)
Find a player by partial name or SteamID.
- **Parameters:**
  - `info` (string): Player name or SteamID (partial match supported)
- **Returns:** Player/nil - Found player or nil
- **Realm:** Shared
- **Example:**
```lua
local target = Monarch.FindPlayer("John")
if target then
    print("Found:", target:Nick())
end
```

---


## Utility Functions

All utility functions are in the `Monarch.Utils` namespace.

### Monarch_ShowUseBar(parentPanel, duration, labelText, onDone, allowMovement)
Show a circular progress overlay for timed actions.
- **Parameters:**
  - `parentPanel` (Panel/nil): Parent panel for the overlay. Falls back to `vgui.GetWorldPanel()`.
  - `duration` (number): Duration in seconds. Internally clamped to a minimum of `0.05`.
  - `labelText` (string): Optional text shown under the progress circle (default fallback is "Using item...").
  - `onDone` (function): Optional callback fired when the timer finishes.
  - `allowMovement` (boolean): Optional. If `false`, captures mouse/keyboard input while active (except inventory-overlay mode).
- **Returns:** Panel/nil - Active overlay panel (DPanel) that can be removed to cancel.
- **Realm:** Client
- **Behavior Notes:**
  - Only one active use overlay exists at a time; existing overlay is removed when a new one is shown.
  - When inventory is open, the bar renders in inventory-overlay mode and uses world panel parenting.
  - If the returned panel is removed early, `onDone` is not called.
- **Example:**
```lua
Monarch_ShowUseBar(vgui.GetWorldPanel(), 3, "Processing...", function()
    LocalPlayer():ConCommand("say Finished processing")
end, false)
```

```lua
local overlay = Monarch_ShowUseBar(vgui.GetWorldPanel(), 5, "Lockpicking...")
timer.Simple(1.5, function()
    if IsValid(overlay) then overlay:Remove() end -- cancel
end)
```

### Monarch.Utils.IsEmpty(str)
Check if a string is empty or nil.
- **Parameters:**
  - `str` (string): String to check
- **Returns:** boolean - True if empty or nil
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Utils.IsEmpty(name) then
    print("Name is empty!")
end
```

### Monarch.Utils.Clamp(value, min, max)
Clamp a number between min and max.
- **Parameters:**
  - `value` (number): Value to clamp
  - `min` (number): Minimum value
  - `max` (number): Maximum value
- **Returns:** number - Clamped value
- **Realm:** Shared
- **Example:**
```lua
local health = Monarch.Utils.Clamp(hp, 0, 100)
```

### Monarch.Utils.FormatMoney(amount)
Format a money amount with comma separators.
- **Parameters:**
  - `amount` (number): Amount to format
- **Returns:** string - Formatted string (e.g., "$1,234")
- **Realm:** Shared
- **Example:**
```lua
local formatted = Monarch.Utils.FormatMoney(5000)
-- Returns: "$5,000"
```

### Monarch.Utils.GetDistance(a, b)
Get distance between two entities or positions.
- **Parameters:**
  - `a` (Entity/Vector): First entity or position
  - `b` (Entity/Vector): Second entity or position
- **Returns:** number - Distance in units
- **Realm:** Shared
- **Example:**
```lua
local dist = Monarch.Utils.GetDistance(ply1, ply2)
```

### Monarch.Utils.IsWithinDistance(ply1, ply2, distance)
Check if two players are within a certain distance.
- **Parameters:**
  - `ply1` (Player): First player
  - `ply2` (Player): Second player
  - `distance` (number): Maximum distance
- **Returns:** boolean - True if within distance
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Utils.IsWithinDistance(ply1, ply2, 200) then
    -- Players are close enough
end
```

### Monarch.Utils.GetPlayersInRadius(source, distance, filter)
Get all players within a radius of a position or entity.
- **Parameters:**
  - `source` (Vector/Entity): Source position or entity
  - `distance` (number): Radius distance
  - `filter` (function): Optional. Filter function (return true to include player)
- **Returns:** table - Array of players within radius
- **Realm:** Shared
- **Example:**
```lua
local nearby = Monarch.Utils.GetPlayersInRadius(ply:GetPos(), 500)
for _, nearbyPly in ipairs(nearby) do
    print(nearbyPly:Nick() .. " is nearby")
end

-- With filter
local nearbyPolice = Monarch.Utils.GetPlayersInRadius(ply:GetPos(), 500, function(p)
    return p:Team() == TEAM_POLICE
end)
```

### Monarch.Utils.Sanitize(str, allowSpaces)
Sanitize a string by removing special characters.
- **Parameters:**
  - `str` (string): String to sanitize
  - `allowSpaces` (boolean): Optional. Allow spaces (default: false)
- **Returns:** string - Sanitized string
- **Realm:** Shared
- **Example:**
```lua
local clean = Monarch.Utils.Sanitize("Hello! World?")
-- Returns: "HelloWorld"

local cleanWithSpaces = Monarch.Utils.Sanitize("Hello! World?", true)
-- Returns: "Hello World"
```

### Monarch.Utils.TableCopy(original)
Create a deep copy of a table.
- **Parameters:**
  - `original` (table): Table to copy
- **Returns:** table - Copied table
- **Realm:** Shared
- **Example:**
```lua
local original = {a = 1, b = {c = 2}}
local copy = Monarch.Utils.TableCopy(original)
copy.b.c = 3
-- original.b.c is still 2
```

---


## Introduction System

The introduction system allows players to introduce themselves to others.

### Monarch.Introductions.GetKnownName(observer, target)
*Server only* - Get the name that an observer knows for a target.
- **Parameters:**
  - `observer` (Player): Player observing
  - `target` (Player): Player being observed
- **Returns:** string/nil - Known name or nil
- **Realm:** Server only

### Monarch.Introductions.IntroducePlayer(introducer, target, observer, customName)
*Server only* - Introduce a player to another.
- **Parameters:**
  - `introducer` (Player): Player doing the introduction
  - `target` (Player): Player being introduced
  - `observer` (Player): Player being introduced to
  - `customName` (string): Optional. Custom name for introduction
- **Realm:** Server only

### Monarch.Introductions.GetDisplayName(ply)
*Client only* - Get the display name for a player (checks introductions).
- **Parameters:**
  - `ply` (Player): Player to get name for
- **Returns:** string - Display name
- **Realm:** Client only

### Monarch.Introductions.SetDefaultTeamKnowledge(rules)
*Server only* - Set default team-to-team name knowledge rules.
- **Parameters:**
  - `rules` (table): Key is observer team ID, value is either:
    - `true` to know all teams
    - table map `{ [targetTeamId] = true }`
    - table array `{ targetTeamId1, targetTeamId2, ... }`
- **Realm:** Server only

### Monarch.Introductions.GetDefaultTeamKnowledge()
*Server only* - Get current default team-to-team name knowledge rules.
- **Returns:** table - Current rules table
- **Realm:** Server only

### Monarch.Introductions.ApplyDefaultTeamKnowledge(observer, specificTarget)
*Server only* - Apply default team knowledge to one observer.
- **Parameters:**
  - `observer` (Player): Player who should know names by default
  - `specificTarget` (Player): Optional. Apply only to this target
- **Realm:** Server only

---


## Animation System

The animation system allows you to control player animations, gestures, and sequences.

### ply:PlayGesture(gesture, restart)
Play a gesture animation on the player (e.g., wave, salute).
- **Parameters:**
  - `gesture` (number): Gesture activity ID (e.g., `ACT_GMOD_GESTURE_WAVE`)
  - `restart` (boolean): Optional. Restart if already playing (default: true)
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
-- Wave gesture
ply:PlayGesture(ACT_GMOD_GESTURE_WAVE)

-- Salute gesture
ply:PlayGesture(ACT_GMOD_GESTURE_SALUTE)

-- Point gesture without restart
ply:PlayGesture(ACT_GMOD_GESTURE_POINT, false)
```

**Common Gesture Activities:**
- `ACT_GMOD_GESTURE_WAVE` - Wave
- `ACT_GMOD_GESTURE_AGREE` - Thumbs up
- `ACT_GMOD_GESTURE_DISAGREE` - Thumbs down
- `ACT_GMOD_GESTURE_BECON` - Beckon/come here
- `ACT_GMOD_GESTURE_BOW` - Bow
- `ACT_GMOD_GESTURE_SALUTE` - Salute
- `ACT_GMOD_GESTURE_CHEER` - Cheer
- `ACT_SIGNAL_FORWARD` - Signal forward
- `ACT_SIGNAL_HALT` - Stop signal

### ply:StopGesture()
Stop the current gesture animation.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:StopGesture()
```

### ply:PlaySequence(sequenceName)
Play an animation sequence by name.
- **Parameters:**
  - `sequenceName` (string): Name of the sequence
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:PlaySequence("wave")
ply:PlaySequence("cheer")
ply:PlaySequence("salute")
```

**Note:** To get the name of the current animation sequence, use the built-in Entity method:
```lua
local currentAnim = ply:GetSequenceName(ply:GetSequence())
print("Currently playing:", currentAnim)
```

### ply:SetAnimationRate(rate)
Set the playback speed of animations.
- **Parameters:**
  - `rate` (number): Playback rate (1.0 = normal, 2.0 = double speed, 0.5 = half speed)
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
-- Slow motion
ply:SetAnimationRate(0.5)

-- Normal speed
ply:SetAnimationRate(1.0)

-- Fast forward
ply:SetAnimationRate(2.0)
```

### ply:RestartAnimation()
Restart the current animation from the beginning.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:RestartAnimation()
```

### Animation System Example
```lua
-- Create a wave command
Monarch.RegisterChatCommand("/wave", {
    callback = function(ply)
        ply:PlayGesture(ACT_GMOD_GESTURE_WAVE)
        
        -- Stop the gesture after 2 seconds
        timer.Simple(2, function()
            if IsValid(ply) then
                ply:StopGesture()
            end
        end)
    end
})

-- Slow motion on crouch
hook.Add("KeyPress", "SlowMotionCrouch", function(ply, key)
    if key == IN_DUCK then
        ply:SetAnimationRate(0.5)
    end
end)

hook.Add("KeyRelease", "NormalSpeedCrouch", function(ply, key)
    if key == IN_DUCK then
        ply:SetAnimationRate(1.0)
    end
end)
```

---


## Model Scaling System

The scaling system allows you to change the size of players and manipulate individual bones.

### ply:SetScale(scale, duration)
Set the player's model scale (size).
- **Parameters:**
  - `scale` (number): Scale multiplier (1.0 = normal, 2.0 = double size, 0.5 = half size)
  - `duration` (number): Optional. Transition duration in seconds (default: 0 = instant)
- **Returns:** boolean - True if successful
- **Realm:** Server only (applies to all clients)
- **Example:**
```lua
-- Make player twice as big instantly
ply:SetScale(2.0)

-- Shrink player to half size over 2 seconds
ply:SetScale(0.5, 2)

-- Giant player
ply:SetScale(5.0)

-- Tiny player
ply:SetScale(0.25)
```

**Note:** Scale is clamped between 0.1 and 10 to prevent extreme values. Collision hull is automatically adjusted.

### ply:GetScale()
Get the player's current model scale.
- **Returns:** number - Current scale multiplier
- **Realm:** Shared
- **Example:**
```lua
local currentScale = ply:GetScale()
print("Player scale:", currentScale)

if currentScale > 1.5 then
    print("Player is enlarged!")
end
```

### ply:ResetScale(duration)
Reset player scale to normal (1.0).
- **Parameters:**
  - `duration` (number): Optional. Transition duration (default: 0)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
-- Reset instantly
ply:ResetScale()

-- Reset over 1 second
ply:ResetScale(1)
```

### ply:ScaleBone(boneID, scale)
Scale a specific bone on the player's model.
- **Parameters:**
  - `boneID` (number): Bone ID to scale
  - `scale` (Vector): Scale vector for each axis (X, Y, Z)
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
-- Make head bigger
local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
if headBone then
    ply:ScaleBone(headBone, Vector(2, 2, 2))
end

-- Stretch arms horizontally
local leftArmBone = ply:LookupBone("ValveBiped.Bip01_L_UpperArm")
if leftArmBone then
    ply:ScaleBone(leftArmBone, Vector(1, 3, 1))
end
```

### ply:ResetBoneScales()
Reset all bone scales to normal.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:ResetBoneScales()
```

### Scaling System Examples
```lua
-- Growth potion effect
function ApplyGrowthPotion(ply)
    local currentScale = ply:GetScale()
    local newScale = math.min(currentScale * 1.5, 3.0) -- Max 3x size
    
    ply:SetScale(newScale, 1.5) -- Grow over 1.5 seconds
    ply:Notify("You feel yourself growing larger!", 0)
    
    -- Revert after 30 seconds
    timer.Simple(30, function()
        if IsValid(ply) then
            ply:ResetScale(1.5)
            ply:Notify("You return to normal size", 0)
        end
    end)
end

-- Shrink ray weapon
function ShrinkPlayer(ply)
    if SERVER then
        local currentScale = ply:GetScale()
        if currentScale > 0.3 then
            ply:SetScale(currentScale * 0.8, 0.5)
            ply:Notify("You've been shrunk!", 1)
        end
    end
end

-- Big head mode (silly effect)
function EnableBigHeadMode(ply)
    local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
    if headBone then
        ply:ScaleBone(headBone, Vector(3, 3, 3))
    end
end
```

---


## User Interfaces - UI Scaling System

**File:** `gamemode/modules/client/cl_scale.lua`

The UI Scaling System provides responsive scaling utilities for creating dynamic user interfaces that adapt to different screen resolutions. All scaling is based on a reference resolution of 1920x1080, with scaling calculations cached and updated automatically when the screen size changes.

### Core Scaling Functions

#### Monarch.UI.GetScale()
Returns the current scaling factors, recalculating if the screen size has changed.
- **Returns:** 
  - `scale` (number) - The uniform scale factor (minimum of X and Y scale)
  - `scaleX` (number) - Horizontal scale factor (width ratio)
  - `scaleY` (number) - Vertical scale factor (height ratio)
- **Realm:** Client
- **Example:**
```lua
local scale, sx, sy = Monarch.UI.GetScale()
print("Uniform scale:", scale)
print("X scale:", sx, "Y scale:", sy)
```

#### Monarch.UI.Scale(v)
Scales a value uniformly using the minimum scale factor (maintains aspect ratio).
- **Parameters:**
  - `v` (number): Value to scale
- **Returns:** number - Scaled value (rounded to nearest integer)
- **Realm:** Client
- **Example:**
```lua
local scaledSize = Monarch.UI.Scale(100)  -- Scales 100 uniformly
local scaledFont = Monarch.UI.Scale(24)   -- Scales font size
```

#### Monarch.UI.ScaleX(v)
Scales a value horizontally using the X scale factor.
- **Parameters:**
  - `v` (number): Value to scale
- **Returns:** number - Horizontally scaled value (rounded to nearest integer)
- **Realm:** Client
- **Example:**
```lua
local scaledWidth = Monarch.UI.ScaleX(500)
local scaledX = Monarch.UI.ScaleX(150)
```

#### Monarch.UI.ScaleY(v)
Scales a value vertically using the Y scale factor.
- **Parameters:**
  - `v` (number): Value to scale
- **Returns:** number - Vertically scaled value (rounded to nearest integer)
- **Realm:** Client
- **Example:**
```lua
local scaledHeight = Monarch.UI.ScaleY(300)
local scaledY = Monarch.UI.ScaleY(100)
```

#### Monarch.UI.ScaleFont(sz)
Scales a font size uniformly. This is an alias for `Monarch.UI.Scale()`.
- **Parameters:**
  - `sz` (number): Font size to scale
- **Returns:** number - Scaled font size
- **Realm:** Client
- **Example:**
```lua
local scaledFontSize = Monarch.UI.ScaleFont(32)
```

#### Monarch.UI.ScreenCenter()
Returns the center coordinates of the screen.
- **Returns:** 
  - `x` (number) - Center X coordinate
  - `y` (number) - Center Y coordinate
- **Realm:** Client
- **Example:**
```lua
local centerX, centerY = Monarch.UI.ScreenCenter()
panel:SetPos(centerX - panel:GetWide() / 2, centerY - panel:GetTall() / 2)
```

#### Monarch.UI.BlinkAlpha(baseAlpha)
Calculates a blinking alpha value using a sine wave, useful for animated UI elements.
- **Parameters:**
  - `baseAlpha` (number): Optional. Base alpha value (0-255). Default: 255
- **Returns:** number - Blinking alpha value (0-255)
- **Realm:** Client
- **Example:**
```lua
-- In Paint function
surface.SetDrawColor(255, 255, 255, Monarch.UI.BlinkAlpha(200))
surface.DrawRect(x, y, w, h)
```

### Workbar System

#### Monarch.MakeWorkbar(time, text, callback, freeze)
Creates and displays an animated progress bar (workbar) for time-based actions (e.g., crafting, looting).
- **Parameters:**
  - `time` (number): Duration in seconds
  - `text` (string): Text to display on the workbar
  - `callback` (function): Optional. Function to call when the workbar completes
  - `freeze` (boolean): Optional. Whether to freeze the player during the action (default: false)
- **Returns:** DPanel - The workbar panel
- **Realm:** Client
- **Notes:**
  - The workbar displays centered on screen
  - Players can press SPACE to cancel the workbar
  - The player is frozen during the action if `freeze` is true
  - The workbar automatically removes itself when complete
- **Example:**
```lua
Monarch.MakeWorkbar(5, "Looting...", function()
    print("Looting complete!")
end, true)  -- Freezes player while looting

-- Another example without freezing
Monarch.MakeWorkbar(3, "Crafting...", function()
    ply:AddMoney(100, "Crafted item")
end)
```

### Shorthand Functions

For convenience, the following shorthand functions are available globally:

```lua
Scale(v)      -- Alias for Monarch.UI.Scale(v)
ScaleX(v)     -- Alias for Monarch.UI.ScaleX(v)
ScaleY(v)     -- Alias for Monarch.UI.ScaleY(v)
ScaleFont(sz) -- Alias for Monarch.UI.ScaleFont(sz)
```

### Usage Recommendations

1. **Always use scaling for UI positions and sizes** - This ensures your UI looks correct on all resolutions
2. **Use `Scale()` for uniform scaling** - Maintains aspect ratio and looks consistent
3. **Use `ScaleX()` and `ScaleY()` separately** - When you need different scaling for width and height
4. **Cache values when possible** - Don't scale the same value repeatedly in loops
5. **Test on different resolutions** - The reference resolution is 1920x1080

### Example: Creating a Responsive Panel

```lua
local panel = vgui.Create("DPanel")
panel:SetSize(Monarch.UI.Scale(400), Monarch.UI.Scale(300))
panel:SetPos(Monarch.UI.ScaleX(100), Monarch.UI.ScaleY(100))

local label = vgui.Create("DLabel", panel)
label:SetText("Hello World")
label:SizeToContents()
label:SetPos(Monarch.UI.Scale(20), Monarch.UI.Scale(20))
label:SetFont("Monarch_Font_" .. Monarch.UI.ScaleFont(20))
```

---


#### Monarch.RegisterChatType(uniqueID, fontType, textColor, canSeeFn)
Register or overwrite a chat type.
- **Parameters:**
  - `uniqueID` (string): Unique type ID (normalized lowercase)
  - `fontType` (string): Font name used by typed dispatch
  - `textColor` (Color): Message color used by typed dispatch
  - `canSeeFn` (function): Visibility callback `function(listener, speaker, message, context) -> boolean`
- **Returns:** `true, chatTypeTable` on success, `false, reason` on failure
- **Realm:** Shared

#### Monarch.GetChatType(uniqueID)
Get a registered chat type definition.
- **Returns:** table/nil
- **Realm:** Shared

#### Monarch.SendChatMessage(chatType, message)
Convenience sender for message-only output.
- **Server behavior:** broadcasts typed message to all players
- **Client behavior:** prints local typed message
- **Returns:** `true` on success, or `false, "unknown-chat-type"`
- **Realm:** Shared

#### Monarch.GetChatTypeRecipients(uniqueID, speaker, message, context)
Resolve recipients from a chat type visibility callback.
- **Returns:** array of players (always includes speaker fallback if valid)
- **Realm:** Server

#### Monarch.SendChatType(uniqueID, speaker, prefixColor, prefix, userColor, userData, message, recipients)
Low-level typed chat sender used by framework systems.
- **Returns:** `true` on success, or `false, "unknown-chat-type"`
- **Realm:** Server

### IC Chat Decorator API

#### Monarch.RegisterICChatDecorator(id, fn)
Register a decorator that can add prefixes/suffixes to IC speech.

#### Monarch.BuildICChatDecorations(ply, message)
Build merged prefix/suffix from all decorators.

