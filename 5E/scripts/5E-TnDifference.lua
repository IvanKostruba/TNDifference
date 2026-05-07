function init()
    ActionAttack.applyAttackTNDOrig = ActionAttack.applyAttack
	ActionAttack.applyAttack = TnDifference.applyAttackDecorator

	ActionSave.applySaveTNDOrig = ActionSave.applySave
	ActionSave.applySave = TnDifference.applySaveDecorator

	ActionCheck.onRollTNDOrig = ActionCheck.onRoll
	ActionCheck.onRoll = TnDifference.checkRollDecorator
	-- have to re-register since we replaced the registered function
	ActionsManager.registerResultHandler("check", ActionCheck.onRoll)
	ActionsManager.registerResultHandler("skill", ActionCheck.onRoll)
end
