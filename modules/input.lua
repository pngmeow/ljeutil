--> [input.lua] <--
--> Adds functions for safely changing viewangles with CUserCmd handles <--

local desiredangle = Angle(0, 0, 0)

lje.input = {}

--> Sets the desired eye angles to the given angle
--- @param angle Angle
--- @return nil
function lje.input.setangle(angle)
    desiredangle[1] = angle[1]
    desiredangle[2] = angle[2]
    desiredangle[3] = angle[3]
end

hook.pre("StartCommand", "__ljeutil_input", function(_, cmd)

end)