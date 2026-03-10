local UserInputService = game:GetService("UserInputService")
local Input = {}

function Input.IsInputPressed(key)
    if not key then return false end
    if key.EnumType == Enum.KeyCode then
        return UserInputService:IsKeyDown(key)
    elseif key.EnumType == Enum.UserInputType then
        if key.Name:match("MouseButton") then
            return UserInputService:IsMouseButtonPressed(key)
        end
    end
    return false
end

return Input
