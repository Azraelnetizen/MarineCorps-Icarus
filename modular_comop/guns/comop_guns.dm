////////////////// TRIPMINE

/obj/item/explosive/mine/tripmine
	name = "\improper IMBEL Tripmine"
	desc = "The IMBEL Tripmine is a directional laser-oriented smart mine of the FECB. It generates a laser that when touched, it explodes."
	icon = 'modular_comop/guns/icons/tripmine.dmi'
	icon_state = "tripmine"

	var/datum/beam/laser_beam
	var/turf/target

/obj/item/explosive/mine/tripmine/deploy_mine(mob/user, turf/target_turf)

	if(!hard_iff_lock && user)
		iff_signal = user.faction

	if(target_turf && target_turf.density)
		forceMove(target_turf)
		anchored = TRUE
	else
		anchored = FALSE

	cause_data = create_cause_data(initial(name), user)
	playsound(loc, 'modular_comop/guns/sounds/tripmine.ogg', 25, FALSE)
	if(user)
		user.drop_inv_item_on_ground(src)
	setDir(user ? user.dir : dir) //The direction it is planted in is the direction the user faces at that time
	activate_sensors()
	create_laser()
	update_icon()

/obj/item/explosive/mine/tripmine/proc/create_laser()
	var/turf/target_turf = get_step(src, dir)
	var/max_dist = 3
	for(var/i = 1 to max_dist)
		var/turf/next_turf = get_step(target_turf, dir)
		if(!next_turf || next_turf.density)
			break
		target_turf = next_turf
	laser_beam = beam(target_turf, icon_state="laser_beam", icon='icons/effects/beam.dmi', beam_type=/obj/effect/ebeam/tripmine, maxdistance=max_dist)
	for(var/obj/effect/ebeam/tripmine/T in laser_beam.elements)
		T.light_system = STATIC_LIGHT
		T.light_power = 1
		T.light_range = 1
		T.light_color = "#880808"
		T.tripmine_owner = src
		T.static_update_light()

	// Update visibility based on smoke presence
	for(var/obj/effect/ebeam/tripmine/T in laser_beam.elements)
		T.update_visibility()

/obj/item/explosive/mine/tripmine/prime()
	. = ..()
	if (laser_beam)
		qdel(laser_beam)

/obj/effect/ebeam/tripmine
	var/obj/item/explosive/mine/tripmine/tripmine_owner

	// New proc to update visibility based on player proximity
/obj/effect/ebeam/tripmine/proc/update_visibility()
	var/player_nearby = FALSE
	for(var/mob/living/carbon/human/H in view(1, src))
		player_nearby = TRUE
		break
	var/smoke_nearby = FALSE
	for(var/obj/effect/particle_effect/smoke/S in view(2, src))
		smoke_nearby = TRUE
		break
	// Set alpha based on player proximity or smoke presence
	alpha = (player_nearby || smoke_nearby) ? 255 : 0
	// Schedule next check in 5 seconds
	spawn(5)
		update_visibility()

/obj/effect/ebeam/tripmine/Crossed(atom/movable/AM)
	. = ..()
	if(tripmine_owner && !QDELETED(tripmine_owner))
		tripmine_owner.prime()
