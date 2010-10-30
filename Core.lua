local addonName, addonTable = ...

CombustionJunction = CreateFrame("frame")

-----------------------------
--  Debugging stuff        --
-----------------------------

local debugf = tekDebug and tekDebug:GetFrame("CombustionJunction")
local function Debug(...)
	if debugf then
		debugf:AddMessage(string.join(", ", ...))
	end
end

-----------------------------
--      Event Handler      --
-----------------------------

CombustionJunction:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)
CombustionJunction:RegisterEvent("ADDON_LOADED")
function CombustionJunction:Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99CombustionJunction|r:", ...)) end


function CombustionJunction:ADDON_LOADED(addon)
	if addon:lower() ~= "combustionjunction" then return end

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self.spells = { LIVING_BOMB=44457, IGNITE_RANK_3=12846, PYROBLAST=92315, FROSTFIRE_BOLT=44614, IGNITE_RANK_2=11120, IGNITE_RANK_1=11119 }

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end

function CombustionJunction:reproject()
	local total_dmg = 0
	target = UnitGUID("target")
	for k,v in pairs(self.spells) do
		total_dmg =  (self.last_tick[v][target] and
						total_dmg + self.last_tick[v][target]) or
					total_dmg
	end
	self.current_projection = total_dmg
	self:redisplay()
end

function CombustionJunction:redisplay()
	self.projection_display:SetText(tostring(self.current_projection))
end

function CombustionJunction:PLAYER_REGEN_ENABLED()
	for k,v in pairs(self.last_tick) do
		self.last_tick[k] = {}
	end
	self.current_projection = 0
	self:redisplay()
end

function CombustionJunction:COMBAT_LOG_EVENT_UNFILTERED(...)
	local timest, event, src, _, from_flags, target, _, target_flags, spellID, _, _, amount, _, _, _, _, _, is_crit, _, _ = ...

	if src ~= self.bob_kelso or (event ~= "SPELL_PERIODIC_DAMAGE" and event ~= "SPELL_AURA_REMOVED")
	then
			return
	end -- Who has two thumbs, doesn't give a crap, & a squeaky voice?
		-- This guy.
		-- (I added the squeaky voice to keep it fresh)
	for k,v in pairs(self.spells) do
		if spellID == v then
			if event == "SPELL_AURA_REMOVED" then
				self.last_tick[v][target] = 0
			elseif not is_crit then
				self.last_tick[v][target] = amount/1.5
			else
				self.last_tick[v][target] = amount
			end
			self:reproject()
			break
		end
	end

end


function CombustionJunction:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")

	Debug("When I feel like heavy metal! When I'm pissed I have it all!")
	if UnitName("player")=="Xbalanque" then
		Debug("You're Xbalanque! Adding balance dots so you can test " ..
				"basic aspects of the addon.")
		self.spells.LANGUISH = 71023
		self.spells.INSECT_SWARM = 5570
		self.spells.SUNFIRE = 93402
		self.spells.MOONFIRE = 8921
	end

	self.bob_kelso = UnitGUID("player")
	self.last_tick = {}
	for k,v in pairs(self.spells) do
		self.last_tick[v] = {}
	end


	self.projection_display =
		self:CreateFontString("CombustionJunctionProjection")
	self.projection_display:SetFontObject(TextStatusBarText)
	self.projection_display:SetPoint("CENTER", nil, nil, 0, 100)

--~ 	for k,v in pairs(self.spells) do
--~ 		self.last_tick[v] = 0
--~ 	end
--~ 	Debug("CombustionJunction.last_tick should have 0 for the value " ..
--~ 			"for all keys which are values in CombustionJunction.spells.")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function CombustionJunction:PLAYER_LOGOUT()
end
