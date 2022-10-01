--  ___FILENAME___
--  ___PACKAGENAME___

--  Created by ___FULLUSERNAME___ on ___DATE___.
--  ___COPYRIGHT___

script ___PACKAGENAMEASIDENTIFIER___
	property parent : class "AMBundleAction"
	
	on runWithInput_fromAction_error_(input, anAction, errorRef)
		-- Add your code here, returning the data to be passed to the next action.
		
		return input
	end runWithInput_fromAction_error_
	
end script
