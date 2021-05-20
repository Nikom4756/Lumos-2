/obj/machinery/mineral/bluespace_miner
	name = "bluespace mining machine"
	desc = "A machine that uses the magic of Bluespace to slowly generate materials and add them to a linked ore silo."
	icon = 'modular_sand/icons/obj/machines/mining_machines.dmi'
	icon_state = "bsminer"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/bluespace_miner
	layer = BELOW_OBJ_LAYER
	var/list/ore_rates = list(/datum/material/iron = 0.3, /datum/material/glass = 0.3, /datum/material/plasma = 0.1,  /datum/material/silver = 0.1, /datum/material/gold = 0.05, /datum/material/titanium = 0.05, /datum/material/uranium = 0.05, /datum/material/diamond = 0.02)
	var/datum/component/remote_materials/materials
	var/multiplier = 0 //Multiplier by tier, has been made fair and everything

/obj/machinery/mineral/bluespace_miner/Initialize(mapload)
	. = ..()
	materials = AddComponent(/datum/component/remote_materials, "bsm", mapload)

/obj/machinery/mineral/bluespace_miner/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>A small screen on the machine reads, \"Efficiency at [multiplier * 100]%\"</span>"
		if(multiplier >= 5)
			. += "<span class='notice'>Bluespace generation is active.</span>"

/obj/machinery/mineral/bluespace_miner/RefreshParts()
	multiplier = 0
	var/stock_amt = 0
	for(var/obj/item/stock_parts/L in component_parts)
		if(!istype(L))
			continue
		multiplier += L.rating
		stock_amt++
	multiplier /= stock_amt
	if(multiplier >= 5)
		ore_rates += list(/datum/material/bluespace = 0.01)
	else
		ore_rates -= ore_rates["bluespace crystal"]

/obj/machinery/mineral/bluespace_miner/Destroy()
	materials = null
	return ..()

/obj/machinery/mineral/bluespace_miner/multitool_act(mob/living/user, obj/item/M)
	if(M.tool_behaviour == TOOL_MULTITOOL)
		if(!M.buffer || !istype(M.buffer, /obj/machinery/ore_silo))
			to_chat(user, "<span class='warning'>You need to multitool the ore silo first.</span>")
			return FALSE

/obj/machinery/mineral/bluespace_miner/examine(mob/user)
	. = ..()
	if(!materials?.silo)
		. += "<span class='notice'>No ore silo connected. Use a multi-tool to link an ore silo to this machine.</span>"
	else if(materials?.on_hold())
		. += "<span class='warning'>Ore silo access is on hold, please contact the quartermaster.</span>"

/obj/machinery/mineral/bluespace_miner/process()
	update_icon_state()
	if(!materials?.silo || materials?.on_hold())
		return
	var/datum/component/material_container/mat_container = materials.mat_container
	if(!mat_container || panel_open || !powered())
		return
	var/datum/material/ore = pick(ore_rates)
	mat_container.bsm_insert(((ore_rates[ore] * 1000) * multiplier * 0.5), ore)

/datum/component/material_container/proc/bsm_insert(amt, datum/material/mat)
	if(!istype(mat))
		mat = SSmaterials.GetMaterialRef(mat)
	if(amt > 0 && has_space(amt))
		var/total_amount_saved = total_amount
		if(mat)
			materials[mat] += amt
			total_amount += amt
		else
			for(var/i in materials)
				materials[i] += amt
				total_amount += amt
		return (total_amount - total_amount_saved)
	return FALSE

/obj/machinery/mineral/bluespace_miner/update_icon_state()
	if(!powered())
		if(!panel_open)
			icon_state = "bsminer-unpowered"
		else
			icon_state = "bsminer-unpowered-maintenance"
	else
		if(!panel_open)
			icon_state = "bsminer"
		else
			icon_state = "bsminer-maintenance"

/obj/machinery/mineral/bluespace_miner/crowbar_act(mob/living/user, obj/item/I)
	. = ..()
	if(default_deconstruction_crowbar(I, FALSE))
		return TRUE

/obj/machinery/mineral/bluespace_miner/screwdriver_act(mob/living/user, obj/item/I)
	. = TRUE
	if(..())
		return
	if(!I.tool_behaviour == TOOL_SCREWDRIVER)
		return
	if(!state_open)
		if(powered())
			if(default_deconstruction_screwdriver(user, "bsminer-maintenance", "bsminer", I))
				return TRUE
		else if(!powered())
			if(default_deconstruction_screwdriver(user, "bsminer-unpowered-maintenance", "bsminer-unpowered", I))
				return TRUE
	return FALSE
