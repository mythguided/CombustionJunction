local addonName, addonTable = ...

CombustionJunction = CreateFrame("frame")
addonTable.frame = CombustionJunction
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
	self.current_projection = math.floor(total_dmg + 0.5)
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

	self.hide_anchor = COMBUSTION_JUNCTION_HIDE_ANCHOR or false
	self.anchor_x = COMBUSTION_JUNCTION_ANCHOR_X or 600
	self.anchor_y = COMBUSTION_JUNCTION_ANCHOR_Y or 600



	self.projection_display =
		self:CreateFontString("CombustionJunctionProjectionText")
	self.projection_display:SetFontObject(TextStatusBarText)
	self.projection_display_anchor = CreateFrame("Button", nil, self)
	local anchor = self.projection_display_anchor
	anchor:SetHeight(24)
	anchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = {left = 5, right = 5, top = 5, bottom = 5}, tile = true, tileSize = 16})
	anchor:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
	anchor:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	if self.hide_anchor then anchor:Hide() end
	anchor:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",self.anchor_x, self.anchor_y)
	self.current_projection = 0
	self:redisplay()

	local text = anchor:CreateFontString(nil, nil, "GameFontNormalSmall")
	text:SetPoint("CENTER")
	text:SetText("Combustion Junction")
	anchor:SetWidth(text:GetStringWidth() + 8)

	anchor:SetMovable(true)
	anchor:RegisterForDrag("LeftButton")

	anchor:SetScript("OnClick", function(self) InterfaceOptionsFrame_OpenToCategory(CombustionJunction.config) end)


	local display = self.projection_display
	display:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",self.anchor_x, self.anchor_y)
	anchor:SetScript("OnDragStart", function(self)
		display:Hide()
		self:StartMoving()
	end)


	anchor:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		addonTable.frame.anchor_x, addonTable.frame.anchor_y = self:GetLeft(), self:GetBottom()
		display:SetPoint("TOPLEFT",UIParent, "BOTTOMLEFT", addonTable.frame.anchor_x, addonTable.frame.anchor_y)
		display:Show()
	end)


	self.projection_display:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.anchor_x, self.anchor_y)

--~ 	for k,v in pairs(self.spells) do
--~ 		self.last_tick[v] = 0
--~ 	end
--~ 	Debug("CombustionJunction.last_tick should have 0 for the value " ..
--~ 			"for all keys which are values in CombustionJunction.spells.")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


function CombustionJunction:PLAYER_LOGOUT()

	if not self.hide_anchor then
		COMBUSTION_JUNCTION_HIDE_ANCHOR=nil
	else
		COMBUSTION_JUNCTION_HIDE_ANCHOR=true
	end
	if self.anchor_x == 600 then
		COMBUSTION_JUNCTION_ANCHOR_X = nil
	else
		COMBUSTION_JUNCTION_ANCHOR_X = self.anchor_x
	end
	if self.anchor_y == 600 then
		COMBUSTION_JUNCTION_ANCHOR_Y = nil
	else
		COMBUSTION_JUNCTION_ANCHOR_Y = self.anchor_y
	end

end
