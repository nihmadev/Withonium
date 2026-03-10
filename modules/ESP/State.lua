local CoreGui = game:GetService("CoreGui")

local State = {
    Data = {},
    Highlights = {},
    Labels = {},
    Skeletons = {},
    Healthbars = {},
    Container = nil
}

function State.GetContainer()
    if not State.Container or not State.Container.Parent then
        local success, folder = pcall(function()
            local f = Instance.new("Folder")
            f.Name = "WithoniumESP"
            f.Parent = (gethui and gethui()) or CoreGui
            return f
        end)
        if success then
            State.Container = folder
        end
    end
    return State.Container
end

function State.Create(player)
    if not State.Data[player] then
        State.Data[player] = {
            LastCharacter = nil
        }
    end
end

return State
