--[[
Name: AceTab-2.0
Revision: $Rev: 1$
Author(s): hyperactiveChipmunk (hyperactiveChipmunk@gmail.com)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceTab-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceTab-2.0
Description: Tab-completion functionality
Dependencies: AceLibrary
]]

local MAJOR_VERSION = "AceTab-2.0"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local AceHook
local AceTab = {}
local dump=DevTools_Dump
local _G = getfenv()

function AceTab:RegisterTabCompletion(descriptor, regex, compfunc, usagefunc, editframes)
	AceTab:argCheck(descriptor, 2, "string")
	AceTab:argCheck(regex, 3, "string", "table")
	AceTab:argCheck(compfunc, 4, "string", "function", "nil")
	AceTab:argCheck(usagefunc, 5, "string", "function", "nil")
	AceTab:argCheck(editframe, 6, "string", "table", "nil")

	if type(regex) == "string" then regex = {regex} end

	if type(compfunc) == "string" and type(self[compfunc]) ~= "function" then
		AceTab:error("Cannot register function %q; it does not exist", compfunc)
	end

	if type(usagefunc) == "string" and type(self[usagefunc]) ~= "function" then
		AceTab:error("Cannot register usage function %q; it does not exist", usagefunc)
	end

	if not editframes then editframes = {ChatFrameEditBox} end

	if type(editframes) == "string" then
		editframes = _G[editframes]
	end

	if editframes.Show then editframes = {editframes} end

	for i, frame in pairs(editframes) do
		if type(frame) == "string" then
			if type(self[frame]) ~= "table" then
				AceTab:Print("Cannot register frame %q; it does not exist", frame)
			else
				frame = _G[frame]
			end
		end
		if frame then
			if frame:GetFrameType() ~= "EditBox" then
				print("Cannot register frame %q; it is not an EditBox", frame)
				frame = nil
			elseif not AceTab.hooks or not AceTab.hooks[frame] then
				self:HookScript(frame, "OnTabPressed")
			end
		end
	end
	
	if not AceTab.registry[descriptor] then
		AceTab.registry[descriptor] = Compost and Compost:Acquire() or {}
	end
	
	if not AceTab.registry[descriptor][self] then
		AceTab.registry[descriptor][self] = Compost and Compost:Acquire() or {}
	end
	
	AceTab.registry[descriptor][self] = {patterns = regex, compfunc = compfunc,  usage = usagefunc, frames = editframes}
end

function AceTab:IsTabCompletionRegistered(descriptor)
	AceTab:argCheck(descriptor, 2, "string")
	if AceTab.registry[descriptor] and AceTab.registry[descriptor][self] then
		return true, AceTab.registry[descriptor][self].completion
	end
	return false, nil
end

function AceTab:UnregisterTabCompletion(descriptor)
	AceTab:argCheck(descriptor, 2, "string")
	if AceTab.registry[description] and AceTab.registry[description][self] then
		AceTab.registry[descriptor][self].completion = nil
	else
		AceTab:error("Cannot unregister a tab completion that you have not registered.")
	end
end

local function LCS(strings) --returns Least Common Substring.  Yoinked wholesale from Tem.
	local len = 0
	local numStrings = table.getn(strings)
	
	for _, s in strings do
		len = string.len(s) > len and string.len(s) or len
	end
	
	for i = 1, len do
		local c = string.lower(string.sub(strings[1], i, i))
		for j = 2, numStrings do
			if string.lower(string.sub(strings[j], i, i)) ~= c then
				return string.sub(strings[1], 0, i-1)
			end
		end
	end
	return strings[1]
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

	local left = string.find(string.sub(text, 1, pos), "%w+$") or pos
	if not left then return self.hooks[this].OnTabPressed.orig() end

	local _, _, word = string.find(string.sub(text, left, pos), "(%S+)")
	if not word then word = "" end
	
	local completions = compost and compost:Erase() or {}
	local matches = compost and compost:Erase() or {}
	local numMatches = 0
	
	for desc, entry in pairs(AceTab.registry) do
		for _, s in pairs(entry) do
			for _, f in s.frames do
				if f == this then
					for _, regex in ipairs(s.patterns) do
						matches[desc] = compost and compost:Erase() or {}
						s.cands = compost and compost:Erase() or {}
						if string.find(string.sub(text, 1, left), regex) then
							s.compfunc(s.cands, string.sub(text, 1, left-1))
						end
						for _, cand in ipairs(s.cands) do
							if string.find(string.lower(cand), string.lower(word), 1, 1) == 1 then
								table.insert(matches[desc], cand)
								numMatches = numMatches + 1
							end
						end
						if matches[desc][1] then matches[desc].usage = s.usage end
					end
				end
			end
		end
	end
	
	if numMatches == 0 then return self.hooks[this].OnTabPressed.orig() end
	this:HighlightText(left-1, left + string.len(word)-1)
	if numMatches == 1 then
		local _, c = next(matches)
		this:Insert(c[1])
		this:Insert(" ")
	else
		local matchlist = compost and compost:Erase() or {}
		for h, c in pairs(matches) do
			print(h..":")
			for _, m in ipairs(c) do
				table.insert(matchlist, m)
				if c.usage then
					c.usage(m)
				else
					print(m)
				end
			end
		end
		this:Insert(LCS(matchlist))
	end
end

local function external(self, major, instance)
	if major == "AceHook-2.0" then
		if not AceHook then
			AceHook = instance
			AceHook:embed(self)
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