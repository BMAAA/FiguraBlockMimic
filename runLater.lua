local timers = {}

local function runLater(ticks,next)
    table.insert(timers,{t=world.getTime()+ticks,n=next})
end

events.TICK:register(function()
    for key,timer in pairs(timers) do
        if world.getTime() >= timer.t then
            timer.n()
            timers[key] = nil
        end
    end
end)

return runLater