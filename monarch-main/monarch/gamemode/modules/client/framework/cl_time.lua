Monarch = Monarch or {}
Monarch.Time = Monarch.Time or {}

if not Monarch.Time.Get then
    Monarch = Monarch or {}
    Monarch.Time = Monarch.Time or {}
    Monarch.Time.CYCLE_DURATION = Monarch.Time.CYCLE_DURATION or (3600 / 1.5)
    Monarch.Time.ServerTimeOffset = Monarch.Time.ServerTimeOffset or 0
    function Monarch.Time.Get()
        local posInCycle = (CurTime() + (Monarch.Time.ServerTimeOffset or 0)) % Monarch.Time.CYCLE_DURATION
        local totalMinutes = (posInCycle / Monarch.Time.CYCLE_DURATION) * 24 * 60
        local hour = math.floor(totalMinutes / 60)
        local minute = math.floor(totalMinutes % 60)
        local ampm = hour >= 12 and "PM" or "AM"
        local hour12 = hour % 12
        if hour12 == 0 then hour12 = 12 end
        return string.format("%02d:%02d %s", hour12, minute, ampm)
    end
end
