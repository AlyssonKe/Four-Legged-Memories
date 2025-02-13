--// Variables
local packages = script.Parent:WaitForChild("Packages")

--// Modules
local ByteNet = require(packages:WaitForChild("ByteNet"))

return {
	-- Tween
	Tween = ByteNet.defineNamespace("tween", function()
		return {
			new = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.struct({
					instance = ByteNet.inst,
					tweenInfo = ByteNet.array(ByteNet.unknown),
					changes = ByteNet.map(ByteNet.string, ByteNet.unknown),
					doNotPlay = ByteNet.optional(ByteNet.bool),
				}),
			}),
			pivot = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.struct({
					instance = ByteNet.inst,
					tweenInfo = ByteNet.array(ByteNet.unknown),
					cframe = ByteNet.unknown,
					doNotPlay = ByteNet.optional(ByteNet.bool),
				}),
			}),
			scale = ByteNet.definePacket({
				reliabilityType = "unreliable",
				value = ByteNet.struct({
					instance = ByteNet.inst,
					tweenInfo = ByteNet.array(ByteNet.unknown),
					size = ByteNet.int8,
					doNotPlay = ByteNet.optional(ByteNet.bool),
				}),
			}),
		}
	end),
}
