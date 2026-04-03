local ATS2 = getgenv().ATS2
local UIS = game:GetService("UserInputService")

local UI = {}
local hotkeyBound = false

function UI.init()
    warn("[ATS2/UI] init version:", ATS2 and ATS2.Version)

    if hotkeyBound then
        return
    end
    hotkeyBound = true

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        if input.KeyCode == Enum.KeyCode.RightControl then
            if ATS2.isStopped() then
                ATS2.resume()
                warn("[ATS2/UI] resumed by hotkey")
            else
                ATS2.stop("RightControl hotkey")
                warn("[ATS2/UI] stopped by hotkey")
            end
        end
    end)
end

return UI