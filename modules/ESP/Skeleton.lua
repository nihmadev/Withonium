local State = require("modules/ESP/State")

local Skeleton = {}

local R15_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

function Skeleton.Draw(player, character, Settings)
    if not State.Skeletons[player] then
        State.Skeletons[player] = {}
    end

    local skeleton = State.Skeletons[player]
    local isR15 = character:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and R15_BONES or R6_BONES

    -- Clear extra lines if type changed
    if #skeleton > #bones then
        for i = #bones + 1, #skeleton do
            skeleton[i]:Destroy()
            skeleton[i] = nil
        end
    end

    for i, bonePair in ipairs(bones) do
        local part1 = character:FindFirstChild(bonePair[1])
        local part2 = character:FindFirstChild(bonePair[2])

        if part1 and part2 then
            if not skeleton[i] then
                local line = Instance.new("LineHandleAdornment")
                line.Name = "BoneLine_" .. i
                line.Length = 0
                line.Thickness = 2
                line.ZIndex = 10
                line.AlwaysOnTop = true
                line.Transparency = 0
                line.Parent = State.GetContainer()
                skeleton[i] = line
            end

            local line = skeleton[i]
            local p1 = part1.Position
            local p2 = part2.Position
            local dist = (p1 - p2).Magnitude

            line.Visible = true
            line.Color3 = Settings.espSkeletonColor
            line.Transparency = 0
            line.Adornee = part1
            line.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), part1.CFrame:PointToObjectSpace(p2))
            line.Length = dist
        else
            if skeleton[i] then
                skeleton[i].Visible = false
            end
        end
    end
end

function Skeleton.Cleanup(player)
    if State.Skeletons[player] then
        for _, line in pairs(State.Skeletons[player]) do
            line.Visible = false
        end
    end
end

function Skeleton.Destroy(player)
    if State.Skeletons[player] then
        for _, line in pairs(State.Skeletons[player]) do
            line:Destroy()
        end
        State.Skeletons[player] = nil
    end
end

return Skeleton
