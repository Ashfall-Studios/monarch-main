local PlayerMeta = FindMetaTable("Player")

util.AddNetworkString("Monarch.GiveMoney")
util.AddNetworkString("Monarch_GiveMoney_Result")
util.AddNetworkString("Monarch.SetMoney")

local function sendResult(ply, ok, msg)
    if not IsValid(ply) then return end
    net.Start("Monarch_GiveMoney_Result")
        net.WriteBool(ok and true or false)
        net.WriteString(msg or (ok and "Success" or "Failed"))
    net.Send(ply)
end

net.Receive("Monarch.GiveMoney", function(_, ply)
    local target = net.ReadEntity()
    local amount = net.ReadUInt(32) or 0
    if not IsValid(target) or not target:IsPlayer() then
        sendResult(ply, false, "Invalid target.")
        return
    end
    if amount <= 0 then
        sendResult(ply, false, "Invalid amount.")
        return
    end

    local canGive = hook.Run("Monarch_CanGiveMoney", ply, target, amount)
    if canGive == false then
        sendResult(ply, false, "Transfer blocked.")
        return
    end

    local ok, msg = ply:GiveMoney(target, amount)
    if ok then
        sendResult(ply, true, msg)
        hook.Run("Monarch_MoneyTransferred", ply, target, amount, msg)
        if target.Notify then
            local amtStr = Monarch and Monarch.FormatMoney and Monarch.FormatMoney(amount) or ("$"..tostring(amount))
            target:Notify(string.format("%s gave you %s.", ply:GetRPName() or ply:Nick(), amtStr))
        end
    else
        sendResult(ply, false, msg or "Transfer failed.")
    end
end)

net.Receive("Monarch.SetMoney", function(_, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local target = net.ReadEntity()
    local amount = net.ReadUInt(32) or 0
    if not IsValid(target) or not target:IsPlayer() then
        ply:Notify("Invalid target.")
        return
    end

    local canSet = hook.Run("Monarch_CanSetMoney", ply, target, amount)
    if canSet == false then
        ply:Notify("Money set blocked.")
        return
    end

    local oldAmount = (target.GetMoney and target:GetMoney()) or tonumber(target.Money) or 0
    target:SetMoney(amount)
    hook.Run("Monarch_MoneySetByAdmin", ply, target, oldAmount, amount)
    local amtStr = Monarch and Monarch.FormatMoney and Monarch.FormatMoney(amount) or ("$"..tostring(amount))
    ply:Notify(string.format("Set %s's money to %s.", target:GetRPName() or target:Nick(), amtStr))
    if target ~= ply and target.Notify then
        target:Notify(string.format("Your balance was set to %s by %s.", amtStr, ply:GetRPName() or ply:Nick()))
    end
end)

local function findPlayerByName(part)
    part = tostring(part or ""):lower()
    local best
    for _, v in player.Iterator() do
        if v:Nick():lower():find(part, 1, true) then best = v break end
    end
    return best
end

function PlayerMeta:SetMoney(amount)
    local oldAmount = (self.GetMoney and self:GetMoney()) or tonumber(self.Money) or tonumber(self:GetNWInt("Money", 0)) or 0
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if mysql and mysql.Update then
        local query = mysql:Update("monarch_players")
        query:Update("money", amount)
        query:Where("steamid", self:SteamID())
        query:Execute()
    end

    self:SetPData("Money", amount)
    self:SetNWInt("Money", amount)
    self.Money = Amount

    if self.SetLocalSyncVar and SYNC_MONEY then
        self:SetLocalSyncVar(SYNC_MONEY, amount)
    end

    hook.Run("Monarch_PlayerMoneySet", self, oldAmount, amount)
    return amount
end

function PlayerMeta:SetSecondaryMoney(x)
    x = math.max(0, math.floor(tonumber(x) or 0))
    if mysql and mysql.Update then
        local query = mysql:Update("monarch_players")
        query:Update("bankmoney", x)
        query:Where("steamid", self:SteamID())
        query:Execute()
    end
    self.BankMoney = x
    self:SetPData("bankMoney", x)
    self:SetNWInt("bankMoney", x)
end

function PlayerMeta:GetSecondaryMoney()
    local v = self.BankMoney
    if v == nil then
        v = self:GetNWInt("bankMoney", 0)
    end
    if not v or tonumber(v) == nil then
        v = tonumber(self:GetPData("bankMoney") or 0) or 0
    end
    return tonumber(v) or 0
end

function PlayerMeta:AddMoney(x)
    x = math.floor(tonumber(x) or 0)
    local cur = (self.GetMoney and self:GetMoney()) or tonumber(self.Money) or 0

    local canChange = hook.Run("Monarch_CanChangePlayerMoney", self, x, cur)
    if canChange == false then
        return cur
    end

    local newAmt = math.max(0, cur + x)
    if mysql and mysql.Update then
        local query = mysql:Update("monarch_players")
        query:Update("money", newAmt)
        query:Where("steamid", self:SteamID())
        query:Execute()
    end
    self:SetPData("Money", newAmt)
    self:SetNWInt("Money", newAmt)
    self.Money = newAmt
    if self.SetLocalSyncVar and SYNC_MONEY then
        self:SetLocalSyncVar(SYNC_MONEY, newAmt)
    end

    hook.Run("Monarch_PlayerMoneyChanged", self, cur, newAmt, x)
    return newAmt
end

function PlayerMeta:AddBankMoney(x)
    x = math.floor(tonumber(x) or 0)
    local cur = tonumber(self:GetSecondaryMoney()) or 0

    local canChangeBank = hook.Run("Monarch_CanChangePlayerBankMoney", self, x, cur)
    if canChangeBank == false then
        return
    end

    local newAmt = math.max(0, cur + x)
    if mysql and mysql.Update then
        local query = mysql:Update("monarch_players")
        query:Update("bankmoney", newAmt)
        query:Where("steamid", self:SteamID())
        query:Execute()
    end
    self.BankMoney = newAmt
    self:SetPData("bankMoney", newAmt)
    self:SetNWInt("bankMoney", newAmt)
    hook.Run("Monarch_PlayerBankMoneyChanged", self, cur, newAmt, x)
end

function PlayerMeta:GiveMoney(target, amount)
    if not IsValid(self) or not IsValid(target) or not target:IsPlayer() then
        return false, "Invalid target"
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Invalid amount" end

    local canGive = hook.Run("Monarch_CanPlayerGiveMoney", self, target, amount)
    if canGive == false then return false, "Transfer blocked" end

    local myCash = (self.GetMoney and self:GetMoney()) or tonumber(self.Money) or 0
    if myCash < amount then return false, "You don't have enough cash" end

    if self:GetPos():DistToSqr(target:GetPos()) > (150 * 150) then
        return false, "Target too far"
    end

    self:AddMoney(-amount)
    target:AddMoney(amount)

    hook.Run("Monarch_PlayerGaveMoney", self, target, amount)

    return true, "Transferred"
end

hook.Add("PlayerDeath", "Monarch_DropCashOnDeath", function(ply)
    if not IsValid(ply) then return end
    local amt = 0
    if ply.GetMoney then
        local ok, res = pcall(ply.GetMoney, ply)
        if ok then amt = tonumber(res) or 0 end
    end
    if amt <= 0 then return end

    local shouldDrop = hook.Run("Monarch_ShouldDropCashOnDeath", ply, amt)
    if shouldDrop == false then return end
    if isnumber(shouldDrop) then
        amt = math.max(0, math.floor(tonumber(shouldDrop) or 0))
    end
    if amt <= 0 then return end

    local dropPos = (ply:GetPos() or vector_origin) + Vector(0, 0, 12)
    local ent = ents.Create("monarch_item")
    if not IsValid(ent) then return end
    ent:SetPos(dropPos)
    ent:SetItemClass("cash")
    if ent.SetStackAmount then ent:SetStackAmount(math.floor(amt)) else ent:SetNWInt("StackAmount", math.floor(amt)) end
    ent:Spawn()
    ent:Activate()
    if ply.SetMoney then
        ply:SetMoney(0)
    else
        ply:SetNWInt("Money", 0)
        ply:SetPData("Money", 0)
    end

    hook.Run("Monarch_CashDroppedOnDeath", ply, ent, math.floor(amt))
end)