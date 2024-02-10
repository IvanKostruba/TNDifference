function registerOptions()
	local numbers = "option_val_01|option_val_02|option_val_03|option_val_04|option_val_05|option_val_06|option_val_07|option_val_08|option_val_09|option_val_10"
	local zeroAndNumbers = "option_val_00|option_val_01|option_val_02|option_val_03|option_val_04|option_val_05|option_val_06|option_val_07|option_val_08|option_val_09|option_val_10"
	OptionsManager.registerOption2(
		"TND_show_attack_over", false, "option_header_TND", "option_label_TND_attacks_over", "option_entry_cycler",
		{labels=zeroAndNumbers, values="0|1|2|3|4|5|6|7|8|9|10", baselabel="option_val_none", baseval="none", default="5"}
	)
	OptionsManager.registerOption2(
		"TND_show_attack_under", false, "option_header_TND", "option_label_TND_attacks_under", "option_entry_cycler",
		{labels=numbers, values ="1|2|3|4|5|6|7|8|9|10", baselabel="option_val_none", baseval="none", default="none"}
	)
	OptionsManager.registerOption2(
		"TND_show_saves_over", false, "option_header_TND", "option_label_TND_saves_over", "option_entry_cycler",
		{labels=zeroAndNumbers, values ="0|1|2|3|4|5|6|7|8|9|10", baselabel="option_val_none", baseval="none", default="none"}
	)
	OptionsManager.registerOption2(
		"TND_show_saves_under", false, "option_header_TND", "option_label_TND_saves_under", "option_entry_cycler",
		{labels=numbers, values="1|2|3|4|5|6|7|8|9|10", baselabel="option_val_none", baseval="none", default="5"}
	)
	OptionsManager.registerOption2(
		"TND_show_skills_over", false, "option_header_TND", "option_label_TND_skills_over", "option_entry_cycler",
		{labels=zeroAndNumbers, values ="0|1|2|3|4|5|6|7|8|9|10", baselabel="option_val_none", baseval="none", default="none"}
	)
	OptionsManager.registerOption2(
		"TND_show_skills_under", false, "option_header_TND", "option_label_TND_skills_under", "option_entry_cycler",
		{labels=numbers, values ="1|2|3|4|5|6|7|8|9|10", baselabel="option_val_none", baseval="none", default="none"}
	)
	OptionsManager.registerOption2(
		"TND_show_multiples", false, "option_header_TND", "option_label_TND_multiples", "option_entry_cycler",
		{labels="option_val_on", values ="on", baselabel="option_val_off", baseval="off", default="off"}
	)
end

function onInit()
	registerOptions()

	ActionAttack.applyAttackTNDOrig = ActionAttack.applyAttack
	ActionAttack.applyAttack = applyAttackDecorator

	ActionSave.applySaveTNDOrig = ActionSave.applySave
	ActionSave.applySave = applySaveDecorator

	ActionCheck.onRollTNDOrig = ActionCheck.onRoll
	ActionCheck.onRoll = checkRollDecorator
	-- have to re-register since we replaced the registered function
	ActionsManager.registerResultHandler("check", ActionCheck.onRoll)

	ActionSkill.onRollTNDOrig = ActionSkill.onRoll
	ActionSkill.onRoll = skillRollDecorator
	ActionsManager.registerResultHandler("skill", ActionSkill.onRoll)
end

function onPreAttackDecorator(rSource, rTarget, rRoll, rMessage)
	-- Call the original onPreAttackResolve function
	ActionAttack.onPreAttackResolveTNDOrig(rSource, rTarget, rRoll, rMessage)
	if rRoll.nDefenseVal == nil then
		return
	end
	setTnDiffState(rSource, rTarget, rRoll.nTotal - rRoll.nDefenseVal)
end

function highlightAttacks()
	return not (OptionsManager.isOption("TND_show_attack_over", "none")
		and OptionsManager.isOption("TND_show_attack_under", "none"))
end

function highlightThreshold(sOpt)
	local sVal = OptionsManager.getOption(sOpt)
	if sVal ~= "none" then
		return tonumber(sVal)
	end
end

function excessMultiplierForDisplay(nDiff, nThreshold)
	if OptionsManager.getOption("TND_show_multiples") ~= "on" then return 1 end
	local m = math.floor(math.abs(nDiff) / nThreshold)
	if m > 3 then m = 3 end  -- currently we only have icons to highlight x3 excess
	return m
end

function prepareChatMessages(nDiff, sOverOpt, sUnderOpt, sTargetName)
	local text = ""
	local icon = ""
	local overThreshold = highlightThreshold(sOverOpt)
	local underThreshold = highlightThreshold(sUnderOpt)
	if overThreshold and nDiff >= overThreshold then
		local m = excessMultiplierForDisplay(nDiff, overThreshold)
		text = string.format("OVER %s BY [%d] OR MORE", sTargetName, overThreshold * m)
		icon = string.format("over_tn_%d", m)
	elseif underThreshold and nDiff <= -underThreshold then
		local m = excessMultiplierForDisplay(nDiff, underThreshold)
		text = string.format("UNDER %s BY [%d] OR MORE", sTargetName, underThreshold * m)
		icon = string.format("under_tn_%d", m)
	end
	if text == "" then return nil, nil end
	local msgShort = { font = "msgfont", ["text"] = text, ["icon"] = icon}
	local msgLong = { font = "msgfont", ["text"] = text, ["icon"] = icon}
	-- typically the short one is for players and the long one is fo DM
	-- but for now they are identical.
	return msgShort, msgLong
end

function applyAttackDecorator(rSource, rTarget, rRoll)
	-- call the original applyAttack method
	ActionAttack.applyAttackTNDOrig(rSource, rTarget, rRoll)
	-- rRoll named after the same parameter in ActionAttack,
	-- but it is actually the action itself, not a die roll data.
	local nDiff
	if rRoll.nDefenseVal ~= nil then
		nDiff = rRoll.nTotal - rRoll.nDefenseVal
	end
	if highlightAttacks() and nDiff ~= nil then
		local msgShort, msgLong = prepareChatMessages(
			nDiff, "TND_show_attack_over", "TND_show_attack_under", "AC")
		if msgShort ~= nil and msgLong ~= nil then
			ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort)
		end
	end
end

function highlightSaves()
	return not (OptionsManager.isOption("TND_show_saves_over", "none")
		and OptionsManager.isOption("TND_show_saves_under", "none"))
end

function applySaveDecorator(rSource, rOrigin, rAction, sUser)
	-- call the original applySave method
	ActionSave.applySaveTNDOrig(rSource, rOrigin, rAction, sUser)

	-- saves handler replaces nil with 0
	if highlightSaves() and rAction.nTarget ~= 0 then
		local msgShort, msgLong = prepareChatMessages(
			rAction.nTotal - rAction.nTarget, "TND_show_saves_over", "TND_show_saves_under", "DC")
		if msgShort ~= nil and msgLong ~= nil then
			ActionsManager.outputResult(rAction.bSecret, rSource, rOrigin, msgLong, msgShort)
		end
	end
end

function highlightSkills()
	return not (OptionsManager.isOption("TND_show_skills_over", "none")
		and OptionsManager.isOption("TND_show_skills_under", "none"))
end

function checkRollDecorator(rSource, rTarget, rRoll)
	-- call the original onRoll method
	ActionCheck.onRollTNDOrig(rSource, rTarget, rRoll)

	if highlightSkills() and rRoll.nTarget ~= nil and rRoll.nTarget ~= 0 then
		local rollTotal = ActionsManager.total(rRoll);
		local msgShort, _ = prepareChatMessages(
			rollTotal - rRoll.nTarget, "TND_show_skills_over", "TND_show_skills_under", "DC")
		if msgShort ~= nil then
			Comm.deliverChatMessage(msgShort)
		end
	end
end

function skillRollDecorator(rSource, rTarget, rRoll)
	-- call the original onRoll method
	ActionSkill.onRollTNDOrig(rSource, rTarget, rRoll)

	if highlightSkills() and rRoll.nTarget ~= nil and rRoll.nTarget ~= 0 then
		local rollTotal = ActionsManager.total(rRoll);
		local msgShort, _ = prepareChatMessages(
			rollTotal - rRoll.nTarget, "TND_show_skills_over", "TND_show_skills_under", "DC")
		if msgShort ~= nil then
			Comm.deliverChatMessage(msgShort)
		end
	end
end
