--!strict
-- Deep Sea Disco: the full cast. 42 dancing sea critters, 6 tiers of 7.
-- Costs and earnings form one ladder: each tier pays roughly an order of
-- magnitude more than the last, and inside a tier the later critters cost
-- a little more and earn a little more. Sell value is 80% of cost.
-- Every critter is a chibi dancing sea-folk: human-proportioned, two arms,
-- two legs, one signature prop, never a dead-neutral pose.

export type CritterDef = {
	id: string,
	name: string,
	tier: string,
	cost: number,
	earn: number,
	body: Color3,
	accent: Color3,
	shape: string,
	prop: string,
	size: number,
}

local function def(
	id: string,
	name: string,
	tier: string,
	cost: number,
	earn: number,
	body: Color3,
	accent: Color3,
	shape: string,
	prop: string,
	size: number
): CritterDef
	return {
		id = id,
		name = name,
		tier = tier,
		cost = cost,
		earn = earn,
		body = body,
		accent = accent,
		shape = shape,
		prop = prop,
		size = size,
	}
end

local Characters = {}

Characters.List = {
	-- COMMON: cheap, cheerful, everywhere in the Open Water.
	def("bubbles-mcfin", "Bubbles McFin", "Common", 25, 1, Color3.fromRGB(255, 176, 102), Color3.fromRGB(46, 196, 182), "Fish", "Bowtie", 1.0),
	def("sandy-claws", "Sandy Claws", "Common", 40, 2, Color3.fromRGB(255, 122, 89), Color3.fromRGB(232, 201, 138), "Crab", "Headphones", 1.0),
	def("wavy-davy", "Wavy Davy", "Common", 60, 2, Color3.fromRGB(96, 165, 250), Color3.fromRGB(184, 230, 46), "Eel", "Sunglasses", 1.05),
	def("plip-plop", "Plip Plop", "Common", 80, 3, Color3.fromRGB(255, 214, 120), Color3.fromRGB(255, 122, 89), "Clam", "TopHat", 0.95),
	def("shelly-belly", "Shelly Belly", "Common", 100, 4, Color3.fromRGB(214, 178, 140), Color3.fromRGB(46, 196, 182), "Turtle", "Flower", 1.1),
	def("guppy-groovy", "Guppy Groovy", "Common", 125, 5, Color3.fromRGB(255, 205, 105), Color3.fromRGB(255, 122, 89), "Fish", "DiscoBall", 0.9),
	def("kelpy-keeps", "Kelpy Keeps", "Common", 150, 6, Color3.fromRGB(96, 190, 110), Color3.fromRGB(255, 201, 60), "Kelp", "Flower", 1.1),

	-- RARE: the first real dancers.
	def("disco-shrimp", "Disco Shrimp", "Rare", 300, 8, Color3.fromRGB(255, 150, 130), Color3.fromRGB(255, 201, 60), "Shrimp", "DiscoBall", 1.0),
	def("bass-bass", "Bass Bass", "Rare", 400, 11, Color3.fromRGB(70, 130, 180), Color3.fromRGB(184, 230, 46), "Fish", "Headphones", 1.15),
	def("coral-carl", "Coral Carl", "Rare", 500, 14, Color3.fromRGB(255, 122, 89), Color3.fromRGB(255, 214, 120), "Coral", "Crown", 1.05),
	def("jelly-jam", "Jelly Jam", "Rare", 600, 17, Color3.fromRGB(255, 170, 210), Color3.fromRGB(46, 196, 182), "Jelly", "Bowtie", 1.0),
	def("starry-starr", "Starry Starr", "Rare", 700, 20, Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 122, 89), "Star", "Sunglasses", 1.0),
	def("puffer-puff", "Puffer Puff", "Rare", 800, 23, Color3.fromRGB(255, 210, 90), Color3.fromRGB(255, 122, 89), "Puffer", "TopHat", 1.1),
	def("anemone-annie", "Anemone Annie", "Rare", 900, 26, Color3.fromRGB(255, 130, 180), Color3.fromRGB(184, 230, 46), "Anemone", "Flower", 1.0),

	-- EPIC: the floor starts to notice.
	def("electric-eelvis", "Electric Eelvis", "Epic", 1500, 40, Color3.fromRGB(190, 160, 255), Color3.fromRGB(255, 201, 60), "Eel", "Sunglasses", 1.2),
	def("squid-vicious", "Squid Vicious", "Epic", 2000, 55, Color3.fromRGB(150, 120, 220), Color3.fromRGB(46, 196, 182), "Squid", "Headphones", 1.1),
	def("manta-ray-charles", "Manta Ray Charles", "Epic", 2500, 70, Color3.fromRGB(60, 70, 110), Color3.fromRGB(184, 230, 46), "Manta", "Bowtie", 1.35),
	def("lobster-thermidor", "Lobster Thermidor", "Epic", 3000, 85, Color3.fromRGB(230, 70, 50), Color3.fromRGB(255, 201, 60), "Lobster", "TopHat", 1.2),
	def("clammy-carter", "Clammy Carter", "Epic", 3500, 100, Color3.fromRGB(220, 200, 240), Color3.fromRGB(255, 122, 89), "Clam", "Crown", 1.05),
	def("seaweed-sally", "Seaweed Sally", "Epic", 4000, 115, Color3.fromRGB(70, 180, 110), Color3.fromRGB(255, 214, 120), "Kelp", "Flower", 1.15),
	def("urchinator", "Urchinator", "Epic", 5000, 130, Color3.fromRGB(90, 60, 140), Color3.fromRGB(184, 230, 46), "Urchin", "Sunglasses", 1.0),

	-- LEGENDARY: headliners.
	def("kraken-rolling", "Kraken Rolling", "Legendary", 10000, 250, Color3.fromRGB(120, 60, 160), Color3.fromRGB(255, 201, 60), "Kraken", "Crown", 1.5),
	def("sharkira", "Sharkira", "Legendary", 13000, 320, Color3.fromRGB(120, 140, 170), Color3.fromRGB(255, 122, 89), "Shark", "Flower", 1.4),
	def("octo-mami", "Octo Mami", "Legendary", 16000, 400, Color3.fromRGB(255, 140, 180), Color3.fromRGB(46, 196, 182), "Octopus", "Headphones", 1.3),
	def("whaleiam", "Whaleiam", "Legendary", 20000, 500, Color3.fromRGB(90, 120, 200), Color3.fromRGB(255, 214, 120), "Whale", "TopHat", 1.6),
	def("narwhal-norton", "Narwhal Norton", "Legendary", 24000, 580, Color3.fromRGB(200, 220, 255), Color3.fromRGB(255, 201, 60), "Narwhal", "Bowtie", 1.35),
	def("seabass-sebastian", "Seabass Sebastian", "Legendary", 27000, 650, Color3.fromRGB(80, 160, 140), Color3.fromRGB(255, 122, 89), "Fish", "Crown", 1.3),
	def("dolphin-dolly", "Dolphin Dolly", "Legendary", 30000, 720, Color3.fromRGB(140, 180, 230), Color3.fromRGB(184, 230, 46), "Dolphin", "Flower", 1.3),

	-- MYTHIC: the old gods of the dance floor.
	def("leviathan-louie", "Leviathan Louie", "Mythic", 75000, 1500, Color3.fromRGB(40, 90, 110), Color3.fromRGB(184, 230, 46), "Eel", "Crown", 1.7),
	def("poseidon-pete", "Poseidon Pete", "Mythic", 100000, 2000, Color3.fromRGB(60, 140, 190), Color3.fromRGB(255, 201, 60), "Merfolk", "Trident", 1.5),
	def("atlantis-annie", "Atlantis Annie", "Mythic", 130000, 2600, Color3.fromRGB(90, 200, 210), Color3.fromRGB(255, 122, 89), "Merfolk", "Crown", 1.5),
	def("abyssal-abby", "Abyssal Abby", "Mythic", 160000, 3200, Color3.fromRGB(70, 50, 120), Color3.fromRGB(184, 230, 46), "Angler", "GlowRing", 1.4),
	def("tsunami-tammy", "Tsunami Tammy", "Mythic", 190000, 3800, Color3.fromRGB(80, 170, 220), Color3.fromRGB(255, 214, 120), "Wave", "Flower", 1.6),
	def("maelstrom-max", "Maelstrom Max", "Mythic", 220000, 4400, Color3.fromRGB(50, 80, 140), Color3.fromRGB(255, 122, 89), "Whirl", "Headphones", 1.6),
	def("siren-c", "Siren C", "Mythic", 250000, 5000, Color3.fromRGB(220, 160, 255), Color3.fromRGB(46, 196, 182), "Merfolk", "GlowRing", 1.5),

	-- ABYSSAL: only the trench knows their names.
	def("mariana-max", "Mariana Max", "Abyssal", 500000, 10000, Color3.fromRGB(20, 40, 70), Color3.fromRGB(184, 230, 46), "Trench", "GlowRing", 1.8),
	def("trench-titan", "Trench Titan", "Abyssal", 750000, 15000, Color3.fromRGB(60, 60, 90), Color3.fromRGB(255, 122, 89), "Trench", "Crown", 1.9),
	def("bio-lume", "Bio-Lume", "Abyssal", 1000000, 20000, Color3.fromRGB(30, 120, 110), Color3.fromRGB(184, 230, 46), "Angler", "GlowRing", 1.5),
	def("hadal-hank", "Hadal Hank", "Abyssal", 1250000, 25000, Color3.fromRGB(40, 50, 80), Color3.fromRGB(255, 201, 60), "Trench", "TopHat", 1.8),
	def("ventsy", "Ventsy", "Abyssal", 1500000, 30000, Color3.fromRGB(200, 90, 60), Color3.fromRGB(255, 214, 120), "Vent", "Headphones", 1.6),
	def("glowy-mcglow", "Glowy McGlow", "Abyssal", 1750000, 35000, Color3.fromRGB(140, 230, 180), Color3.fromRGB(255, 201, 60), "Angler", "GlowRing", 1.5),
	def("the-abyssal-dj", "The Abyssal DJ", "Abyssal", 2000000, 40000, Color3.fromRGB(30, 30, 50), Color3.fromRGB(184, 230, 46), "Merfolk", "DiscoBall", 1.7),
}

Characters.ById = {}
for _, entry in Characters.List do
	Characters.ById[entry.id] = entry
end

-- Weighted random pick by tier, then a uniform critter inside that tier.
function Characters.roll(rng: Random): CritterDef
	local Config = require(script.Parent.Config)
	local total = 0
	for _, tier in Config.TierOrder do
		total += Config.Tiers[tier].weight
	end
	local roll = rng:NextNumber(0, total)
	local pickedTier = "Common"
	for _, tier in Config.TierOrder do
		roll -= Config.Tiers[tier].weight
		if roll <= 0 then
			pickedTier = tier
			break
		end
	end
	local pool = {}
	for _, entry in Characters.List do
		if entry.tier == pickedTier then
			table.insert(pool, entry)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

return Characters
