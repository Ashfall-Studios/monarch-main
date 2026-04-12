Monarch = Monarch or {}
Monarch.Inventory = Monarch.Inventory or {}
Monarch.Inventory.Data = Monarch.Inventory.Data or {}
Monarch.Inventory.Data[0] = Monarch.Inventory.Data[0] or {}
Monarch.Inventory.Items = Monarch.Inventory.Items or {}
Monarch.Inventory.ItemsRef = Monarch.Inventory.ItemsRef or {}
Monarch.Inventory.ItemsQW = Monarch.Inventory.ItemsQW or {}
Monarch.Inventory.Benches = Monarch.Inventory.Benches or {}
Monarch.Inventory.Mixtures = Monarch.Inventory.Mixtures or {}
Monarch.Inventory.MixturesRef = Monarch.Inventory.MixturesRef or {}
Monarch.Inventory.CraftInfo = Monarch.Inventory.CraftInfo or {}

if CLIENT then
    Monarch.Inventory.Data[0][1] = Monarch.Inventory.Data[0][1] or {}
    Monarch.Inventory.Data[0][2] = Monarch.Inventory.Data[0][2] or {}
end

local count = 1
local countX = 1

local meta = FindMetaTable("Player")

function Monarch.RegisterItem(item)
	if type(item.SetDurability) ~= "function" then
		function item:SetDurability(itemData, value)
			if not istable(itemData) then return nil end
			local durability = math.floor(tonumber(value) or 0)
			durability = math.Clamp(durability, 0, 100)
			itemData.durability = durability
			return durability
		end
	end

	if type(item.GetDurability) ~= "function" then
		function item:GetDurability(itemData)
			if not istable(itemData) then return nil end
			local startingDurability = math.Clamp(math.floor(tonumber(self.StartingDurability or self.DurabilityStart or self.DefaultDurability or 100) or 100), 0, 100)
			if itemData.durability == nil then
				itemData.durability = startingDurability
			end
			return math.Clamp(math.floor(tonumber(itemData.durability) or startingDurability), 0, 100)
		end
	end

	if type(item.OnDurabilityDrained) ~= "function" then
		function item:OnDurabilityDrained(ply, slot, itemData, context)
			return
		end
	end

	if type(item.WeaponUsed) ~= "function" then
		function item:WeaponUsed(ply, slot, itemData, weapon, context)
			return
		end
	end

	local class = item.WeaponClass
	local attClass = item.AttachmentClass

	if class then
		function item:OnEquip(ply, itemclass, uid)

			if self.ShouldRemoveOnEquip then
				ply:StripInventoryItem(uid, true)
			end
			local wep = ply:Give(class)

			if wep and IsValid(wep) then
				wep:SetClip1(item.WeaponOverrideClip or self.clip or 0)

				if item.WeaponOverrideClip then
					wep.PairedItem = uid
				end
			end
		end

		function item:UnEquip(ply)
			local wep = ply:GetWeapon(class)

			if wep and IsValid(wep) then
				self.clip = wep:Clip1()
				ply:StripWeapon(class)
			end

			if ply.InvAttachments then
				local uid = ply.InvAttachments[class]

				if uid and ply:HasInventoryItemSpecific(uid) then
					ply.doForcedInvEquip = true
					ply:SetInventoryItemEquipped(uid, false)
				end
			end
		end
	elseif attClass then
		function item:CanEquip(ply)
			if ply.doForcedInvEquip then
				ply.doForcedInvEquip = nil
				return true 
			end

			local weps = ply:GetWeapons()

			for v,k in pairs(weps) do
				if (IsValid(k) and k.IsLongsword and k.Attachments and k.Attachments[attClass]) then
					if k.Attachments[attClass] then
						return true
					end
				end
			end

			return false
		end

		function item:OnEquip(ply, itemclass, uid)
			local wep = ply:GetActiveWeapon()
			local weps = ply:GetWeapons()

			for k,v in pairs(weps) do
				if v.IsLongsword and v.Attachments and v.Attachments[attClass] then
					v:GiveAttachment(attClass)
					ply.InvAttachments = ply.InvAttachments or {}
					ply.InvAttachments[v:GetClass()] = uid
				end
			end
		end

		function item:UnEquip(ply, itemclass, uid)
			local weps = ply:GetWeapons()
			local wep = ply:GetActiveWeapon()

			for v,k in pairs(weps) do
				if IsValid(k) and k.IsLongsword and k.Attachments and k.Attachments[attClass] then
					k:TakeAttachment(attClass)
					ply.InvAttachments[k:GetClass()] = nil
					return
				elseif IsValid(k) and k.IsPlutonic and k.Attachments and k.Attachments[attClass] and ply:Alive() then
					net.Start("Plutonic.AttachmentRemove")
					net.WriteEntity(k)
					net.WriteEntity(ply)
					net.WriteString(attClass)
					net.Send(ply)
				end
			end

			ply.InvAttachments = {}
		end
	end

	local craftSound = item.CraftSound
	local craftTime = item.CraftTime

	if craftSound or craftTime then
		Monarch.Inventory.CraftInfo[item.UniqueID] = {
			time = craftTime or nil,
			sound = craftSound or nil
		}
	end

	Monarch.Inventory.Items[count] = item
	Monarch.Inventory.ItemsRef[item.UniqueID] = count
	Monarch.Inventory.ItemsQW[item.UniqueID] = (item.Weight or 1)
	count = count + 1
end

function Monarch.RegisterBench(bench)
    local class = bench.Class
    Monarch.Inventory.Benches[class] = bench
    Monarch.Inventory.Mixtures[class] = {}
end

function Monarch.RegisterMixture(mix)
    local class = mix.Class
    local bench = mix.Bench

    mix.NetworkID = countX

    Monarch.Inventory.Mixtures[bench][class] = mix
    Monarch.Inventory.MixturesRef[countX] = {bench, class}
    countX = countX + 1
end

function Monarch.Inventory.ClassToNetID(class)
    return Monarch.Inventory.ItemsRef[class]
end