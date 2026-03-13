AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

if SERVER then
    util.AddNetworkString("Monarch_ATM_Open")
    util.AddNetworkString("Monarch_ATM_Update")
    util.AddNetworkString("Monarch_ATM_Deposit")
    util.AddNetworkString("Monarch_ATM_Withdraw")
    util.AddNetworkString("Monarch_ATM_CashCheck")
end

ENT.Model = ENT.Model or "models/props_lab/reciever01b.mdl"

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

end

local function getChar(ply)
    if not IsValid(ply) then return nil end
    return ply.MonarchActiveChar
end

local function getWalletBank(ply)
    if not IsValid(ply) then return 0, 0, false end

    local wallet = 0
    if ply.GetMoney then
        local ok, res = pcall(ply.GetMoney, ply)
        if ok then wallet = tonumber(res) or 0 end
    else
        wallet = tonumber(ply:GetNWInt("Money", ply:GetPData("Money") or 0)) or 0
    end
    local bank = 0
    if ply.GetSecondaryMoney then
        local ok, res = pcall(ply.GetSecondaryMoney, ply)
        if ok then bank = tonumber(res) or 0 end
    else
        bank = tonumber(ply:GetNWInt("bankMoney", ply:GetPData("bankMoney") or 0)) or 0
    end
    return wallet, bank, true
end

local function setWalletBank(ply, newWallet, newBank)
    if not IsValid(ply) then return false end

    if ply.SetMoney then ply:SetMoney(newWallet) else ply:SetNWInt("Money", newWallet) end
    if ply.SetSecondaryMoney then ply:SetSecondaryMoney(newBank) else ply:SetNWInt("bankMoney", newBank) end
    return true
end

local function countPlayerChecks(ply)
    if not IsValid(ply) or not ply.beenInvSetup then return 0 end
    if not (Monarch and Monarch.Inventory and Monarch.Inventory.Data) then return 0 end

    local charID = ply.MonarchID or (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
    if not charID then return 0 end

    local invChar = Monarch.Inventory.Data[charID] and Monarch.Inventory.Data[charID][1]
    local sid = ply:SteamID64()
    local invSid = Monarch.Inventory.Data[sid]
    local count = 0

    if invChar then
        for _, item in pairs(invChar) do
            if istable(item) and (item.class == "util_payroll_check" or item.id == "util_payroll_check") then
                count = count + 1
            end
        end
    end

    if invSid then
        for _, item in pairs(invSid) do
            if istable(item) and (item.class == "util_payroll_check" or item.id == "util_payroll_check") then
                count = count + 1
            end
        end
    end

    return count
end

local function removePayrollCheck(ply)
    if not IsValid(ply) or not ply.beenInvSetup then return false end
    if not (Monarch and Monarch.Inventory and Monarch.Inventory.Data) then return false end

    local charID = ply.MonarchID or (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
    if not charID then return false end

    ply.InventoryRegister = ply.InventoryRegister or {}
    ply.InventoryStorageRegister = ply.InventoryStorageRegister or {}

    local invChar = Monarch.Inventory.Data[charID] and Monarch.Inventory.Data[charID][1]
    local sid = ply:SteamID64()
    local invSid = Monarch.Inventory.Data[sid]

    local function countChecks(inv)
        if not inv then return 0 end
        local c = 0
        for _, item in pairs(inv) do
            if istable(item) and (item.class == "util_payroll_check" or item.id == "util_payroll_check") then
                c = c + 1
            end
        end
        return c
    end

    local beforeChar = countChecks(invChar)
    local beforeSid = countChecks(invSid)
    local beforeTotal = beforeChar + beforeSid
    if ply.TakeInventoryItemClass then
        ply:TakeInventoryItemClass("util_payroll_check", 1, 1)
    end

    invChar = Monarch.Inventory.Data[charID] and Monarch.Inventory.Data[charID][1]
    invSid = Monarch.Inventory.Data[sid]

    local afterChar = countChecks(invChar)
    local afterSid = countChecks(invSid)
    local afterTotal = afterChar + afterSid
    if afterTotal < beforeTotal then
        return true
    end

    if invChar then
        for slot, item in pairs(invChar) do
            if item and (item.class == "util_payroll_check" or item.id == "util_payroll_check") then
                invChar[slot] = nil
                if Monarch.Inventory.DBRemoveItem then
                    Monarch.Inventory.DBRemoveItem(charID, item.class or item.id, 1, 1)
                end
                local reg = (item.class or item.id)
                ply.InventoryRegister[reg] = math.max((ply.InventoryRegister[reg] or 1) - 1, 0)
                if ply.InventoryRegister[reg] == 0 then ply.InventoryRegister[reg] = nil end
                if Monarch.Inventory.SaveForOwner then
                    Monarch.Inventory.SaveForOwner(ply, charID)
                end
                if ply.SyncInventory then ply:SyncInventory() end

                local afterChar2 = countChecks(invChar)
                local afterSid2 = countChecks(invSid)
                if afterChar2 + afterSid2 < afterTotal then
                    return true
                end

                break
            end
        end
    end

    if invSid then
        for slot, item in pairs(invSid) do
            if item and (item.class == "util_payroll_check" or item.id == "util_payroll_check") then
                invSid[slot] = nil
                local reg = (item.class or item.id)
                ply.InventoryRegister[reg] = math.max((ply.InventoryRegister[reg] or 1) - 1, 0)
                if ply.InventoryRegister[reg] == 0 then ply.InventoryRegister[reg] = nil end
                if Monarch.Inventory.SaveForOwner then
                    Monarch.Inventory.SaveForOwner(ply, charID)
                end
                if ply.SyncInventory then ply:SyncInventory() end
                local afterChar2 = countChecks(invChar)
                local afterSid2 = countChecks(invSid)
                if afterChar2 + afterSid2 < afterTotal then
                    return true
                end

                break
            end
        end
    end

    return false
end

local function sendATMUpdate(ply)
    if not IsValid(ply) then return end
    local wallet, bank = getWalletBank(ply)
    net.Start("Monarch_ATM_Update")
        net.WriteInt(wallet, 32)
        net.WriteInt(bank, 32)
    net.Send(ply)
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    local wallet, bank = getWalletBank(activator)

    net.Start("Monarch_ATM_Open")
        net.WriteEntity(self)
        net.WriteInt(wallet, 32)
        net.WriteInt(bank, 32)
    net.Send(activator)
end

if SERVER then
    net.Receive("Monarch_ATM_Deposit", function(len, ply)
        if not IsValid(ply) then return end
        ply._atmNext = ply._atmNext or 0
        if ply._atmNext > CurTime() then return end
        ply._atmNext = CurTime() + 0.5

        local amt = net.ReadUInt(32) or 0
        amt = math.floor(math.max(0, amt))
        if amt <= 0 or amt > 100000000 then return end

        local wallet, bank = getWalletBank(ply)
        if wallet < amt then
            if ply.Notify then ply:Notify("You don't have enough cash.") end
            sendATMUpdate(ply)
            return
        end
        wallet = wallet - amt
        bank = bank + amt
        setWalletBank(ply, wallet, bank)
        if ply.Notify then ply:Notify("Deposited $"..amt..".") end
        sendATMUpdate(ply)
    end)

    net.Receive("Monarch_ATM_Withdraw", function(len, ply)
        if not IsValid(ply) then return end
        ply._atmNext = ply._atmNext or 0
        if ply._atmNext > CurTime() then return end
        ply._atmNext = CurTime() + 0.5

        local amt = net.ReadUInt(32) or 0
        amt = math.floor(math.max(0, amt))
        if amt <= 0 or amt > 100000000 then return end

        local wallet, bank = getWalletBank(ply)
        if bank < amt then
            if ply.Notify then ply:Notify("You don't have enough in the bank.") end
            sendATMUpdate(ply)
            return
        end
        bank = bank - amt
        wallet = wallet + amt
        setWalletBank(ply, wallet, bank)
        if ply.Notify then ply:Notify("Withdrew $"..amt..".") end
        sendATMUpdate(ply)
    end)

    net.Receive("Monarch_ATM_CashCheck", function(len, ply)
        if not IsValid(ply) then return end

        ply._atmNext = ply._atmNext or 0
        if ply._atmNext > CurTime() then return end
        ply._atmCheckLock = ply._atmCheckLock or false
        if ply._atmCheckLock then return end
        ply._atmCheckLock = true
        ply._atmNext = CurTime() + 1.0

        local checkAmount = 0
        if Monarch and Monarch.Payroll and Monarch.Payroll.CalculatePayroll then
            checkAmount = Monarch.Payroll.CalculatePayroll(ply)
        else
            checkAmount = 100 
        end

        if checkAmount <= 0 then
            ply._atmCheckLock = false
            if ply.Notify then ply:Notify("You don't have any valid checks to cash.") end
            return
        end

        local checksBefore = countPlayerChecks(ply)
        if checksBefore <= 0 then
            ply._atmCheckLock = false
            if ply.Notify then ply:Notify("You don't have a check to cash.") end
            return
        end

        local removed = removePayrollCheck(ply)
        local checksAfter = countPlayerChecks(ply)
        if not removed or checksAfter ~= (checksBefore - 1) then
            ply._atmCheckLock = false
            if ply.Notify then ply:Notify("Failed to process check. Please try again.") end
            return
        end

        local wallet, bank = getWalletBank(ply)
        wallet = wallet + checkAmount
        setWalletBank(ply, wallet, bank)

        if math.random() <= (Monarch and Monarch.Payroll and Monarch.Payroll.Config and Monarch.Payroll.Config.LoyaltyGainChance or 0.25) then
            if Monarch and Monarch.Loyalty and Monarch.Loyalty.SetLoyaltyTier then
                local data = Monarch.Loyalty.GetPlayerData(ply)
                if data then
                    local currentPoints = tonumber(data.loyalty_points) or 0
                    local gainAmount = (Monarch and Monarch.Payroll and Monarch.Payroll.Config and Monarch.Payroll.Config.LoyaltyGainAmount) or 1
                    local newPoints = math.min(currentPoints + gainAmount, 100)
                    Monarch.Loyalty.SetLoyaltyTier(ply, newPoints)

                    net.Start("Monarch_LoyaltyGain")
                    net.WriteInt(gainAmount, 8)
                    net.Send(ply)

                    if ply.Notify then ply:Notify("Check cashed for $" .. checkAmount .. "! Your loyalty level increased!") end
                end
            end
        else
            if ply.Notify then ply:Notify("Check cashed for $" .. checkAmount .. ".") end
        end

        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply._atmCheckLock = false
            end
        end)

        sendATMUpdate(ply)
    end)
end
