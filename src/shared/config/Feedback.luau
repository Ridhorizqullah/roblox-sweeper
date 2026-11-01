--!strict
local Sounds = require(script.Parent.Sounds)

return {
	Duration = 0.8,
	Rise = 3,
	MaximumEffects = 24,
	CleanSize = 0.6,
	CleanExpansion = 2.5,
	RequestCooldown = 1,
	SoundVolume = Sounds.MasterVolume,
	Sounds = {
		Clean = Sounds.Effects.Clean.Id,
		Sell = Sounds.Effects.Sell.Id,
		Reward = Sounds.Effects.Reward.Id,
		Pet = Sounds.Effects.Pet.Id,
		ButtonClick = Sounds.Effects.ButtonClick.Id,
	},
	SoundConfigs = Sounds.Effects,
}
