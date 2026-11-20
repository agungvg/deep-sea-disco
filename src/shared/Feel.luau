--!strict
-- Deep Sea Disco: the one frozen feel table. Every juice number lives here
-- so a designer reads it in one screen and nothing drifts apart.
-- (P-29: tune feel from one frozen table.)

local Feel = table.freeze({
	-- Camera shake (trauma model).
	ShakeAddPickup = 0.12,
	ShakeAddSteal = 0.5,
	ShakeAddHurt = 0.3,
	ShakeAddEvent = 0.2,
	ShakeDecay = 1.3,
	ShakeMaxAngleDeg = 2.5,

	-- Hit-stop: freeze animation tracks, never physics.
	HitStopLight = 0.06,
	HitStopHeavy = 0.12,

	-- Movement forgiveness.
	CoyoteTime = 0.12,
	JumpBuffer = 0.12,

	-- Pickup pop.
	PickupPopScale = 1.25,
	PickupPopTime = 0.2,

	-- Floating income labels.
	LabelRiseTime = 1.1,
	LabelRiseHeight = 2.5,
	LabelPoolSize = 24,

	-- Event banner.
	BannerInTime = 0.35,
	BannerHoldTime = 2.6,
	BannerOutTime = 0.3,

	-- Squash and stretch.
	SquashAmount = 0.3,
	SquashTime = 0.12,
	IdleBreatheAmount = 0.03,
	IdleBreathePeriod = 2.4,

	-- Count-up numbers.
	CountUpTime = 0.6,

	-- Particles.
	ParticleBurst = 12,
	ParticleBurstBig = 24,
	ParticleLife = 0.45,
})

return Feel
