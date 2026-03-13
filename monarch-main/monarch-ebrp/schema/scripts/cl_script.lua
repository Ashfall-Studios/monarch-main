do
	local TRACKS = {
		"amb/amb_song7.mp3",
		"amb/ambsong1.mp3",
		"amb/ambsong2.mp3",
		"amb/ambsong3.mp3",
		"amb/ambsong4.mp3",
		"amb/ambsong5.mp3",
		"amb/ambsong6.mp3",
	}

	local cvar_enabled = GetConVar("monarch_music_enabled")
	local cvar_volume = GetConVar("monarch_music_volume")	

	local PITCH_MIN, PITCH_MAX = 98, 104
	local FADE_IN, FADE_OUT = 2.0, 2.0
	local GAP_MIN, GAP_MAX = 6.0, 18.0
	local MAX_TRACK_LEN = 7 * 60

	local handle
	local nextAt = 0
	local current
	local ending = false
	local lastCheckTime = 0

	local function Stop(fade)
		if not handle then return end
		if fade and handle:IsPlaying() then
			ending = true
			handle:ChangeVolume(0, FADE_OUT)
			timer.Simple(FADE_OUT + 0.1, function()
				if handle then handle:Stop() end
				handle = nil
				ending = false
			end)
		else
			handle:Stop()
			handle = nil
		end
	end

	local function schedule(after)
		nextAt = CurTime() + (after or 0) + math.Rand(GAP_MIN, GAP_MAX)
	end

	local function play()
		if not cvar_enabled or not cvar_volume then return end
		local enabled = cvar_enabled:GetBool()
		local volume = math.Clamp(cvar_volume:GetFloat(), 0, 1)

		if not enabled then return end
		if not IsValid(LocalPlayer()) then return end
		if #TRACKS == 0 then return end

		if handle then
			Stop(false)
		end

		current = TRACKS[ math.random(#TRACKS) ]
		handle = CreateSound(LocalPlayer(), current)
		if not handle then
			schedule(5)
			return
		end
		local pitch = math.random(PITCH_MIN, PITCH_MAX)
		handle:PlayEx(0, pitch)
		handle:ChangeVolume(volume, FADE_IN)

		local dur = SoundDuration(current) or 0
		if dur <= 0 then dur = MAX_TRACK_LEN end
		dur = math.min(dur, MAX_TRACK_LEN)

		if dur > FADE_OUT + 0.5 then
			timer.Simple(dur - FADE_OUT, function()
				if handle and handle:IsPlaying() then
					Stop(true)
				end
			end)
		end

		schedule(dur)
	end

	local function bindCallbacks()

		cvar_enabled = cvar_enabled or GetConVar("monarch_music_enabled")
		cvar_volume = cvar_volume or GetConVar("monarch_music_volume")
		if not cvar_enabled or not cvar_volume then return end

		if cvars and cvars.RemoveChangeCallback then
			cvars.RemoveChangeCallback("monarch_music_enabled", "MonarchAmbienceEnabled")
			cvars.RemoveChangeCallback("monarch_music_volume", "MonarchAmbienceVolume")
		end

		if cvars and cvars.AddChangeCallback then
			cvars.AddChangeCallback("monarch_music_enabled", function(name, old, new)
				local enabled = tonumber(new) == 1
				if enabled then

					if not handle then
						play()
					else
						local vol = math.Clamp(cvar_volume:GetFloat(), 0, 1)
						handle:ChangeVolume(vol, FADE_IN)
					end
				else

					if handle then Stop(true) end
				end
			end, "MonarchAmbienceEnabled")

			cvars.AddChangeCallback("monarch_music_volume", function(name, old, new)
				local vol = math.Clamp(tonumber(new) or 0, 0, 1)
				if handle and handle:IsPlaying() then
					handle:ChangeVolume(vol, 0.5)
				end
			end, "MonarchAmbienceVolume")
		end
	end

	bindCallbacks()
	timer.Create("MonarchAmbienceBindCallbacks", 1.0, 1, bindCallbacks)

	hook.Add("Think", "Monarch_AmbienceCycleThink", function()

		if not cvar_enabled or not cvar_volume then return end

		local menuOpen = (IsValid(Monarch.splash) and Monarch.splash:IsVisible()) or 
		                 (IsValid(Monarch.MainMenu) and Monarch.MainMenu:IsVisible()) or
		                 (IsValid(Monarch.MainMenu) and IsValid(Monarch.MainMenu.CharacterSelect) and Monarch.MainMenu.CharacterSelect:IsVisible())

		if menuOpen then
			if handle then Stop(true) end
			return
		end

		if CurTime() >= lastCheckTime + 5 then
			lastCheckTime = CurTime()

			local enabled = cvar_enabled:GetBool()
			local volume = math.Clamp(cvar_volume:GetFloat(), 0, 1)

			if not enabled and handle then
				Stop(true)
				return
			end

			if enabled and handle and handle:IsPlaying() then
				handle:ChangeVolume(volume, 0.5)
			end
		end

		local enabled = cvar_enabled:GetBool()

		if not enabled then
			if handle then Stop(true) end
			return
		end

		if handle and not handle:IsPlaying() and not ending then
			handle = nil
		end

		if CurTime() >= nextAt and (not handle) then
			play()
		end
	end)

	hook.Add("InitPostEntity", "Monarch_AmbienceCycleInit", function()
		schedule(2)
	end)

	hook.Add("OnReloaded", "Monarch_AmbienceCycleReload", function()
		schedule(1)
	end)
end
