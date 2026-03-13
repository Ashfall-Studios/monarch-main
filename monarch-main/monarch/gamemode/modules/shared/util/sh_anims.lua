Config = Config or {}

Monarch.Anim = Monarch.Anim or {}
Monarch.Anim.citizen_male = {
    normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	ar2 = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE,
	vehicle = {
		["prop_vehicle_prisoner_pod"] = {"podpose", Vector(-3, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_BUSY_SIT_CHAIR, Vector(14, 0, -14)},
		["prop_vehicle_airboat"] = {ACT_BUSY_SIT_CHAIR, Vector(8, 0, -20)},
		chair = {ACT_BUSY_SIT_CHAIR, Vector(1, 0, -23)}
	},
}

Monarch.Anim.citizen_female = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        attack = ACT_RANGE_ATTACK_THROW
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        attack = ACT_MELEE_ATTACK_SWING
    },
    glide = ACT_GLIDE,
    vehicle = Monarch.Anim.citizen_male.vehicle 
}

Monarch.Anim.metrocop = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_GESTURE_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE}
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_COMBINE_THROW_GRENADE
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_MELEE_ATTACK_SWING_GESTURE
    },
    glide = ACT_GLIDE,
    vehicle = {
        chair = {ACT_COVER_PISTOL_LOW, Vector(5, 0, -5)},
        ["prop_vehicle_airboat"] = {ACT_COVER_PISTOL_LOW, Vector(10, 0, 0)},
        ["prop_vehicle_jeep"] = {ACT_COVER_PISTOL_LOW, Vector(18, -2, 4)},
        ["prop_vehicle_prisoner_pod"] = {ACT_IDLE, Vector(-4, -0.5, 0)}
    }
}
Monarch.Anim.overwatch = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkeasy_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET}
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkeasy_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
        attack = ACT_MELEE_ATTACK_SWING_GESTURE
    },
    glide = ACT_GLIDE,
    vehicle = {
        chair = {ACT_CROUCHIDLE, Vector(5, 0, -5)},
        ["prop_vehicle_airboat"] = {ACT_CROUCHIDLE, Vector(10, 0, 0)},
        ["prop_vehicle_jeep"] = {ACT_CROUCHIDLE, Vector(18, -2, 4)},
        ["prop_vehicle_prisoner_pod"] = {"idle_unarmed", Vector(-4, -0.5, 0)}
    }
}
Monarch.Anim.vort = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN}
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN}
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN}
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "sweep_idle"},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK, "walk_all_holdbroom"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, "walk_all_holdbroom"}
    },
    glide = ACT_GLIDE
}
Monarch.Anim.player = {
    normal = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN
    },
    passive = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE
    },

    pistol = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PISTOL,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_PISTOL,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_PISTOL,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_HL2MP_GESTURE_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SMG1,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_SMG1,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_SMG1,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_HL2MP_GESTURE_RELOAD_SMG1
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_AR2,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_AR2,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_AR2,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
        reload = ACT_HL2MP_GESTURE_RELOAD_AR2
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SHOTGUN,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_SHOTGUN,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_SHOTGUN,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN,
        reload = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN
    },
    crossbow = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_CROSSBOW,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_CROSSBOW,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_CROSSBOW,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW,
        reload = ACT_HL2MP_GESTURE_RELOAD_CROSSBOW
    },
    rpg = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_RPG,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_RPG,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_RPG,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_GRENADE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_GRENADE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_GRENADE,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE
    },
    melee = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_MELEE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_MELEE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_MELEE,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
    },
    melee2 = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_MELEE2,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_MELEE2,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_MELEE2,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2
    },
    physgun = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PHYSGUN,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_PHYSGUN,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_PHYSGUN
    },
    fist = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_FIST,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_FIST,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_FIST,
        attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST
    }
}

local translations = translations or {}

function Monarch.Anim.SetModelClass(model, class)
    if not Monarch.Anim[class] then
        error("'"..tostring(class).."' is not a valid animation class!")
    end

    translations[model:lower()] = class
end

local stringLower = string.lower
local stringFind = string.find

function Monarch.Anim.GetModelClass(model)
	model = string.lower(model)
	local class = translations[model]

	if (!class and string.find(model, "/player")) then
		return "player"
	end

	class = class or "citizen_male"

	if (class == "citizen_male" and (
		string.find(model, "female") or
		string.find(model, "alyx") or
		string.find(model, "mossman"))) then
		class = "citizen_female"
	end

	return class
end

Monarch.Anim.SetModelClass("models/dpfilms/metropolice/hdpolice.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/dpfilms/metropolice/civil_medic.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/dpfilms/metropolice/hl2beta_police.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/dpfilms/metropolice/retrocop.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/dpfilms/metropolice/elite_police.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/dpfilms/metropolice/policetrench.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/dpfilms/metropolice/hl2concept.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/wn7new/metropolice/male_08.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/dpfilms/metropolice/police_fragger.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/synapse/hl_a/civil_protection/civil_protection.mdl", "metrocop")

Monarch.Anim.SetModelClass("models/jq/hlvr/characters/combine_soldier/combine_soldier_new_content_npc.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/combine_soldier_prisonguard.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/wn/ota_shotgunner.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/wn/ota_skylegion.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/wn/ota_soldier.mdl", "overwatch")

Monarch.Anim.SetModelClass("models/vortigaunt.mdl", "vort")
Monarch.Anim.SetModelClass("models/vortigaunt_blue.mdl", "vort")
Monarch.Anim.SetModelClass("models/vortigaunt_doctor.mdl", "vort")
Monarch.Anim.SetModelClass("models/vortigaunt_slave.mdl", "vort")
Monarch.Anim.SetModelClass("models/vortiblue1.mdl", "vort")

local mdls = Config.CharacterModels or {}

for k,mdl in pairs(mdls) do
    Monarch.Anim.SetModelClass(mdl, "player")
end

local ebrp_models = {

	"models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_05.mdl", 
	"models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_06.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/enlisted/stasi_enlisted_staff_service_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/enlisted/stasi_enlisted_staff_service_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/enlisted/stasi_enlisted_staff_service_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/enlisted/stasi_enlisted_staff_service_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/enlisted/stasi_enlisted_staff_service_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/enlisted/stasi_enlisted_staff_service_06.mdl",

	"models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_06.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/officer/stasi_officer_staff_service_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/officer/stasi_officer_staff_service_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/officer/stasi_officer_staff_service_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/officer/stasi_officer_staff_service_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/officer/stasi_officer_staff_service_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/officer/stasi_officer_staff_service_06.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/officer/stasi_officer_social_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/officer/stasi_officer_social_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/officer/stasi_officer_social_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/officer/stasi_officer_social_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/officer/stasi_officer_social_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/officer/stasi_officer_social_06.mdl",

	"models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_06.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_06.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/general/stasi_general_staff_service_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/general/stasi_general_staff_service_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/general/stasi_general_staff_service_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/general/stasi_general_staff_service_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/general/stasi_general_staff_service_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/staffservice/general/stasi_general_staff_service_06.mdl",

	"models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_01.mdl",
	"models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_02.mdl",
	"models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_03.mdl",
	"models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
	"models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_05.mdl",
	"models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_06.mdl"

}

for _,model in pairs(ebrp_models) do
	Monarch.Anim.SetModelClass(model, "player")
end

Monarch.Anim.SetModelClass("models/humans/group01/male_01.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_02.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_03.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_04.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_05.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_06.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_07.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_08.mdl", "citizen_male")
Monarch.Anim.SetModelClass("models/humans/group01/male_09.mdl", "citizen_male")

Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male01.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male02.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male03.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male04.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male05.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male06.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male07.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male08.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/male09.mdl", "player")

Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_01.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_02.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_03.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_05.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_06.mdl", "player")

Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_01.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_02.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_03.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_05.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_06.mdl", "player")

Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_01.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_02.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_03.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_04.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_05.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_06.mdl", "player")

Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_01.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_02.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_03.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_05.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_06.mdl", "player")

Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_01.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_02.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_03.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_05.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_06.mdl", "player")

Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_01.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_02.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_03.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_04.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_05.mdl", "player")
Monarch.Anim.SetModelClass("models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_06.mdl", "player")

Monarch.Anim.SetModelClass("models/hts/comradebear/pm0v3/player/rkka/infantry/co/m43_s1_05.mdl", "player")
Monarch.Anim.SetModelClass("models/hts/comradebear/pm0v3/player/rkka/infantry/nco/m35_1941_s1_04.mdl", "player")
Monarch.Anim.SetModelClass("models/hts/comradebear/pm0v3/player/rkka/infantry/en/m43_s1_04.mdl", "player")

Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_01.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_02.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_03.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_04.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_05.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_06.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_07.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_08.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_09.mdl", "player")
Monarch.Anim.SetModelClass("models/willardnetworks_custom/citizens/female_10.mdl", "player")

-- Half life 2 RP
Monarch.Anim.SetModelClass("models/synapse/combine/civil_protection.mdl", "metrocop")
Monarch.Anim.SetModelClass("models/synapse/combine/combine_soldier_h.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/synapse/combine/combine_grunt.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/synapse/hl_a/combine_grunt/npc/combine_grunt.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/synapse/hl_a/combine_commander/npc/combine_commander.mdl", "player")
Monarch.Anim.SetModelClass("models/wn/ordinal.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/overwatchupgrades/newordinal.mdl", "overwatch")
Monarch.Anim.SetModelClass("models/synapse/combine/combine_soldier_elite_h.mdl", "player")
Monarch.Anim.SetModelClass("models/hlvr/characters/worker/npc/worker_citizen.mdl", "player")

hook.Run("LoadAnimationClasses")

local meta = FindMetaTable("Player")

local MONARCH_ACTION_DEBUG = false

local function ActionDebug(ply, msg, ...)
    if not SERVER or not MONARCH_ACTION_DEBUG then return end

    local prefix = "[MonarchActionDebug]"
    local who = "[unknown]"

    if IsValid(ply) and ply:IsPlayer() then
        who = string.format("[%s|%s|team:%s]", tostring(ply:Nick()), tostring(ply:SteamID()), tostring(ply:Team()))
    end

    local formatted = string.format(tostring(msg or ""), ...)
    print(string.format("%s %s %s", prefix, who, formatted))
end

local ALWAYS_RAISED = {}
ALWAYS_RAISED["weapon_physgun"] = true
ALWAYS_RAISED["gmod_tool"] = true
ALWAYS_RAISED["weapon_braaains"] = true
ALWAYS_RAISED["weapon_frag"] = true
ALWAYS_RAISED["monarch_hands"] = true

local ALWAYS_LOWERED = {}
ALWAYS_LOWERED["tfa_melee_stunstick"] = true

	function meta:IsWeaponRaised()
		local weapon = self.GetActiveWeapon(self)

        if IsValid(weapon) then
			if weapon.IsAlwaysRaised or ALWAYS_RAISED[weapon.GetClass(weapon)] then
				return true
			elseif weapon.IsAlwaysLowered or ALWAYS_LOWERED[weapon.GetClass(weapon)] then
				return false
			end
		end

        if weapon:IsTFA() then
            if !weapon:IsSafety() then return true else return false end
        end

		return self.GetSyncVar(self, SYNC_WEPRAISED, false)
	end
do

    function meta:ForceSequence(sequence, callback, time, noFreeze)
        hook.Run("OnPlayerEnterSequence", self, sequence, callback, time, noFreeze)

        local requestedSequence = sequence
        ActionDebug(self, "ForceSequence request seq='%s' time=%s noFreeze=%s", tostring(requestedSequence), tostring(time), tostring(noFreeze))

        if not sequence then
            ActionDebug(self, "ForceSequence reset requested (nil sequence)")
            net.Start("MonarchSeqSet")
            net.WriteEntity(self)
            net.WriteBool(true)
            net.WriteUInt(0, 16)
            net.Broadcast()
            return
        end

        local sequence = self:LookupSequence(sequence)
        ActionDebug(self, "LookupSequence('%s') => %s", tostring(requestedSequence), tostring(sequence))

        if sequence and sequence >= 0 then
            time = time or self:SequenceDuration(sequence)
            ActionDebug(self, "ForceSequence accepted sequenceId=%s duration=%s", tostring(sequence), tostring(time))

            self.MonarchSeqCallback = callback
            self.MonarchForceSeq = sequence

            if not noFreeze then
                self:SetMoveType(MOVETYPE_NONE)
            end

            if time > 0 then
                timer.Create("MonarchSeq"..self:EntIndex(), time, 1, function()
                    if IsValid(self) then
                        self:leaveSequence()
                    end
                end)
            end

            net.Start("MonarchSeqSet")
            net.WriteEntity(self)
            net.WriteBool(false)
            net.WriteUInt(sequence, 16)
            net.Broadcast()

            return time
        end

        ActionDebug(self, "ForceSequence rejected invalid sequence for '%s'", tostring(requestedSequence))

        return false
    end

    function meta:leaveSequence()
        hook.Run("OnPlayerLeaveSequence", self)

        net.Start("MonarchSeqSet")
        net.WriteEntity(self)
        net.WriteBool(true)
        net.WriteUInt(0, 16)
        net.Broadcast()

        self:SetMoveType(MOVETYPE_WALK)
        self.MonarchForceSeq = nil 

        if self.MonarchSeqCallback then 
            self:MonarchSeqCallback() 
        end
    end
    if SERVER then
		util.AddNetworkString("MonarchSeqSet")

		function meta:SetWeaponRaised(state)
			self:SetSyncVar(SYNC_WEPRAISED, state, true)

			local weapon = self:GetActiveWeapon()

			if IsValid(weapon) then
				weapon:SetNextPrimaryFire(CurTime() + 1)
				weapon:SetNextSecondaryFire(CurTime() + 1)

				if weapon.OnLowered then
					weapon.OnLowered(weapon)
				end
			end
		end

		function meta:ToggleWeaponRaised()
			self:SetWeaponRaised(!self:IsWeaponRaised())
		end
	end

	if CLIENT then
        local function ShouldUseTauntThirdPerson()
            local thirdPersonCvar = GetConVar("monarch_thirdperson")
            return not (thirdPersonCvar and thirdPersonCvar:GetBool())
        end

		net.Receive("MonarchSeqSet", function()
			local ent = net.ReadEntity()
			local reset = net.ReadBool()
			local sequence = net.ReadUInt(16)

			if IsValid(ent) then
				if reset then
                    ent.impulseForceSeq = nil
					ent.ForceSeq = nil
                    ent.MonarchForceSeq = nil

                    if ent == LocalPlayer() then
                        ent.MonarchTauntThirdPerson = false
                    end
					return
				end

                ent.impulseForceSeq = sequence
				ent:SetCycle(0)
				ent:SetPlaybackRate(1)
				ent.ForceSeq = sequence
                ent.MonarchForceSeq = sequence
                ent:ResetSequence(sequence)

                if ent == LocalPlayer() then
                    ent.MonarchTauntThirdPerson = ShouldUseTauntThirdPerson()
                end
			end
		end)
	end
end

HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "normal"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

PLAYER_HOLDTYPE_TRANSLATOR = {}
PLAYER_HOLDTYPE_TRANSLATOR[""] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["fist"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["pistol"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["grenade"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["melee"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["slam"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["melee2"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["passive"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["knife"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["duel"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["bugbait"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["revolver"] = "passive"
PLAYER_HOLDTYPE_TRANSLATOR["normal"] = "normal"

local getModelClass = Monarch.Anim.GetModelClass
local IsValid = IsValid
local string  = string
local type = type

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR

function GM:TranslateActivity(ply, act)
    local model = string.lower(ply:GetModel())
    local class = Monarch.Anim.GetModelClass(model) or "player"
    local weapon = ply:GetActiveWeapon()

    if class == "player" then
        local holdType = "normal"
        if IsValid(weapon) then
            holdType = weapon.HoldType or weapon:GetHoldType() or "normal"
            
        end

        if ply:IsWeaponRaised() then
            holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "normal"
        else
            holdType = "passive"
        end

        if not ply:IsWeaponRaised() or not IsValid(weapon) then
            holdType = "passive"
        end

        return self.BaseClass:TranslateActivity(ply, act)
    end

    local animTree = Monarch.Anim[class]

    if animTree then
        local subClass = "normal"
        if ply:InVehicle() then
            local vehicle = ply:GetVehicle()
            local vehicleClass = "chair"

            if animTree.vehicle and animTree.vehicle[vehicleClass] then
                local vehicleAct = animTree.vehicle[vehicleClass][1]
                local fixvec = animTree.vehicle[vehicleClass][2]

                if fixvec then
                    ply:SetLocalPos(fixvec)
                end

                if type(vehicleAct) == "string" then
                    ply.CalcSeqOverride = ply:LookupSequence(vehicleAct)
                    return
                else
                    return vehicleAct
                end
            else
                local fallbackAct = animTree.normal[ACT_MP_CROUCH_IDLE]
                if fallbackAct and fallbackAct[1] then
                    if type(fallbackAct[1]) == "string" then
                        ply.CalcSeqOverride = ply:LookupSequence(fallbackAct[1])
                    else
                        return fallbackAct[1]
                    end
                end
                return
            end
        elseif ply:OnGround() then
            ply:ManipulateBonePosition(0, vector_origin)

            if IsValid(weapon) then
                subClass = weapon.HoldType or weapon:GetHoldType()
                subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass
            end

            if animTree[subClass] and animTree[subClass][act] then
                local animData = animTree[subClass][act]

                if type(animData) == "table" and #animData >= 2 then

                    local isRaised = ply:IsWeaponRaised()
                    local selectedAct = animData[isRaised and 2 or 1]

                    if type(selectedAct) == "string" then
                        ply.CalcSeqOverride = ply:LookupSequence(selectedAct)
                        return
                    end
                    return selectedAct
                else

                    if type(animData) == "string" then
                        ply.CalcSeqOverride = ply:LookupSequence(animData)
                        return
                    elseif type(animData) == "number" then
                        return animData
                    end
                end
            end
        elseif animTree.glide then
            return animTree.glide
        end
    end

    return self.BaseClass:TranslateActivity(ply, act)
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle

function GM:CalcMainActivity(ply, velocity)
    local eyeAngles = ply:EyeAngles()
    local yaw = vectorAngle(velocity)[2]
    local normalized = normalizeAngle(yaw - eyeAngles[2])

    ply:SetPoseParameter("move_yaw", normalized)

    if CLIENT then
        ply:SetIK(false)
    end

    local oldSeqOverride = ply.CalcSeqOverride
    local seqIdeal, seqOverride = self.BaseClass:CalcMainActivity(ply, velocity)

    return seqIdeal, ply.MonarchForceSeq or ply.ForceSeq or ply.impulseForceSeq or oldSeqOverride or ply.CalcSeqOverride
end

function GM:DoAnimationEvent(ply, event, data)
    local model = ply:GetModel():lower()
    local class = Monarch.Anim.GetModelClass(model)

    if class == "player" then
        return self.BaseClass:DoAnimationEvent(ply, event, data)
    else
        local weapon = ply:GetActiveWeapon()

        if IsValid(weapon) then
            local holdType = weapon.HoldType or weapon:GetHoldType()
            holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

            local animation = Monarch.Anim[class][holdType]

            if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
                ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)
                return ACT_VM_PRIMARYATTACK
            elseif event == PLAYERANIMEVENT_ATTACK_SECONDARY then
                ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)
                return ACT_VM_SECONDARYATTACK
            elseif event == PLAYERANIMEVENT_RELOAD then
                ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.reload or ACT_GESTURE_RELOAD_SMG1, true)
                return ACT_INVALID
            elseif event == PLAYERANIMEVENT_JUMP then
                ply.m_bJumping = true
                ply.m_bFirstJumpFrame = true
                ply.m_flJumpStartTime = CurTime()
                ply:AnimRestartMainSequence()
                return ACT_INVALID
            elseif event == PLAYERANIMEVENT_CANCEL_RELOAD then
                ply:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)
                return ACT_INVALID
            end
        end
    end
    return ACT_INVALID
end



concommand.Add("monarch_toggle_weapon", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then return end
    if ALWAYS_RAISED[weapon:GetClass()] or weapon.IsAlwaysRaised then return end
    if ALWAYS_LOWERED[weapon:GetClass()] or weapon.IsAlwaysLowered then return end
    ply:ToggleWeaponRaised()
end)

function meta:ToggleWeaponRaised()
    self:SetWeaponRaised(!self:IsWeaponRaised())
end
