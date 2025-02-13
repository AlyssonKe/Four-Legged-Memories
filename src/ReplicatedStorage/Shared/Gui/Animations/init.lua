local Module = {}

for _, v in script:GetChildren() do
	if v:IsA("ModuleScript") then
		Module[v.Name] = require(v)
	end
end

return Module
