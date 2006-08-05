--[[
Name: AceEvent-2.0
Revision: $Rev$
Author(s): ckknight (ckknight@gmail.com)
	facboy (<email here>)
Inspired By: AceEvent 1.x by Turan (<email here>)
Website: http://www.wowace.com/
Documentation: http://wiki.wowace.com/index.php/AceEvent-2.0
SVN: http://svn.wowace.com/root/trunk/Ace2/AceEvent-2.0
Description: Mixin to allow for event handling, scheduling, and inter-addon
             communication.
Dependencies: AceLibrary, AceOO-2.0
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
					   }

local new, del
do
	local list = setmetatable({}, {__mode="k"})
	function new()
		local t = next(list)
		if t then
			list[t] = nil
			return t
		else
			return {}
		end
	end
	
	function del(t)
		setmetatable(t, nil)
		for k in pairs(t) do
			t[k] = nil
		end
		table.setn(t, 0)
		list[t] = true
	end
end

local registeringFromAceEvent
function AceEvent:RegisterEvent(event, method, once)
	AceEvent:argCheck(event, 2, "string")
	if self == AceEvent and not registeringFromAceEvent then
		AceEvent:argCheck(method, 3, "function")
		self = method
	else
		AceEvent:argCheck(method, 3, "string", "function", "nil")
	end
	AceEvent:argCheck(once, 4, "boolean", "nil")
	if not method then
		method = event
	end
	if type(method) == "string" and type(self[method]) ~= "function" then
		AceEvent:error("Cannot register event %q to method %q, it does not exist", event, method)
	end

	local AceEvent_registry = AceEvent.registry
	if not AceEvent_registry[event] then
		AceEvent_registry[event] = new()
		AceEvent.frame:RegisterEvent(event)
	end
	
	local remember = true
	if AceEvent_registry[event][self] then
		remember = false
	end
	AceEvent_registry[event][self] = method
	
	if once then
		local AceEvent_onceRegistry = AceEvent.onceRegistry
		if not AceEvent_onceRegistry then
			AceEvent.onceRegistry = new()
			AceEvent_onceRegistry = AceEvent.onceRegistry
		end
		if not AceEvent_onceRegistry[event] then
			AceEvent_onceRegistry[event] = new()
		end
		AceEvent_onceRegistry[event][self] = true
	else
		if AceEvent_onceRegistry and AceEvent_onceRegistry[event] then
			AceEvent_onceRegistry[event][self] = nil
			if not next(AceEvent_onceRegistry[event]) then
				AceEvent_onceRegistry[event] = del(AceEvent_onceRegistry[event])
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
	
	if not AceEvent.registry[ALL_EVENTS] then
		AceEvent.registry[ALL_EVENTS] = new()
		AceEvent.frame:RegisterAllEvents()
	end
	
	AceEvent.registry[ALL_EVENTS][self] = method
end

local _G = getfenv(0)
function AceEvent:TriggerEvent(event, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	AceEvent:argCheck(event, 2, "string")
	local AceEvent_registry = AceEvent.registry
	if (not AceEvent_registry[event] or not next(AceEvent_registry[event])) and (not AceEvent_registry[ALL_EVENTS] or not next(AceEvent_registry[ALL_EVENTS])) then
		return
	end
	local _G_event = _G.event
	_G.event = event

	local AceEvent_onceRegistry = AceEvent.onceRegistry
	local AceEvent_debugTable = AceEvent.debugTable
	if AceEvent_onceRegistry and AceEvent_onceRegistry[event] then
		local obj
		while true do
			obj = next(AceEvent_onceRegistry[event])
			if not obj then
				return
			end
			local mem, time
			if AceEvent_debugTable then
				if not AceEvent_debugTable[event] then
					AceEvent_debugTable[event] = new()
				end
				if not AceEvent_debugTable[event][obj] then
					AceEvent_debugTable[event][obj] = new()
					AceEvent_debugTable[event][obj].mem = 0
					AceEvent_debugTable[event][obj].time = 0
				end
				mem, time = gcinfo(), GetTime()
			end
			local method = AceEvent_registry[event] and AceEvent_registry[event][obj]
			if not method then
				break
			end
			AceEvent.UnregisterEvent(obj, event)
			if type(method) == "string" then
				local obj_method = obj[method]
				if obj_method then
					obj_method(obj, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
				end
			elseif method then -- function
				method(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
			end
			if AceEvent_debugTable then
				mem, time = mem - gcinfo(), time - GetTime()
				AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
				AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
			end
			if not AceEvent_onceRegistry[event] or not next(AceEvent_onceRegistry[event]) then
				break
			end
		end
	end
	if AceEvent_registry[event] then
		local tmp = new()
		for obj, method in pairs(AceEvent_registry[event]) do
			tmp[obj] = method
		end
		local obj = next(tmp)
		while obj do
			local method = tmp[obj]
			local mem, time
			if AceEvent_debugTable then
				if not AceEvent_debugTable[event] then
					AceEvent_debugTable[event] = new()
				end
				if not AceEvent_debugTable[event][obj] then
					AceEvent_debugTable[event][obj] = new()
					AceEvent_debugTable[event][obj].mem = 0
					AceEvent_debugTable[event][obj].time = 0
				end
				mem, time = gcinfo(), GetTime()
			end
			if type(method) == "string" then
				local obj_method = obj[method]
				if obj_method then
					obj_method(obj, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
				end
			elseif method then -- function
				method(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
			end
			if AceEvent_debugTable then
				mem, time = mem - gcinfo(), time - GetTime()
				AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
				AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
			end
			tmp[obj] = nil
			obj = next(tmp)
		end
		del(tmp)
	end
	if AceEvent_registry[ALL_EVENTS] then
		local tmp = new()
		for obj, method in pairs(AceEvent_registry[ALL_EVENTS]) do
			tmp[obj] = method
		end
		local obj = next(tmp)
		while obj do
			local method = tmp[obj]
			local mem, time
			if AceEvent_debugTable then
				if not AceEvent_debugTable[event] then
					AceEvent_debugTable[event] = new()
				end
				if not AceEvent_debugTable[event][obj] then
					AceEvent_debugTable[event][obj] = new()
					AceEvent_debugTable[event][obj].mem = 0
					AceEvent_debugTable[event][obj].time = 0
				end
				mem, time = gcinfo(), GetTime()
			end
			if type(method) == "string" then
				local obj_method = obj[method]
				if obj_method then
					obj_method(obj, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
				end
			elseif method then -- function
				method(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
			end
			if AceEvent_debugTable then
				mem, time = mem - gcinfo(), time - GetTime()
				AceEvent_debugTable[event][obj].mem = AceEvent_debugTable[event][obj].mem + mem
				AceEvent_debugTable[event][obj].time = AceEvent_debugTable[event][obj].time + time
			end
			tmp[obj] = nil
			obj = next(tmp)
		end
		del(tmp)
	end
	_G.event = _G_event
end

--------------------
-- schedule heap management
--------------------

-- local accessors
local getn = table.getn
local setn = table.setn
local tinsert = table.insert
local tremove = table.remove
local floor = math.floor

--------------------
-- sifting functions
local function hSiftUp(heap, pos, schedule)
	schedule = schedule or heap[pos]
	local scheduleTime = schedule.time
	
	local curr, i = pos, floor(pos/2)
	local parent = heap[i]
	while i > 0 and scheduleTime < parent.time do
		heap[curr], parent.i = parent, curr
		curr, i = i, floor(i/2)
		parent = heap[i]
	end
	heap[curr], schedule.i = schedule, curr
	return pos ~= curr
end

local function hSiftDown(heap, pos, schedule, size)
	schedule, size = schedule or heap[pos], size or getn(heap)
	local scheduleTime = schedule.time
	
	local curr = pos
	repeat
		local child, childTime, c
		-- determine the child to compare with
		local j = 2 * curr
		if j > size then
			break
		end
		local k = j + 1
		if k > size then
			child = heap[j]
			childTime, c = child.time, j
		else
			local childj, childk = heap[j], heap[k]
			local jTime, kTime = childj.time, childk.time
			if jTime < kTime then
				child, childTime, c = childj, jTime, j
			else
				child, childTime, c = childk, kTime, k
			end
		end
		-- do the comparison
		if scheduleTime <= childTime then
			break
		end
		heap[curr], child.i = child, curr
		curr = c
	until false
	heap[curr], schedule.i = schedule, curr
	return pos ~= curr
end

--------------------
-- heap functions
local function hMaintain(heap, pos, schedule, size)
	schedule, size = schedule or heap[pos], size or getn(heap)
	if not hSiftUp(heap, pos, schedule) then
		hSiftDown(heap, pos, schedule, size)
	end
end

local function hPush(heap, schedule)
	tinsert(heap, schedule)
	hSiftUp(heap, getn(heap), schedule)
end

local function hPop(heap)
	local head, tail = heap[1], tremove(heap)
	local size = getn(heap)
	
	if size == 1 then
		heap[1], tail.i = tail, 1
	elseif size > 1 then
		hSiftDown(heap, 1, tail, size)
	end
	return head
end

local function hDelete(heap, pos)
	local size = getn(heap)
	local tail = tremove(heap)
	if pos < size then
		size = size - 1
		if size == 1 then
			heap[1], tail.i = tail, 1
		elseif size > 1 then
			heap[pos] = tail
			hMaintain(heap, pos, tail, size)
		end
	end
end

local GetTime = GetTime
local delayRegistry
local delayHeap
local function OnUpdate()
	local t = GetTime()
	-- peek at top of heap
	local v = delayHeap[1]
	local v_time = v and v.time
	while v and v_time <= t do
		local v_repeatDelay = v.repeatDelay
		if v_repeatDelay then
			-- use the event time, not the current time, else timing inaccuracies add up over time
			v.time = v_time + v_repeatDelay
			-- re-arrange the heap
			hSiftDown(delayHeap, 1, v)
		else
			-- pop the event off the heap, and delete it from the registry
			hPop(delayHeap)
			delayRegistry[v.id] = nil
		end
		local event = v.event
		if type(event) == "function" then
			event(unpack(v))
		else
			AceEvent:TriggerEvent(event, unpack(v))
		end
		if not v_repeatDelay then
			del(v)
		end
		v = delayHeap[1]
		v_time = v and v.time
	end
	if not v then
		AceEvent.frame:Hide()
	end
end

local function ScheduleEvent(self, repeating, event, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	local id
	if type(event) == "string" or type(event) == "table" then
		if type(event) == "table" then
			if not delayRegistry or not delayRegistry[event] then
				AceEvent:error("Bad argument #2 to `ScheduleEvent'. Improper id table fed in.")
			end
		end
		if type(delay) ~= "number" then
			id, event, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20 = event, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20
			AceEvent:argCheck(event, 3, "string", "function", --[[ so message is right ]] "number")
			AceEvent:argCheck(delay, 4, "number")
			self:CancelScheduledEvent(id)
		end
	else
		AceEvent:argCheck(event, 2, "string", "function")
		AceEvent:argCheck(delay, 3, "number")
	end

	if not delayRegistry then
		AceEvent.delayRegistry = new()
		AceEvent.delayHeap = new()
		AceEvent.delayHeap.n = 0
		delayRegistry = AceEvent.delayRegistry
		delayHeap = AceEvent.delayHeap
		AceEvent.frame:SetScript("OnUpdate", OnUpdate)
	end
	local t
	if type(id) == "table" then
		for k in pairs(id) do
			id[k] = nil
		end
		table.setn(id, 0)
		t = id
	else
		t = new()
	end
	t.n = 0
	tinsert(t, a1)
	tinsert(t, a2)
	tinsert(t, a3)
	tinsert(t, a4)
	tinsert(t, a5)
	tinsert(t, a6)
	tinsert(t, a7)
	tinsert(t, a8)
	tinsert(t, a9)
	tinsert(t, a10)
	tinsert(t, a11)
	tinsert(t, a12)
	tinsert(t, a13)
	tinsert(t, a14)
	tinsert(t, a15)
	tinsert(t, a16)
	tinsert(t, a17)
	tinsert(t, a18)
	tinsert(t, a19)
	tinsert(t, a20)
	t.event = event
	t.time = GetTime() + delay
	t.self = self
	t.id = id or t
	t.repeatDelay = repeating and delay
	delayRegistry[t.id] = t
	-- insert into heap
	hPush(delayHeap, t)
	AceEvent.frame:Show()
	return t.id
end

function AceEvent:ScheduleEvent(event, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	if type(event) == "string" or type(event) == "table" then
		if type(event) == "table" then
			if not delayRegistry or not delayRegistry[event] then
				AceEvent:error("Bad argument #2 to `ScheduleEvent'. Improper id table fed in.")
			end
		end
		if type(delay) ~= "number" then
			AceEvent:argCheck(delay, 3, "string", "function", --[[ so message is right ]] "number")
			AceEvent:argCheck(a1, 4, "number")
		end
	else
		AceEvent:argCheck(event, 2, "string", "function")
		AceEvent:argCheck(delay, 3, "number")
	end
	
	return ScheduleEvent(self, false, event, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
end

function AceEvent:ScheduleRepeatingEvent(event, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
	if type(event) == "string" or type(event) == "table" then
		if type(event) == "table" then
			if not delayRegistry or not delayRegistry[event] then
				AceEvent:error("Bad argument #2 to `ScheduleEvent'. Improper id table fed in.")
			end
		end
		if type(delay) ~= "number" then
			AceEvent:argCheck(delay, 3, "string", "function", --[[ so message is right ]] "number")
			AceEvent:argCheck(a1, 4, "number")
		end
	else
		AceEvent:argCheck(event, 2, "string", "function")
		AceEvent:argCheck(delay, 3, "number")
	end
	
	return ScheduleEvent(self, true, event, delay, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
end

function AceEvent:CancelScheduledEvent(t)
	AceEvent:argCheck(t, 2, "string", "table")
	if delayRegistry then
		local v = delayRegistry[t]
		if v then
			hDelete(delayHeap, v.i)
			delayRegistry[t] = nil
			del(v)
			if not next(delayRegistry) then
				AceEvent.frame:Hide()
			end
			return true
		end
	end
	return false
end

function AceEvent:IsEventScheduled(t)
	AceEvent:argCheck(t, 2, "string", "table")
	if delayRegistry then
		local v = delayRegistry[t]
		if v then
			return true, v.time - GetTime()
		end
	end
	return false, nil
end


function AceEvent:IsEventRegistered(event)
	AceEvent:argCheck(event, 2, "string")
	local AceEvent_registry = AceEvent.registry
	if self == AceEvent then
		return AceEvent_registry[event] and next(AceEvent_registry[event]) and true or false
	end
	if AceEvent_registry[event] and AceEvent_registry[event][self] then
		return true, AceEvent_registry[event][self]
	end
	return false, nil
end

function AceEvent:UnregisterEvent(event)
	AceEvent:argCheck(event, 2, "string")
	local AceEvent_registry = AceEvent.registry
	if AceEvent_registry[event] and AceEvent_registry[event][self] then
		AceEvent_registry[event][self] = nil
		local AceEvent_onceRegistry = AceEvent.onceRegistry
		if AceEvent_onceRegistry[event] and AceEvent_onceRegistry[event][self] then
			AceEvent_onceRegistry[event][self] = nil
			if not next(AceEvent_registry[event]) then
				AceEvent_onceRegistry[event] = del(AceEvent_onceRegistry[event])
			end
		end
		if not next(AceEvent_registry[event]) then
			AceEvent_registry[event] = del(AceEvent_registry[event])
			if not AceEvent_registry[ALL_EVENTS] or not next(AceEvent_registry[ALL_EVENTS]) then
				AceEvent.frame:UnregisterEvent(event)
			end
		end
	else
		if self == AceEvent then
			error(string.format("Cannot unregister event %q. Improperly unregistering from AceEvent-2.0.", event), 2)
		else
			AceEvent:error("Cannot unregister event %q. %q is not registered with it.", event, self)
		end
	end
	AceEvent:TriggerEvent("AceEvent_EventUnregistered", self, event)
end

function AceEvent:UnregisterAllEvents()
	local AceEvent_registry = AceEvent.registry
	if AceEvent_registry[ALL_EVENTS] and AceEvent_registry[ALL_EVENTS][self] then
		AceEvent_registry[ALL_EVENTS][self] = nil
		if not next(AceEvent_registry[ALL_EVENTS]) then
			del(AceEvent_registry[ALL_EVENTS])
			AceEvent.frame:UnregisterAllEvents()
			for k,v in pairs(AceEvent_registry) do
				if k ~= ALL_EVENTS then
					AceEvent.frame:RegisterEvent(k)
				end
			end
			AceEvent_registry[event] = nil
		end
	end
	local first = true
	for event, data in pairs(AceEvent_registry) do
		if first then
			if AceEvent_registry.AceEvent_EventUnregistered then
				event = "AceEvent_EventUnregistered"
			else
				first = false
			end
		end
		local x = data[self]
		data[self] = nil
		if x and event ~= ALL_EVENTS then
			if not next(data) then
				del(data)
				if not AceEvent_registry[ALL_EVENTS] or not next(AceEvent_registry[ALL_EVENTS]) then
					AceEvent.frame:UnregisterEvent(event)
				end
				AceEvent_registry[event] = nil
			end
			AceEvent:TriggerEvent("AceEvent_EventUnregistered", self, event)
		end
		if first then
			event = nil
		end
	end
	if AceEvent.onceRegistry then
		for event, data in pairs(AceEvent.onceRegistry) do
			data[self] = nil
		end
	end
end

function AceEvent:CancelAllScheduledEvents()
	if delayRegistry then
		for k,v in pairs(delayRegistry) do
			if v.self == self then
				hDelete(delayHeap, v.i)
				del(v)
				delayRegistry[k] = nil
			end
		end
		if not next(delayRegistry) then
			AceEvent.frame:Hide()
		end
	end
end

function AceEvent:IsEventRegistered(event)
	AceEvent:argCheck(event, 2, "string")
	local AceEvent_registry = AceEvent.registry
	if self == AceEvent then
		return AceEvent_registry[event] and next(AceEvent_registry[event]) and true or false
	end
	if AceEvent_registry[event] and AceEvent_registry[event][self] then
		return true, AceEvent_registry[event][self]
	end
	return false, nil
end

local bucketfunc
function AceEvent:RegisterBucketEvent(event, delay, method)
	AceEvent:argCheck(event, 2, "string", "table")
	if type(event) == "table" then
		for k,v in pairs(event) do
			if type(k) ~= "number" then
				AceEvent:error("All keys to argument #2 to `RegisterBucketEvent' must be numbers.")
			elseif type(k) ~= "string" then
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
	if not AceEvent.buckets then
		AceEvent.buckets = new()
	end
	if not AceEvent.buckets[event] then
		AceEvent.buckets[event] = new()
	end
	if not AceEvent.buckets[event][self] then
		AceEvent.buckets[event][self] = new()
		AceEvent.buckets[event][self].current = new()
		AceEvent.buckets[event][self].self = self
	else
		AceEvent:CancelScheduledEvent(AceEvent.buckets[event][self].id)
	end
	local bucket = AceEvent.buckets[event][self]
	bucket.method = method
	
	local func = function(arg1)
		if arg1 then
			bucket.current[arg1] = true
		end
	end
	AceEvent.buckets[event][self].func = func
	if type(event) == "string" then
		AceEvent:RegisterEvent(event, func)
	else
		for _,v in ipairs(event) do
			AceEvent:RegisterEvent(v, func)
		end
	end
	if not bucketfunc then
		bucketfunc = function(bucket)
			local current = bucket.current
			local method = bucket.method
			local self = bucket.self
			if next(current) then
				if type(method) == "string" then
					self[method](self, current)
				elseif method then -- function
					method(current)
				end
				for k in pairs(current) do
					current[k] = nil
				end
			end
		end
	end
	bucket.id = AceEvent:ScheduleRepeatingEvent(bucketfunc, delay, bucket)
end

function AceEvent:IsBucketEventRegistered(event)
	AceEvent:argCheck(event, 2, "string", "table")
	return AceEvent.buckets and AceEvent.buckets[event] and AceEvent.buckets[event][self]
end

function AceEvent:UnregisterBucketEvent(event)
	AceEvent:argCheck(event, 2, "string", "table")
	if not AceEvent.buckets or not AceEvent.buckets[event] or not AceEvent.buckets[event][self] then
		AceEvent:error("Cannot unregister bucket event %q. %q is not registered with it.", event, self)
	end
	
	local bucket = AceEvent.buckets[event][self]
	
	if type(event) == "string" then
		AceEvent.UnregisterEvent(bucket.func, event)
	else
		for _,v in ipairs(event) do
			AceEvent.UnregisterEvent(bucket.func, v)
		end
	end
	AceEvent:CancelScheduledEvent(bucket.id)
	
	del(bucket.current)
	AceEvent.buckets[event][self] = del(AceEvent.buckets[event][self])
	if not next(AceEvent.buckets[event]) then
		AceEvent.buckets[event] = del(AceEvent.buckets[event])
	end
end

function AceEvent:UnregisterAllBucketEvents()
	if not AceEvent.buckets or not next(AceEvent.buckets) then
		return
	end
	for k,v in pairs(AceEvent.buckets) do
		if v == self then
			AceEvent.UnregisterBucketEvent(self, k)
			k = nil
		end
	end
end

function AceEvent:OnEmbedDisable(target)
	self.UnregisterAllEvents(target)

	self.CancelAllScheduledEvents(target)
	
	self.UnregisterAllBucketEvents(target)
end

function AceEvent:EnableDebugging()
	if not self.debugTable then
		self.debugTable = new()
	end
end

function AceEvent:IsFullyInitialized()
	return self.postInit or false
end

function AceEvent:IsPostPlayerLogin()
	return self.playerLogin or false
end

function AceEvent:activate(oldLib, oldDeactivate)
	AceEvent = self

	if oldLib then
		self.onceRegistry = oldLib.onceRegistry
		self.delayRegistry = oldLib.delayRegistry
		self.buckets = oldLib.buckets
		self.delayHeap = oldLib.delayHeap
		self.registry = oldLib.registry
		self.frame = oldLib.frame
		self.debugTable = oldLib.debugTable
		self.playerLogin = oldLib.pew or DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.defaultLanguage and true
		self.postInit = oldLib.postInit or self.playerLogin and ChatTypeInfo and ChatTypeInfo.WHISPER and ChatTypeInfo.WHISPER.r and true
		self.ALL_EVENTS = oldLib.ALL_EVENTS
	end
	if not self.registry then
		self.registry = {}
	end
	if not self.frame then
		self.frame = CreateFrame("Frame", "AceEvent20Frame")
	end
	if not self.ALL_EVENTS then
		self.ALL_EVENTS = {}
	end
	ALL_EVENTS = self.ALL_EVENTS
	self.frame:SetScript("OnEvent", function()
		if event then
			self:TriggerEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
		end
	end)
	if self.delayRegistry then
		delayRegistry = self.delayRegistry
		delayHeap = self.delayHeap
		self.frame:SetScript("OnUpdate", OnUpdate)
	end

	self:UnregisterAllEvents()
	self:CancelAllScheduledEvents()

	if not self.playerLogin then
		registeringFromAceEvent = true
		self:RegisterEvent("PLAYER_LOGIN", function()
			self.playerLogin = true
		end, true)
		registeringFromAceEvent = nil
	end

	if not self.postInit then
		local isReload = true
		local function func()
			self.postInit = true
			self:TriggerEvent("AceEvent_FullyInitialized")
			if self.registry["CHAT_MSG_CHANNEL_NOTICE"] and self.registry["CHAT_MSG_CHANNEL_NOTICE"][self] then
				self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
			end
			if self.registry["MEETINGSTONE_CHANGED"] and self.registry["MEETINGSTONE_CHANGED"][self] then
				self:UnregisterEvent("MEETINGSTONE_CHANGED")
			end
			if self.registry["MINIMAP_ZONE_CHANGED"] and self.registry["MINIMAP_ZONE_CHANGED"][self] then
				self:UnregisterEvent("MINIMAP_ZONE_CHANGED")
			end
			if self.registry["SPELLS_CHANGED"] and self.registry["SPELLS_CHANGED"][self] then
				self:UnregisterEvent("SPELLS_CHANGED")
			end
		end
		registeringFromAceEvent = true
		local f = function()
			self.playerLogin = true
			self:ScheduleEvent("AceEvent_FullyInitialized", func, 1)
		end
		self:RegisterEvent("MEETINGSTONE_CHANGED", f, true)
		self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", function()
			self:ScheduleEvent("AceEvent_FullyInitialized", func, 0.05)
		end)
		self:RegisterEvent("SPELLS_CHANGED", function()
			if self.registry["MEETINGSTONE_CHANGED"] and self.registry["MEETINGSTONE_CHANGED"][self] then
				self:UnregisterEvent("MEETINGSTONE_CHANGED")
				self:RegisterEvent("MINIMAP_ZONE_CHANGED", f, true)
			end
		end)
		registeringFromAceEvent = nil
	end

	self.super.activate(self, oldLib, oldDeactivate)
	if oldLib then
		oldDeactivate(oldLib)
	end
end

AceLibrary:Register(AceEvent, MAJOR_VERSION, MINOR_VERSION, AceEvent.activate)
AceEvent = AceLibrary(MAJOR_VERSION)
