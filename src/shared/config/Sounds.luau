--!strict
-- Sounds.luau
-- Clean, natural audio configuration with pleasant defaults and safe fallbacks.
-- Per PHASES_9_PLUS.md, slots can be empty strings ("") to silently skip,
-- or contain verified safe Roblox audio IDs / pleasant built-in sounds.

export type SoundConfig = {
	Id: string,
	FallbackId: string,
	Volume: number,
	PitchMin: number,
	PitchMax: number,
	Looped: boolean?,
}

return {
	Enabled = true,
	MasterVolume = 0.35, -- Gentle, non-fatiguing volume

	Effects = {
		-- Clean: Soft, subtle debris sweep / suction sound instead of harsh electronic beeps
		Clean = {
			Id = "rbxasset://sounds/action_footstep_plastic.mp3",
			FallbackId = "rbxasset://sounds/action_footstep_plastic.mp3",
			Volume = 0.18,
			PitchMin = 1.1,
			PitchMax = 1.35,
		},

		-- Sell: Pleasant, clean chime when selling bag contents
		Sell = {
			Id = "rbxasset://sounds/button.wav",
			FallbackId = "rbxasset://sounds/button.wav",
			Volume = 0.35,
			PitchMin = 1.2,
			PitchMax = 1.35,
		},

		-- Reward: Satisfying level/daily reward sound
		Reward = {
			Id = "rbxasset://sounds/button.wav",
			FallbackId = "rbxasset://sounds/button.wav",
			Volume = 0.4,
			PitchMin = 1.4,
			PitchMax = 1.5,
		},

		-- Pet: Cheerful celebration chime when uncovering a pet
		Pet = {
			Id = "rbxasset://sounds/button.wav",
			FallbackId = "rbxasset://sounds/button.wav",
			Volume = 0.45,
			PitchMin = 1.5,
			PitchMax = 1.7,
		},

		-- ButtonClick: Soft, standard UI click
		ButtonClick = {
			Id = "rbxasset://sounds/button.wav",
			FallbackId = "rbxasset://sounds/button.wav",
			Volume = 0.2,
			PitchMin = 0.98,
			PitchMax = 1.02,
		},

		-- BrushSweep: Natural soft brush sweep
		BrushSweep = {
			Id = "rbxasset://sounds/action_footstep_plastic.mp3",
			FallbackId = "rbxasset://sounds/action_footstep_plastic.mp3",
			Volume = 0.15,
			PitchMin = 1.0,
			PitchMax = 1.25,
		},
	},

	Ambience = {
		SpaceWind = {
			Id = "",
			FallbackId = "",
			Volume = 0.08,
			Looped = true,
		},
	},
}
