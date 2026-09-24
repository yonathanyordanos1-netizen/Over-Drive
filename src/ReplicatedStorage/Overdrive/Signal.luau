--[[
	Signal
	A minimal in-process event. Used for server-side service-to-service
	notifications (DataService telling ShopService a profile loaded) and for
	client screens reacting to a cached profile change.

	A plain Lua implementation rather than a BindableEvent, because Bindables
	deep-copy their arguments -- which would sever the identity of the profile
	tables we pass around, and silently drop keys like nested arrays.
]]

local Signal = {}
Signal.__index = Signal

export type Connection = { Disconnect: (Connection) -> () }

function Signal.new(name: string?)
	return setmetatable({
		_name = name or "Signal",
		_handlers = {},
	}, Signal)
end

function Signal:Connect(handler: (...any) -> ()): Connection
	assert(type(handler) == "function", "Signal:Connect expects a function")

	local handlers = self._handlers
	handlers[handler] = true

	return {
		Disconnect = function()
			handlers[handler] = nil
		end,
	}
end

--[[
	Fires every handler in its own thread, so one bad listener cannot stop the
	rest from running or block the caller. Errors are reported and swallowed:
	a broken UI listener must never abort a data save.
]]
function Signal:Fire(...)
	for handler in self._handlers do
		task.spawn(function(...)
			local ok, err = pcall(handler, ...)
			if not ok then
				warn(string.format("[Overdrive] %s handler errored: %s", self._name, tostring(err)))
			end
		end, ...)
	end
end

function Signal:DisconnectAll()
	table.clear(self._handlers)
end

return Signal
