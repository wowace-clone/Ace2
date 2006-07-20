--[[
Name: AceTab-2.0
Revision: $Rev: 1$
Author(s): hyperactiveChipmunk (hyperactiveChipmunk@gmail.com)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceTab-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceTab-2.0
Description: A tab-completion library
Dependencies: AceLibrary
]]

local MAJOR_VERSION = "AceTab-2.0"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceHook, AceEvent
local AceTab = {}
local _G = getfenv()

local hookedFrames = compost and compost:Acquire() or {}

function AceTab:RegisterTabCompletion(descriptor, regex, compfunc, usagefunc, editframes)
	self:argCheck(descriptor, 2, "string")
	self:argCheck(regex, 3, "string", "table")
	self:argCheck(compfunc, 4, "string", "function", "nil")
	self:argCheck(usagefunc, 5, "string", "function", "nil")
	self:argCheck(editframe, 6, "string", "table", "nil")

	if type(regex) == "string" then regex = {regex} end

	if type(compfunc) == "string" and type(self[compfunc]) ~= "function" then
		self:error("Cannot register function %q; it does not exist", compfunc)
	end

	if type(usagefunc) == "string" and type(self[usagefunc]) ~= "function" then
		self:error("Cannot register usage function %q; it does not exist", usagefunc)
	end

	if not editframes then editframes = {"ChatFrameEditBox"} end

	if type(editframes) == "table" and editframes.Show then editframes = {editframes:GetName()} end
	
	for _, frame in pairs(editframes) do
		local Gframe
		if type(frame) == "table" then
			Gframe = frame
			frame  = frame:GetName()
		else
			Gframe = _G[frame]
		end

		if type(Gframe) ~= "table" or not Gframe.Show then
			self:error("Cannot register frame %q; it does not exist", frame)
			frame = nil
		end
		
		if frame then
			if Gframe:GetFrameType() ~= "EditBox" then
				self:error("Cannot register frame %q; it is not an EditBox", frame)
				frame = nil
			else
				if AceEvent:IsFullyInitialized() and not self:IsHooked(Gframe, "OnTabPressed") then
					self:HookScript(Gframe, "OnTabPressed")
				else
					hookedFrames[frame] = true
				end
			end
		end
	end
	
	if not self.registry[descriptor] then
		self.registry[descriptor] = Compost and Compost:Acquire() or {}
	end
	
	if not self.registry[descriptor][self] then
		self.registry[descriptor][self] = Compost and Compost:Acquire() or {}
	end
	self.registry[descriptor][self] = {patterns = regex, compfunc = compfunc,  usage = usagefunc, frames = editframes}
	
	if not AceEvent and AceLibrary:HasInstance("AceEvent-2.0") then
		external(AceTab, "AceEvent-2.0", AceLibrary("AceEvent-2.0"))
	end
	if AceEvent then
		if not self.finalHook then
			self:RegisterEvent("AceEvent_FullyInitialized", "AceEvent_FullyInitialized", true)
		end
	end
end

function AceTab:IsTabCompletionRegistered(descriptor)
	self:argCheck(descriptor, 2, "string")
	if self.registry[descriptor] and self.registry[descriptor][self] then
		return true, self.registry[descriptor][self].completion
	end
	return false, nil
end

function AceTab:UnregisterTabCompletion(descriptor)
	self:argCheck(descriptor, 2, "string")
	if self.registry[description] and self.registry[description][self] then
		self.registry[descriptor][self].completion = nil
	else
		self:error("Cannot unregister a tab completion that you have not registered.")
	end
end

local GCS
GCS = function(s1, s2)
	if not s1 and not s2 then return end
	if not s1 then s1 = s2 end
	if not s2 then s2 = s1 end
	local s1len, s2len = string.len(s1), string.len(s2)
	if s2len < s1len then
		s1, s2 = s2, s1
	end
	if string.find(string.lower(s2), string.lower(s1)) then
		return s1
	else
		return GCS(string.sub(s1, 1, -2), s2)
	end
end

function AceTab:OnTabPressed()
	local ost = this:GetScript("OnTextSet")
	if ost then this:SetScript("OnTextSet", nil) end
	this:Insert("\255")
	local pos = string.find(this:GetText(), "\255", 1) - 1
	this:HighlightText(pos, pos+1)
	this:Insert("\0")
	if ost then this:SetScript("OnTextSet", ost) end

	local text = string.sub(this:GetText(), 0, pos) or ""

	local left = string.find(string.sub(text, 1, pos), "%S+$") or pos
	
	if not left or left == 1 and string.sub(text, 1, 1) == "/" then return self.hooks[this].OnTabPressed.orig() end

	local _, _, word = string.find(string.sub(text, left, pos), "(%S+)")
	if not word then word = "" end
	
	local completions = compost and compost:Erase() or {}
	local matches = compost and compost:Erase() or {}
	local numMatches = 0
	
	for desc, entry in pairs(AceTab.registry) do
		for _, s in pairs(entry) do
			for _, f in s.frames do
				if _G[f] == this then
					for _, regex in ipairs(s.patterns) do
						matches[desc] = compost and compost:Erase() or {}
						local cands = compost and compost:Erase() or {}
						if string.find(string.sub(text, 1, left), regex) then
							s.compfunc(cands, string.sub(text, 1, left-1) .. string.sub(text, 1, left-1+string.len(word)), left-1)
						end
						for _, cand in ipairs(cands) do
							if string.find(string.lower(cand), string.lower(word), 1, 1) == 1 then
								table.insert(matches[desc], cand)
								numMatches = numMatches + 1
							end
						end
						matches[desc].usage = s.usage
					end
				end
			end
		end
	end
	
	this:HighlightText(left-1, left + string.len(word)-1)

	if numMatches == 1 then
		local _, c = next(matches)
		this:Insert(c[1])
		this:Insert(" ")
	else
		local gcs
		for h, c in pairs(matches) do
			local u = c.usage
			local gcs2
			if next(c) then
				if not u then print(h..":") end
				for _, m in ipairs(c) do
					if not u then print(m) end
					gcs2 = GCS(gcs2, m)
				end
			end
			gcs = GCS(gcs, gcs2)
			if u then u(c, gcs2, string.sub(text, 1, left-1)) end
		end
		this:Insert(gcs)
	end
end

function AceTab:AceEvent_FullyInitialized()
	for frame in pairs(hookedFrames) do
		self:HookScript(_G[frame], "OnTabPressed")
	end
end

local function external(self, major, instance)
	if major == "AceHook-2.0" then
		if not AceHook then
			AceHook = instance
			AceHook:embed(self)
		end
	elseif major == "AceEvent-2.0" then
		if not AceEvent then
			AceEvent = instance
			
			AceEvent:embed(self)
		end
	end
end

local function activate(self, oldLib, oldDeactivate)
	if oldLib then
		self.registry = oldLib.registry
	end

	if not self.registry then
		self.registry = {}
	end

	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceTab, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
AceTab = AceLibrary(MAJOR_VERSION)
