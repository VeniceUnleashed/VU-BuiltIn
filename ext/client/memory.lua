local drawMemoryStats = false

Console:Register('DrawMemoryStats', 'Draw VeniceEXT memory stats for all loaded mods.', function(args)
	if #args == 0 then
		return tostring(drawMemoryStats)
	end

	if #args ~= 1 then
		return 'Usage: _vu.DrawMemoryStats_ <*true* | *false*>'
	end

	local firstArg = args[1]:lower()

	if firstArg == '1' or firstArg == 'y' or firstArg == 'true' or firstArg == 'on' then
		drawMemoryStats = true
		return 'true'
	elseif firstArg == '0' or firstArg == 'n' or firstArg == 'false' or firstArg == 'off' then
		drawMemoryStats = false
		return 'false'
	else
		return 'Usage: _vu.DrawMemoryStats_ <*true* | *false*>'
	end
end)

Events:Subscribe('UI:DrawHud', function()
	if drawMemoryStats then
		local stats = BuiltinUtils:GetTotalMemoryUsage()

		local currentY = 20

		DebugRenderer:DrawText2D(20, currentY, '[Mod memory usage]', Vec4(0, 1, 0, 1), 1.0)
		currentY = currentY + 20

		for mod, usage in pairs(stats) do
			local usageMb = string.format('%.2f', usage / 1024.0 / 1024.0)
			DebugRenderer:DrawText2D(20, currentY, mod .. ' => ' .. usageMb .. 'MB ('.. tostring(usage) .. ')', Vec4(0, 1, 0, 1), 1.0)
			currentY = currentY + 20
		end
	end
end)