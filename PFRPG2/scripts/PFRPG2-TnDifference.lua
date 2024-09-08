function init()
	-- PFRPG2 version replaces a different frunction campared to 5E.
    ActionAttack.onAttackTNDOrig = ActionAttack.onAttack
	ActionAttack.onAttack = onAttackDecorator
	-- have to re-register since we replaced the registered function
	ActionsManager.registerResultHandler("attack", ActionAttack.onAttack);

	ActionSave.applySaveTNDOrig = ActionSave.applySave
	ActionSave.applySave = TnDifference.applySaveDecorator

	ActionAbility.onRollTNDOrig = ActionAbility.onRoll
	ActionAbility.onRoll = TnDifference.checkRollDecorator
	-- have to re-register since we replaced the registered function
	ActionsManager.registerResultHandler("ability", ActionAbility.onRoll)

	ActionSkill.onRollTNDOrig = ActionSkill.onRoll
	ActionSkill.onRoll = TnDifference.skillRollDecorator
	ActionsManager.registerResultHandler("skill", ActionSkill.onRoll)
end

function onAttackDecorator(rSource, rTarget, rRoll)
	-- call the original onAttack method
	ActionAttack.onAttackTNDOrig(rSource, rTarget, rRoll)
	if not TnDifference.highlightAttacks() then
		return
	end
	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus;
	nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, _, _ = ActorManager2.getDefenseValue(rSource, rTarget, rRoll);
	-- rRoll named after the same parameter in ActionAttack,
	-- but it is actually the action itself, not a die roll data.
	local nDiff
	if nDefenseVal then
		nDiff = ActionsManager.total(rRoll) + nAtkEffectsBonus - nDefenseVal - nDefEffectsBonus
	end
	if nDiff ~= nil then
		local msgShort, msgLong = TnDifference.prepareChatMessages(
			nDiff, "TND_show_attack_over", "TND_show_attack_under", "AC")
		if msgShort ~= nil and msgLong ~= nil then
			ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort)
		end
	end
end
