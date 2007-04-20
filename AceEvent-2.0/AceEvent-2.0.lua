--[[
Name: AceEvent-2.0
Revision: $Rev$
Developed by: The Ace Development Team (http://www.wowace.com/index.php/The_Ace_Development_Team)
Inspired By: Ace 1.x by Turan (turan@gryphon.com)
Website: http://www.wowace.com/
Documentation: http://www.wowace.com/index.php/AceEvent-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceEvent-2.0
Description: Mixin to allow for event handling, scheduling, and inter-addon
             communication.
Dependencies: AceLibrary, AceOO-2.0
License: LGPL v2.1
]]

local MAJOR_VERSION = "AceEvent-2.0"
local MINOR_VERSION = "$Revision$"

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

if not AceLibrary:HasInstance("AceOO-2.0") then error(MAJOR_VERSION .. " requires AceOO-2.0") end

local AceOO = AceLibrary:GetInstance("AceOO-2.0")
local Mixin = AceOO.Mixin
local AceEvent = Mixin {
						"RegisterEvent",
						"RegisterAllEvents",
						"UnregisterEvent",
						"UnregisterAllEvents",
						"TriggerEvent",
						"ScheduleEvent",
						"ScheduleRepeatingEvent",
						"CancelScheduledEvent",
						"CancelAllScheduledEvents",
						"IsEventRegistered",
						"IsEventScheduled",
						"RegisterBucketEvent",
						"UnregisterBucketEvent",
						"UnregisterAllBucketEvents",
						"IsBucketEventRegistered",
						"ScheduleLeaveCombatAction",
						"CancelAllCombatSchedules",
					   }

local weakKey = {__mode="k"}

local WoW21 = IsLoggedIn and true

local FAKE_NIL
local RATE
local addonFrames
local onceRegistry
local throttleRegistry
local buckets
local registry
local combatSchedules
local AceEvent_debugTable

local eventsWhichHappenOnce = {
	PLAYER_LOGIN = true,
	AceEvent_FullyInitialized = true,
	VARIABLES_LOADED = true,
	PLAYER_LOGOUT = true,
}
local next = next
local pairs = pairs
local pcall = pcall
local type = type
local GetTime = GetTime
local gcinfo = gcinfo
local unpack = unpack
local geterrorhandler = geterrorhandler

local new, del
do
	local cache = setmetatable({}, {__mode='k'})
	function new(...)
		local t = next(cache)
		if t then
			cache[t] = nil
			for i = 1, select('#', ...) do
				t[i] = select(i, ...)
			end
			return t
		else
			return { ... }
		end
	end
	function del(t)
		for k in pairs(t) do
			t[k] = nil
		end
		cache[t] = true
		return nil
	end
end

local registeringFromAceEvent
function AceEvent:RegisterEvent(event, method, once)
	AceEvent:argCheck(event, 2, "string")
	if self == AceEvent and not registeringFromAceEvent then
		AceEvent:argCheck(method, 3, "function")
		self = method
	else
		AceEvent:argCheck(method, 3, "string", "function", "nil", "boolean", "number")
		if type(method) == "boolean" or type(method) == "number" then
			AceEvent:argCheck(once, 4, "nil")
			once, method = method, event
		end
	end
	AceEvent:argCheck(once, 4, "number", "boolean", "nil")
	if eventsWhichHappenOnce[event] then
		once = true
	end
	local throttleRate
	if type(once) == "number" then
		throttleRate, once = once
	end
	if not method then
		method = event
	end
	if type(method) == "string" and type(self[method]) ~= "function" then
		AceEvent:error("Cannot register event %q to method %q, it does not exist", event, method)
	else
		assert(type(method) == "function" or type(method) == "string")
	end

	if not registry[event] then
		registry[event] = new()
	end
	if event:match("^[A-Z_]+$") then
		-- Blizzard event
		if self == method then
			addonFrames[AceEvent]:RegisterEvent(event)
		else
			addonFrames[self]:RegisterEvent(event)
		end
	end

	local remember = true
	if registry[event][self] then
		remember = false
	end
	registry[event][self] = method

	if once then
		if not onceRegistry[event] then
			onceRegistry[event] = new()
		end
		onceRegistry[event][self] = true
	else
		if onceRegistry[event] then
			onceRegistry[event][self] = nil
			if not next(onceRegistry[event]) then
				onceRegistry[event] = del(onceRegistry[event])
			end
		end
	end

	if throttleRate then
		if not throttleRegistry[event] then
			throttleRegistry[event] = new()
		end
		if throttleRegistry[event][self] then
			throttleRegistry[event][self] = nil
		end
		throttleRegistry[event][self] = setmetatable(new(), weakKey)
		local t = throttleRegistry[event][self]
		t[RATE] = throttleRate
	else
		if throttleRegistry[event] then
			if throttleRegistry[event][self] then
				throttleRegistry[event][self] = nil
			end
			if not next(throttleRegistry[event]) then
				throttleRegistry[event] = del(throttleRegistry[event])
			end
		end
	end

	if remember then
		AceEvent:TriggerEvent("AceEvent_EventRegistered", self, event)
	end
end

local ALL_EVENTS

function AceEvent:RegisterAllEvents(method)
	if self == AceEvent then
		AceEvent:argCheck(method, 1, "function")
		self = method
	else
		AceEvent:argCheck(method, 1, "string", "function")
		if type(method) == "string" and type(self[method]) ~= "function" then
			AceEvent:error("Cannot register all events to method %q, it does not exist", method)
		end
	end

	if not registry[ALL_EVENTS] then
		registry[ALL_EVENTS] = new()
	end
	if self == method then
		addonFrames[AceEvent]:RegisterAllEvents()
	else
		addonFrames[self]:RegisterAllEvents()
	end

	registry[ALL_EVENTS][self] = method
end

local memstack, timestack = {}, {}
local memdiff, timediff

function AceEvent:TriggerEvent(event, ...)
	local tmp = new()
	AceEvent:argCheck(event, 2, "string")
	if not registry[event] and not registry[ALL_EVENTS] then
		return
	end
	local lastEvent = AceEvent.currentEvent
	AceEvent.currentEvent = event

	if onceRegistry[event] then
		for obj, method in pairs(onceRegistry[event]) do
			tmp[obj] = registry[event] and registry[event][obj] or nil
		end
		local obj = next(tmp)
		while obj do
			local mem, time
			if AceEvent_debugTable then
				if not AceEvent_debugTable[event] then
					AceEvent_debugTable[event] = {}
				end
				if not AceEvent_debugTable[event][obj] then
					AceEvent_debugTable[event][obj] = {
						mem = 0,
						time = 0,
						count = 0,
					}
				end
				if memdiff then
					table.insert(memstack, memdiff)
					table.insert(timestack, timediff)
				end
				memdiff, timediff = 0, 0
				mem, time = gcinfo(), GetTime()
			end
			local method = tmp[obj]
			AceEvent.UnregisterEvent(obj, event)
			if type(method) == "string" then
				local obj_method = obj[method]
				if obj_method then
					local success, err = pcall(obj_method, obj, ...)
					if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
				end
			elseif method then -- function
				local success, err = pcall(method, ...)
				if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
			end
			if AceEvent_debugTable then
				local dmem, dtime = memdiff, timediff
				mem, time = gcinfo() - mem - memdiff, GetTime() - time - timediff
				AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
				AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
				AceEvent_debugTable[event][obj].count = AceEvent_debugTable[event][obj].count + 1

				memdiff, timediff = table.remove(memstack), table.remove(timestack)
				if memdiff then
					memdiff = memdiff + mem + dmem
					timediff = timediff + time + dtime
				end
			end
			tmp[obj] = nil
			obj = next(tmp)
		end
	end

	local throttleTable = throttleRegistry[event]
	if registry[event] then
		for obj, method in pairs(registry[event]) do
			tmp[obj] = method
		end
		local obj = next(tmp)
		while obj do
			local method = tmp[obj]
			local continue = false
			if throttleTable and throttleTable[obj] then
				local a1 = ...
				if a1 == nil then
					a1 = FAKE_NIL
				end
				if not throttleTable[obj][a1] or GetTime() - throttleTable[obj][a1] >= throttleTable[obj][RATE] then
					throttleTable[obj][a1] = GetTime()
				else
					continue = true
				end
			end
			if not continue then
				local mem, time
				if AceEvent_debugTable then
					if not AceEvent_debugTable[event] then
						AceEvent_debugTable[event] = {}
					end
					if not AceEvent_debugTable[event][obj] then
						AceEvent_debugTable[event][obj] = {
							mem = 0,
							time = 0,
							count = 0,
						}
					end
					if memdiff then
						table.insert(memstack, memdiff)
						table.insert(timestack, timediff)
					end
					memdiff, timediff = 0, 0
					mem, time = gcinfo(), GetTime()
				end
				if type(method) == "string" then
					local obj_method = obj[method]
					if obj_method then
						local success, err = pcall(obj_method, obj, ...)
						if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
					end
				elseif method then -- function
					local success, err = pcall(method, ...)
					if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
				end
				if AceEvent_debugTable then
					local dmem, dtime = memdiff, timediff
					mem, time = gcinfo() - mem - memdiff, GetTime() - time - timediff
					AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
					AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
					AceEvent_debugTable[event][obj].count = AceEvent_debugTable[event][obj].count + 1

					memdiff, timediff = table.remove(memstack), table.remove(timestack)
					if memdiff then
						memdiff = memdiff + mem + dmem
						timediff = timediff + time + dtime
					end
				end
			end
			tmp[obj] = nil
			obj = next(tmp)
		end
	end
	if registry[ALL_EVENTS] then
		for obj, method in pairs(registry[ALL_EVENTS]) do
			tmp[obj] = method
		end
		local obj = next(tmp)
		while obj do
			local method = tmp[obj]
			local mem, time
			if AceEvent_debugTable then
				if not AceEvent_debugTable[event] then
					AceEvent_debugTable[event] = {}
				end
				if not AceEvent_debugTable[event][obj] then
					AceEvent_debugTable[event][obj] = {}
					AceEvent_debugTable[event][obj].mem = 0
					AceEvent_debugTable[event][obj].time = 0
					AceEvent_debugTable[event][obj].count = 0
				end
				if memdiff then
					table.insert(memstack, memdiff)
					table.insert(timestack, timediff)
				end
				memdiff, timediff = 0, 0
				mem, time = gcinfo(), GetTime()
			end
			if type(method) == "string" then
				local obj_method = obj[method]
				if obj_method then
					local success, err = pcall(obj_method, obj, ...)
					if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
				end
			elseif method then -- function
				local success, err = pcall(method, ...)
				if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
			end
			if AceEvent_debugTable then
				local dmem, dtime = memdiff, timediff
				mem, time = gcinfo() - mem - memdiff, GetTime() - time - timediff
				AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
				AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
				AceEvent_debugTable[event][obj].count = AceEvent_debugTable[event][obj].count + 1

				memdiff, timediff = table.remove(memstack), table.remove(timestack)
				if memdiff then
					memdiff = memdiff + mem + dmem
					timediff = timediff + time + dtime
				end
			end
			tmp[obj] = nil
			obj = next(tmp)
		end
	end
	tmp = del(tmp)
	AceEvent.currentEvent = lastEvent
end

local delayRegistry

local delayParents = {}
local function ScheduleEvent(self, repeating, event, delay, ...)
	local id
	if type(event) == "string" or type(event) == "table" then
		if type(event) == "table" then
			if not delayRegistry[event] then
				AceEvent:error("Bad argument #2 to `ScheduleEvent'. Improper id table fed in.")
			end
		end
		if type(delay) ~= "number" then
			id, event, delay = event, delay, ...
			AceEvent:argCheck(event, 3, "string", "function", --[[ so message is right ]] "number")
			AceEvent:argCheck(delay, 4, "number")
			self:CancelScheduledEvent(id)
		end
	else
		AceEvent:argCheck(event, 2, "string", "function")
		AceEvent:argCheck(delay, 3, "number")
	end
	
	local t
	if type(id) == "table" then
		for k in pairs(id) do
			id[k] = nil
		end
		t = id
		for i = 2, select('#', ...) do
			t[i-1] = select(i, ...)
		end
		t.n = select('#', ...) - 1
	elseif id then
		t = new(select(2, ...))
		t.n = select('#', ...) - 1
	else
		t = { n = select('#', ...), ... }
	end
	t.event = event
	t.time = GetTime() + delay
	t.self = self
	t.id = id or t
	t.repeatDelay = repeating and delay
	if AceEvent_debugTable then
		t.mem = 0
		t.count = 0
		t.timeSpent = 0
	end
	delayRegistry[t.id] = t
	if not delayParents[self] then
		delayParents[self] = new()
		addonFrames[self]:Show()
	end
	delayParents[self][t.id] = t
	return t.id
end

function AceEvent:ScheduleEvent(event, delay, ...)
--	DEFAULT_CHAT_FRAME:AddMessage(debugstack() .. "\n--------\n")
	if type(event) == "string" or type(event) == "table" then
		if type(event) == "table" then
			if not delayRegistry[event] then
				AceEvent:error("Bad argument #2 to `ScheduleEvent'. Improper id table fed in.")
			end
		end
		if type(delay) ~= "number" then
			AceEvent:argCheck(delay, 3, "string", "function", --[[ so message is right ]] "number")
			AceEvent:argCheck(..., 4, "number")
		end
	else
		AceEvent:argCheck(event, 2, "string", "function")
		AceEvent:argCheck(delay, 3, "number")
	end

	return ScheduleEvent(self, false, event, delay, ...)
end

function AceEvent:ScheduleRepeatingEvent(event, delay, ...)
	if type(event) == "string" or type(event) == "table" then
		if type(event) == "table" then
			if not delayRegistry[event] then
				AceEvent:error("Bad argument #2 to `ScheduleEvent'. Improper id table fed in.")
			end
		end
		if type(delay) ~= "number" then
			AceEvent:argCheck(delay, 3, "string", "function", --[[ so message is right ]] "number")
			AceEvent:argCheck(..., 4, "number")
		end
	else
		AceEvent:argCheck(event, 2, "string", "function")
		AceEvent:argCheck(delay, 3, "number")
	end

	return ScheduleEvent(self, true, event, delay, ...)
end

function AceEvent:CancelScheduledEvent(t)
	AceEvent:argCheck(t, 2, "string", "table")
	local v = delayRegistry[t]
	if v then
		delayRegistry[t] = nil
		local v_self = v.self
		local parent = delayParents[v_self]
		if not parent then
			return true
		end
		parent[t] = nil
		if not next(parent) then
			delayParents[v_self] = del(parent)
			addonFrames[v_self]:Hide()
		end
		if type(t) == "string" then
			del(v)
		end
		return true
	end
	return false
end

function AceEvent:IsEventScheduled(t)
	AceEvent:argCheck(t, 2, "string", "table")
	local v = delayRegistry[t]
	if v then
		return true, v.time - GetTime()
	end
	return false, nil
end

function AceEvent:UnregisterEvent(event)
	AceEvent:argCheck(event, 2, "string")
	if registry[event] and registry[event][self] then
		registry[event][self] = nil
		if onceRegistry[event] and onceRegistry[event][self] then
			onceRegistry[event][self] = nil
			if not next(onceRegistry[event]) then
				onceRegistry[event] = del(onceRegistry[event])
			end
		end
		if throttleRegistry[event] and throttleRegistry[event][self] then
			throttleRegistry[event][self] = nil
			if not next(throttleRegistry[event]) then
				throttleRegistry[event] = del(throttleRegistry[event])
			end
		end
		if not next(registry[event]) then
			registry[event] = del(registry[event])
		end
		if type(self) == "function" or self == AceEvent then
			local has = false
			if event == "PLAYER_REGEN_ENABLED" then
				has = true
			else
				if registry[event] then
					for obj, event in pairs(registry[event]) do
						if type(obj) == "function" or obj == AceEvent then
							has = true
							break
						end
					end
				end
				if not has then
					if registry[ALL_EVENTS] then
						for obj, event in pairs(registry[ALL_EVENTS]) do
							if type(obj) == "function" or obj == AceEvent then
								has = true
								break
							end
						end
					end
					if not has then
						addonFrames[AceEvent]:UnregisterEvent(event)
					end
				end
			end
		else
			local has = false
			if registry[event] and registry[event][self] then
				has = true
			elseif registry[ALL_EVENTS] and registry[ALL_EVENTS][self] then
				has = true
			elseif event == "PLAYER_REGEN_ENABLED" and combatSchedules[self] then
				has = true
			end
			if not has then
				addonFrames[self]:UnregisterEvent(event)
			end
		end
	else
		if self == AceEvent then
			error(("Cannot unregister event %q. Improperly unregistering from AceEvent-2.0."):format(event), 2)
		else
			AceEvent:error("Cannot unregister event %q. %q is not registered with it.", event, self)
		end
	end
	AceEvent:TriggerEvent("AceEvent_EventUnregistered", self, event)
end

function AceEvent:UnregisterAllEvents()
	local addonFrame
	if type(self) == "function" then
		addonFrame = addonFrames[AceEvent]
	else
		addonFrame = addonFrames[self]
	end
	if registry[ALL_EVENTS] and registry[ALL_EVENTS][self] then
		registry[ALL_EVENTS][self] = nil
		if not next(registry[ALL_EVENTS]) then
			registry[ALL_EVENTS] = del(registry[ALL_EVENTS])
		end
		if type(self) == "function" or self == AceEvent then
			addonFrame:UnregisterAllEvents()
			for event, data in pairs(registry) do
				local has = false
				for obj, method in pairs(data) do
					if type(obj) == "function" or obj == AceEvent then
						has = true
						break
					end
				end
				if has then
					addonFrame:RegisterEvent(event)
				end
			end
		else
			addonFrame:UnregisterAllEvents()
			for event, data in pairs(registry) do
				if data[self] then
					addonFrame:RegisterEvent(event)
				end
			end
		end
	end
	if registry.AceEvent_EventUnregistered then
		local event, data = "AceEvent_EventUnregistered", registry.AceEvent_EventUnregistered
		local x = data[self]
		data[self] = nil
		if x then
			if not next(data) then
				if not registry[ALL_EVENTS] then
					addonFrame:UnregisterEvent(event)
				end
				registry[event] = del(registry[event])
			end
			AceEvent:TriggerEvent("AceEvent_EventUnregistered", self, event)
		end
	end
	for event, data in pairs(registry) do
		local x = data[self]
		data[self] = nil
		if x and event ~= ALL_EVENTS then
			if not next(data) then
				if not registry[ALL_EVENTS] then
					addonFrame:UnregisterEvent(event)
				end
				registry[event] = del(registry[event])
			end
			AceEvent:TriggerEvent("AceEvent_EventUnregistered", self, event)
		end
	end
	for event, data in pairs(onceRegistry) do
		data[self] = nil
	end
	if combatSchedules[self] or self == AceEvent or type(self) == "function" then
		addonFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function AceEvent:CancelAllScheduledEvents()
	for k,v in pairs(delayRegistry) do
		if v.self == self then
			if type(k) == "string" then
				del(delayRegistry[k])
			end
			delayRegistry[k] = nil
			local parent = delayParents[self]
			if not parent then
				return true
			end
			parent[k] = nil
			if not next(parent) then
				delayParents[self] = del(parent)
				addonFrames[self]:Hide()
			end
		end
	end
end

function AceEvent:IsEventRegistered(event)
	AceEvent:argCheck(event, 2, "string")
	if self == AceEvent then
		return registry[event] and next(registry[event]) and true or false
	end
	if registry[event] and registry[event][self] then
		return true, registry[event][self]
	end
	return false, nil
end

local bucketfunc
function AceEvent:RegisterBucketEvent(event, delay, method, ...)
	AceEvent:argCheck(event, 2, "string", "table")
	if type(event) == "table" then
		for k,v in pairs(event) do
			if type(k) ~= "number" then
				AceEvent:error("All keys to argument #2 to `RegisterBucketEvent' must be numbers.")
			elseif type(v) ~= "string" then
				AceEvent:error("All values to argument #2 to `RegisterBucketEvent' must be strings.")
			end
		end
	end
	AceEvent:argCheck(delay, 3, "number")
	if AceEvent == self then
		AceEvent:argCheck(method, 4, "function")
		self = method
	else
		if type(event) == "string" then
			AceEvent:argCheck(method, 4, "string", "function", "nil")
			if not method then
				method = event
			end
		else
			AceEvent:argCheck(method, 4, "string", "function")
		end

		if type(method) == "string" and type(self[method]) ~= "function" then
			AceEvent:error("Cannot register event %q to method %q, it does not exist", event, method)
		end
	end
	if not buckets[event] then
		buckets[event] = new()
	end
	if not buckets[event][self] then
		local t = new()
		t.current = new()
		t.self = self
		buckets[event][self] = t
	else
		AceEvent.CancelScheduledEvent(self, buckets[event][self].id)
	end
	local bucket = buckets[event][self]
	bucket.method = method
	
	local n = select('#', ...)
	if n > 0 then
		for i = 1, n do
			bucket[i] = select(i, ...)
		end
	end
	bucket.n = n

	local func = function(arg1)
		bucket.run = true
		if arg1 then
			bucket.current[arg1] = true
		end
	end
	buckets[event][self].func = func
	if type(event) == "string" then
		AceEvent.RegisterEvent(self, event, func)
	else
		for _,v in ipairs(event) do
			AceEvent.RegisterEvent(self, v, func)
		end
	end
	if not bucketfunc then
		bucketfunc = function(bucket)
			local current = bucket.current
			local method = bucket.method
			local self = bucket.self
			if bucket.run then
				if type(method) == "string" then
					self[method](self, current, unpack(bucket, 1, bucket.n))
				elseif method then -- function
					method(current, unpack(bucket, 1, bucket.n))
				end
				for k in pairs(current) do
					current[k] = nil
					k = nil
				end
				bucket.run = false
			end
		end
	end
	bucket.id = AceEvent.ScheduleRepeatingEvent(self, bucketfunc, delay, bucket)
end

function AceEvent:IsBucketEventRegistered(event)
	AceEvent:argCheck(event, 2, "string", "table")
	return buckets[event] and buckets[event][self]
end

function AceEvent:UnregisterBucketEvent(event)
	AceEvent:argCheck(event, 2, "string", "table")
	if not buckets or not buckets[event] or not buckets[event][self] then
		AceEvent:error("Cannot unregister bucket event %q. %q is not registered with it.", event, self)
	end

	local bucket = buckets[event][self]

	if type(event) == "string" then
		AceEvent.UnregisterEvent(self, event)
	else
		for _,v in ipairs(event) do
			AceEvent.UnregisterEvent(self, v)
		end
	end
	AceEvent:CancelScheduledEvent(bucket.id)

	bucket.current = del(bucket.current)
	buckets[event][self] = del(bucket)
	if not next(buckets[event]) then
		buckets[event] = del(buckets[event])
	end
end

function AceEvent:UnregisterAllBucketEvents()
	for k,v in pairs(buckets) do
		if v == self then
			AceEvent.UnregisterBucketEvent(self, k)
			k = nil
		end
	end
end

function AceEvent:CancelAllCombatSchedules()
	local combatSchedules_self = combatSchedules[self]
	if not combatSchedules_self then
		return
	end
	for i,v in ipairs(combatSchedules_self) do
		combatSchedules_self[i] = del(v)
	end
	combatSchedules[self] = del(combatSchedules_self)
end

local inCombat = false

function AceEvent:ScheduleLeaveCombatAction(method, ...)
	local style = type(method)
	if self == AceEvent then
		if style == "table" then
			local func = (...)
			AceEvent:argCheck(func, 3, "string")
			if type(method[func]) ~= "function" then
				AceEvent:error("Cannot schedule a combat action to method %q, it does not exist", func)
			end
		else
			AceEvent:argCheck(method, 2, "function", --[[so message is right]] "table")
		end
		self = method
	else
		AceEvent:argCheck(method, 2, "function", "string", "table")
		if style == "string" and type(self[method]) ~= "function" then
			AceEvent:error("Cannot schedule a combat action to method %q, it does not exist", method)
		elseif style == "table" then
			local func = (...)
			AceEvent:argCheck(func, 3, "string")
			if type(method[func]) ~= "function" then
				AceEvent:error("Cannot schedule a combat action to method %q, it does not exist", func)
			end
		end
	end
	
	if not inCombat then
		local success, err
		if type(method) == "function" then
			success, err = pcall(method, ...)
		elseif type(method) == "table" then
			local func = (...)
			success, err = pcall(method[func], method, select(2, ...))
		else
			success, err = pcall(self[method], self, ...)
		end
		if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
		return
	end
	local t
	local n = select('#', ...)
	if style == "table" then
		t = new(select(2, ...))
		t.obj = method
		t.method = (...)
		t.n = n-1
	else
		t = new(...)
		t.n = n
		if style == "function" then
			t.func = method
		else
			t.method = method
		end
	end
	t.self = self
	local combatSchedules_self = combatSchedules[self]
	if not combatSchedules_self then
		combatSchedules_self = new()
		combatSchedules[self] = combatSchedules_self
	end
	combatSchedules_self[#combatSchedules_self+1] = t
	addonFrames[self]:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function AceEvent:OnEmbedDisable(target)
	self.UnregisterAllEvents(target)

	self.CancelAllScheduledEvents(target)

	self.UnregisterAllBucketEvents(target)
	
	self.CancelAllCombatSchedules(target)
end

function AceEvent:EnableDebugging()
	if not self.debugTable then
		self.debugTable = {}
		AceEvent_debugTable = self.debugTable

		for k,v in pairs(self.delayRegistry) do
			if not v.mem then
				v.mem = 0
				v.count = 0
				v.timeSpent = 0
			end
		end
	end
end

function AceEvent:IsFullyInitialized()
	return self.postInit or false
end

if WoW21 then
	function AceEvent:IsPostPlayerLogin()
		return IsLoggedIn() and true or false
	end
else
	function AceEvent:IsPostPlayerLogin()
		return self.playerLogin or false
	end
end

local inPlw = false
local blacklist = {
	UNIT_INVENTORY_CHANGED = true,
	BAG_UPDATE = true,
	ITEM_LOCK_CHANGED = true,
	ACTIONBAR_SLOT_CHANGED = true,
}
local function runEvent(obj, event, ...)
	local registry_event_obj = registry[event] and registry[event][obj]
	local registry_ALL_EVENTS_obj = registry[ALL_EVENTS] and registry[ALL_EVENTS][obj]
	
	if not registry_event_obj and not registry_ALL_EVENTS_obj then
		return
	end
	
	local lastEvent = AceEvent.currentEvent
	AceEvent.currentEvent = event

	if onceRegistry[event] and onceRegistry[event][obj] then
		local mem, time
		if AceEvent_debugTable then
			if not AceEvent_debugTable[event] then
				AceEvent_debugTable[event] = {}
			end
			if not AceEvent_debugTable[event][obj] then
				AceEvent_debugTable[event][obj] = {
					mem = 0,
					time = 0,
					count = 0,
				}
			end
			if memdiff then
				table.insert(memstack, memdiff)
				table.insert(timestack, timediff)
			end
			memdiff, timediff = 0, 0
			mem, time = gcinfo(), GetTime()
		end
	
		local method = registry_event_obj
		AceEvent.UnregisterEvent(obj, event)
		if type(method) == "string" then
			local obj_method = obj[method]
			if obj_method then
				local success, err = pcall(obj_method, obj, ...)
				if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
			end
		elseif method then -- function
			local success, err = pcall(method, ...)
			if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
		end
	
		if AceEvent_debugTable then
			local dmem, dtime = memdiff, timediff
			mem, time = gcinfo() - mem - memdiff, GetTime() - time - timediff
			AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
			AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
			AceEvent_debugTable[event][obj].count = AceEvent_debugTable[event][obj].count + 1

			memdiff, timediff = table.remove(memstack), table.remove(timestack)
			if memdiff then
				memdiff = memdiff + mem + dmem
				timediff = timediff + time + dtime
			end
		end
	elseif registry_event_obj then
		local method = registry_event_obj
		local throttleTable = throttleRegistry[event]
		local throttleTable_obj = throttleTable and throttleTable[obj]
		local continue = false
		if throttleTable_obj then
			local a1 = ...
			if a1 == nil then
				a1 = FAKE_NIL
			end
			if not throttleTable_obj[a1] or GetTime() - throttleTable_obj[a1] >= throttleTable_obj[RATE] then
				throttleTable_obj[a1] = GetTime()
			else
				continue = true
			end
		end
		if not continue then
			local mem, time
			if AceEvent_debugTable then
				if not AceEvent_debugTable[event] then
					AceEvent_debugTable[event] = {}
				end
				if not AceEvent_debugTable[event][obj] then
					AceEvent_debugTable[event][obj] = {
						mem = 0,
						time = 0,
						count = 0,
					}
				end
				if memdiff then
					table.insert(memstack, memdiff)
					table.insert(timestack, timediff)
				end
				memdiff, timediff = 0, 0
				mem, time = gcinfo(), GetTime()
			end
		
			if type(method) == "string" then
				local obj_method = obj[method]
				if obj_method then
					local success, err = pcall(obj_method, obj, ...)
					if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
				end
			elseif method then -- function
				local success, err = pcall(method, ...)
				if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
			end

			if AceEvent_debugTable then
				local dmem, dtime = memdiff, timediff
				mem, time = gcinfo() - mem - memdiff, GetTime() - time - timediff
				AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
				AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
				AceEvent_debugTable[event][obj].count = AceEvent_debugTable[event][obj].count + 1

				memdiff, timediff = table.remove(memstack), table.remove(timestack)
				if memdiff then
					memdiff = memdiff + mem + dmem
					timediff = timediff + time + dtime
				end
			end
		end
	end

	if registry_ALL_EVENTS_obj then
		local mem, time
		if AceEvent_debugTable then
			if not AceEvent_debugTable[event] then
				AceEvent_debugTable[event] = {}
			end
			if not AceEvent_debugTable[event][obj] then
				AceEvent_debugTable[event][obj] = {
					mem = 0,
					time = 0,
					count = 0,
				}
			end
			if memdiff then
				table.insert(memstack, memdiff)
				table.insert(timestack, timediff)
			end
			memdiff, timediff = 0, 0
			mem, time = gcinfo(), GetTime()
		end
	
		local method = registry_ALL_EVENTS_obj
		if type(method) == "string" then
			local obj_method = obj[method]
			if obj_method then
				local success, err = pcall(obj_method, obj, ...)
				if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
			end
		elseif method then -- function
			local success, err = pcall(method, ...)
			if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
		end

		if AceEvent_debugTable then
			local dmem, dtime = memdiff, timediff
			mem, time = gcinfo() - mem - memdiff, GetTime() - time - timediff
			AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
			AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
			AceEvent_debugTable[event][obj].count = AceEvent_debugTable[event][obj].count + 1

			memdiff, timediff = table.remove(memstack), table.remove(timestack)
			if memdiff then
				memdiff = memdiff + mem + dmem
				timediff = timediff + time + dtime
			end
		end
	end

	AceEvent.currentEvent = lastEvent
end

local tmp = {}
local function frame_OnEvent(this, event, ...)
	if inPlw and blacklist[event] then
		return
	end
	local obj = this.obj
	
	if event == "PLAYER_REGEN_ENABLED" then
		local combatSchedules_obj = combatSchedules[obj]
		if combatSchedules_obj then
			for i, v in ipairs(combatSchedules_obj) do
				tmp[i] = v
				combatSchedules_obj[i] = nil
			end
			combatSchedules[obj] = del(combatSchedules_obj)
			for i, v in ipairs(tmp) do
				local func = v.func
				if func then
					local success, err = pcall(func, unpack(v, 1, v.n))
					if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
				else
					local obj = v.obj or v.self
					local method = v.method
					local obj_method = obj[method]
					if obj_method then
						local success, err = pcall(obj_method, obj, unpack(v, 1, v.n))
						if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
					end
				end
				tmp[i] = del(v)
			end
			
			if obj ~= AceEvent then
				local registry_event_obj = registry[event] and registry[event][obj]
				local registry_ALL_EVENTS_obj = registry[ALL_EVENTS] and registry[ALL_EVENTS][obj]
				if not registry_event_obj and not registry_ALL_EVENTS_obj then
					this:UnregisterEvent(event)
					return
				end
			end
		end
	end
	
	if obj == AceEvent then
		local registry_event = registry[event]
		if registry_event then
			for obj, method in pairs(registry_event) do
				tmp[obj] = method
			end
			for obj, method in pairs(tmp) do
				tmp[obj] = nil
				if type(obj) == "function" then
					runEvent(obj, event, ...)
				elseif obj == AceEvent then
					runEvent(obj, event, ...)
				end
			end
		end
		return
	else
		return runEvent(obj, event, ...)
	end
end

local function frame_OnUpdate(this, elapsed)
	local obj = this.obj
	local list = delayParents[obj]
	if not list then
		this:Hide()
		return
	end
	local t = GetTime()
	for k in pairs(list) do
		tmp[k] = true
	end
	for k in pairs(tmp) do
		tmp[k] = nil
		local v = delayRegistry[k]
		if v then
			local v_time = v.time
			if not v_time then
				delayRegistry[k] = nil
				list[k] = nil
			elseif v_time <= t then
				local v_repeatDelay = v.repeatDelay
				if v_repeatDelay then
					-- use the event time, not the current time, else timing inaccuracies add up over time
					v.time = v_time + v_repeatDelay
				end
				local event = v.event
				local mem, time
				if AceEvent_debugTable then
					mem, time = gcinfo(), GetTime()
				end
				if type(event) == "function" then
					local success, err = pcall(event, unpack(v, 1, v.n))
					if not success then geterrorhandler()(err:find("%.lua:%d+:") and err or (debugstack():match("(.-: )in.-\n") or "") .. err) end
				else
					AceEvent:TriggerEvent(event, unpack(v, 1, v.n))
				end
				if AceEvent_debugTable then
					mem, time = gcinfo() - mem, GetTime() - time
					v.mem = v.mem + mem
					v.timeSpent = v.timeSpent + time
					v.count = v.count + 1
				end
				if not v_repeatDelay then
					local x = delayRegistry[k]
					if x and x.time == v_time then -- check if it was manually reset
						if type(k) == "string" then
							del(delayRegistry[k])
						end
						delayRegistry[k] = nil
						list[k] = nil
					end
				end
			end
		end
	end
	if not next(list) then
		delayParents[obj] = del(list)
		this:Hide()
	end
end

function AceEvent:OnInstanceInit(obj)
	local frame = CreateFrame("Frame")
	addonFrames[obj] = frame
	frame.obj = obj
	frame:SetScript("OnEvent", frame_OnEvent)
	frame:SetScript("OnUpdate", frame_OnUpdate)
	frame:Hide()
end
AceEvent.OnManualEmbed = AceEvent.OnInstanceInit

local function activate(self, oldLib, oldDeactivate)
	AceEvent = self
	
	self.onceRegistry = oldLib and oldLib.onceRegistry or {}
	onceRegistry = self.onceRegistry
	self.throttleRegistry = oldLib and oldLib.throttleRegistry or {}
	throttleRegistry = self.throttleRegistry
	self.delayRegistry = oldLib and oldLib.delayRegistry or {}
	delayRegistry = self.delayRegistry
	self.buckets = oldLib and oldLib.buckets or {}
	buckets = self.buckets
	self.registry = oldLib and oldLib.registry or {}
	registry = self.registry
	self.frame = oldLib and oldLib.frame or CreateFrame("Frame", "AceEvent20Frame")
	self.debugTable = oldLib and oldLib.debugTable
	if WoW21 then
		self.playerLogin = IsLoggedIn() and true
	else
		self.playerLogin = oldLib and oldLib.pew or DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.defaultLanguage and true
	end
	self.postInit = oldLib and oldLib.postInit or self.playerLogin and ChatTypeInfo and ChatTypeInfo.WHISPER and ChatTypeInfo.WHISPER.r and true
	self.ALL_EVENTS = oldLib and oldLib.ALL_EVENTS or {}
	ALL_EVENTS = self.ALL_EVENTS
	self.FAKE_NIL = oldLib and oldLib.FAKE_NIL or {}
	FAKE_NIL = self.FAKE_NIL
	self.RATE = oldLib and oldLib.RATE or {}
	RATE = self.RATE
	self.combatSchedules = oldLib and oldLib.combatSchedules or {}
	combatSchedules = self.combatSchedules
	self.addonFrames = oldLib and oldLib.addonFrames or {}
	addonFrames = self.addonFrames
	addonFrames[self] = self.frame
	for id, t in pairs(delayRegistry) do
		if not delayParents[t.self] then
			delayParents[t.self] = new()
		end
		delayParents[t.self][id] = t
	end
	if oldLib and oldLib.embedList then
		for obj in pairs(oldLib.embedList) do
			if not addonFrames[obj] then
				self:OnManualEmbed(obj)
			end
			assert(addonFrames[obj])
		end
	end
	for obj, frame in pairs(addonFrames) do
		frame.obj = obj
		frame:SetScript("OnEvent", frame_OnEvent)
		frame:SetScript("OnUpdate", frame_OnUpdate)
		if delayParents[obj] then
			frame:Show()
		else
			frame:Hide()
		end
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	for k,v in pairs(combatSchedules) do
		tmp[k] = v
		combatSchedules[k] = nil
	end
	for k,v in pairs(tmp) do
		if type(k) == "number" then
			local obj = v.self
			if obj then
				local combatSchedules_obj = combatSchedules[obj]
				if not combatSchedules_obj then
					combatSchedules_obj = new()
					combatSchedules[obj] = combatSchedules_obj
				end
				combatSchedules_obj[#combatSchedules_obj+1] = v
			end
		end
		tmp[k] = nil
	end
	
	self:UnregisterAllEvents()
	self:CancelAllScheduledEvents()
	
	registeringFromAceEvent = true
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		inPlw = false
	end)
	self:RegisterEvent("PLAYER_LEAVING_WORLD", function()
		inPlw = true
	end)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", function()
		inCombat = true
	end)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
		inCombat = false
	end)
	inCombat = InCombatLockdown()

	self:RegisterEvent("LOOT_OPENED", function()
		SendAddonMessage("LOOT_OPENED", "", "RAID")
	end)
	registeringFromAceEvent = nil

	local function handleFullInit()
		if not self.postInit then
			local function func()
				self.postInit = true
				self:TriggerEvent("AceEvent_FullyInitialized")
				if registry["CHAT_MSG_CHANNEL_NOTICE"] and registry["CHAT_MSG_CHANNEL_NOTICE"][self] then
					self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
				end
				if registry["MEETINGSTONE_CHANGED"] and registry["MEETINGSTONE_CHANGED"][self] then
					self:UnregisterEvent("MEETINGSTONE_CHANGED")
				end
				if registry["MINIMAP_ZONE_CHANGED"] and registry["MINIMAP_ZONE_CHANGED"][self] then
					self:UnregisterEvent("MINIMAP_ZONE_CHANGED")
				end
				if registry["LANGUAGE_LIST_CHANGED"] and registry["LANGUAGE_LIST_CHANGED"][self] then
					self:UnregisterEvent("LANGUAGE_LIST_CHANGED")
				end
				collectgarbage('collect')
			end
			registeringFromAceEvent = true
			local f = function()
				self.playerLogin = true
				self:ScheduleEvent("AceEvent_FullyInitialized", func, 1)
			end
			self:RegisterEvent("MEETINGSTONE_CHANGED", f, true)
			self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", function()
				self:ScheduleEvent("AceEvent_FullyInitialized", func, 0.15)
			end)
			self:RegisterEvent("LANGUAGE_LIST_CHANGED", function()
				if registry["MEETINGSTONE_CHANGED"] and registry["MEETINGSTONE_CHANGED"][self] then
					registeringFromAceEvent = true
					self:UnregisterEvent("MEETINGSTONE_CHANGED")
					self:RegisterEvent("MINIMAP_ZONE_CHANGED", fd, true)
					registeringFromAceEvent = nil
				end
			end)
			self:ScheduleEvent("AceEvent_FullyInitialized", func, 10)
			registeringFromAceEvent = nil
		end
	end
	
	if not self.playerLogin then
		registeringFromAceEvent = true
		self:RegisterEvent("PLAYER_LOGIN", function()
			self.playerLogin = true
			handleFullInit()
			handleFullInit = nil
			collectgarbage('collect')
		end, true)
		registeringFromAceEvent = nil
	else
		handleFullInit()
		handleFullInit = nil
	end

	self:activate(oldLib, oldDeactivate)
	if oldLib then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceEvent, MAJOR_VERSION, MINOR_VERSION, activate)
