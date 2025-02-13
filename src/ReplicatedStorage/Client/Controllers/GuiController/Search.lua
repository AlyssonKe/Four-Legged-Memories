return function(textBox, frame)
	local InputText = string.upper(textBox.Text)
	if frame then
		for _, v in pairs(frame:GetChildren()) do
			local itemName: string = v:GetAttribute("SearchName") or v.Name
			if v:IsA("TextButton") or v:IsA("ImageButton") or v:IsA("Frame") or v:IsA("ImageLabel") then
				if InputText == "" or string.find(string.upper(itemName), InputText) ~= nil then
					v.Visible = true
				else
					v.Visible = false
				end
			end
		end
	end
end
