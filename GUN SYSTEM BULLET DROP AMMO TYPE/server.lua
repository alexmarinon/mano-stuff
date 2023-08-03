local module = {}

-- ROBLOX services:

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerScriptService = game:GetService('ServerScriptService')
local CollectionService = game:GetService('CollectionService')

-- Modules:

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Databases = ReplicatedStorage.Databases

local CombatService = require(script.Parent.Parent)

local FastCast = require(Packages.Shared.FastCastRedux)
local PartCache = require(Packages.Shared.PartCache)

local ItemsDatabase = require(Databases.Items)
local AmmoTypes = ItemsDatabase.Ammo

-- Tables

local RegisteredCasters = {}
local RegisteredBehaviors = {}
local RegisteredCosmeticBullets = {}

-- Math functions

random = math.random

--

local bodyPartToCategory = require(script.Parent.Parent:WaitForChild('BodyPartToCategory'))

-- Variables

local CosmeticBulletsFolder = workspace.ComessticBullets

function constructBehavior(ammoCategory, ammoSubtype)
	local ammoType = AmmoTypes[ammoCategory][ammoSubtype]

	local CastParams = RaycastParams.new()

	local ammoVelocity = 99999 --ammoType.Velocity
	local maxDistance = ammoType.MaxDistance

	CastParams.IgnoreWater = false
	CastParams.FilterType = Enum.RaycastFilterType.Blacklist
	CastParams.FilterDescendantsInstances = {}
	CastParams.RespectCanCollide = false

	local CastBehavior = FastCast.newBehavior()
	CastBehavior.RaycastParams = CastParams
	CastBehavior.MaxDistance = maxDistance
	CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default
	CastBehavior.CanPierceFunction = canBulletPierce

	CastBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0)

	if ammoType.CosmeticBullet ~= nil then
		RegisteredCosmeticBullets[ammoCategory .. ", ".. ammoSubtype] = PartCache.new(ammoType.CosmeticBullet, 100, CosmeticBulletsFolder)

		CastBehavior.CosmeticBulletProvider = RegisteredCosmeticBullets[ammoCategory .. ", ".. ammoSubtype]
		CastBehavior.CosmeticBulletContainer = CosmeticBulletsFolder

		warn(ammoType.CosmeticBullet.Name)
	end

	RegisteredBehaviors[ammoCategory.. ', '.. ammoSubtype] = CastBehavior

end

function constructCaster(ammoCategory, ammoSubtype)
	local ammoType = AmmoTypes[ammoCategory][ammoSubtype]

	local caster = FastCast.new()

	caster.RayPierced:Connect(onBulletPierced)
	caster.RayHit:Connect(onBulletHit)
	caster.CastTerminating:Connect(onBulletTerminated)
	caster.LengthChanged:Connect(onLengthChanged)

	RegisteredCasters[ammoCategory.. ', '.. ammoSubtype] = caster

	return caster
end

function canBulletPierce(cast: Ray, rayResult: RaycastResult, segmentVelocity)
	local bulletType = cast.UserData.BulletType
	local subCategory = cast.UserData.SubCategory
	local damageMultipler = cast.UserData.DamageMultiplier
	local currentHits = cast.UserData.Hits

	local velocity = cast:GetVelocity()

	local lastPartPierced = cast.UserData.LastPartPierced

	if currentHits == nil then
		cast.UserData.Hits = 0
		currentHits = 0
	end
	local instance: Instance = rayResult.Instance
	local material: Enum.Material = rayResult.Material
	local position: Vector3 = rayResult.Position
	local ahead: number = rayResult.Instance.Size.Magnitude	
	local pierceableMaterials = AmmoTypes[bulletType][subCategory].PierceableMaterials
	local maxHits = AmmoTypes[bulletType][subCategory].MaxPierceAmount
	if instance:IsA('BasePart') and instance.CanCollide == true then

		-- Double check
		if instance:IsDescendantOf(workspace.Zones) or instance:IsDescendantOf(workspace.ComessticBullets) then
			return true
		end

		if lastPartPierced == instance then
			return false
		end
		
		if CollectionService:HasTag(instance, 'Leaf') or CollectionService:HasTag(instance, 'Bush') or instance.Transparency == 1  or instance:IsA("Accessory") then
			return true
		end

		if currentHits >= maxHits then
			return false
		end
	
		if pierceableMaterials[material] then -- Material found

			return true

		elseif not pierceableMaterials[material] then  -- Material not found

			return false

		end
		return false
	else
		return true
	end
end

function checkAndDoDamage(bulletType: string, hitPart: Instance, cast, raycastResult: RaycastResult, segmentVelocity: Vector3,HitPos)

	local bulletType = cast.UserData.BulletType
	local subCategory = cast.UserData.SubCategory

	local maxVelocity = AmmoTypes[bulletType][subCategory].Velocity
	--local distanceTravelled = cast.UserData.LastRecordedDistance
	--warn(distanceTravelled)

	local amountOfDamage = 30

	local damageMultiplier = cast.UserData.DamageMultiplier
	if hitPart ~= nil and hitPart.Parent ~= nil then -- Test if we hit something
		local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid") -- Is there a humanoid?

		if humanoid then

			local player = Players:GetPlayerFromCharacter(hitPart.Parent)		
			local categoryOfPart = bodyPartToCategory[hitPart.Name]
			local bodyPartMultiplier = AmmoTypes[bulletType][subCategory].DamageMultipler[bodyPartToCategory[hitPart.Name]]

			local damageToDo = amountOfDamage * (segmentVelocity.Magnitude/maxVelocity) * (damageMultiplier * 1.5) * bodyPartMultiplier

			if player then
				CombatService:TakeDamage(player, humanoid, bulletType, damageToDo)
			else
				humanoid:TakeDamage(damageToDo) -- Damage.
			end
			
			local SoundFolder = game.ServerStorage.ServerLibrary.Assets.Hit:GetChildren()
			local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()	
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			EffectSound.Parent = attnew
			EffectSound:Play()
			wait(10)
			attnew:Destroy()
			return
		end
		if hitPart.CanCollide == true or hitPart.Material == Enum.Material.Water or raycastResult.Material == Enum.Material.Water  then
			if hitPart.Name == "Window" and hitPart.CanCollide == true or hitPart.Transparency == .5 and hitPart.CanCollide == true then
				local transparency = hitPart.Transparency
				hitPart.Transparency = 1
				hitPart.CanCollide = false
				local Shatter = game.ServerStorage.ServerLibrary.Assets.ShatterSound:Clone()
			local Effect = game.ServerStorage.ServerLibrary.Assets.GlassBreakingEffect:Clone()
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
				attnew.CFrame = CFrame.new(HitPos)
				Shatter.Parent = attnew
				Effect.Parent = hitPart
				Shatter:Play()
				Effect:Emit(20)
				wait(120)
				hitPart.CanCollide = true
				hitPart.Transparency = transparency
				Effect:Destroy()
				attnew:Destroy()
		elseif hitPart.Name == "Leaf" or hitPart.Name == "Bush" then
			local num = math.random(1,3)
			local LeafSound = game.ServerStorage.ServerLibrary.Assets.LeafSound:Clone()
			if num == 1 then 
				LeafSound.PlaybackSpeed = 1
			elseif num == 2 then 
				LeafSound.PlaybackSpeed = 1.5
			elseif num == 3 then 
				LeafSound.PlaybackSpeed = 2
			end
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			LeafSound.Parent = attnew
			LeafSound:Play()
			wait(10)
			attnew:Destroy()
		elseif hitPart.Material == Enum.Material.Concrete or hitPart.Material == Enum.Material.Granite or hitPart.Material == Enum.Material.Cobblestone or hitPart.Material == Enum.Material.Brick or raycastResult.Material == Enum.Material.Concrete then
			local SoundFolder = game.ServerStorage.ServerLibrary.Assets.Concrete:GetChildren()
			local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()	
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			EffectSound.Parent = attnew
			EffectSound:Play()
			wait(10)
			attnew:Destroy()
		elseif hitPart.Material == Enum.Material.Grass or hitPart.Material == Enum.Material.LeafyGrass or hitPart.Material == Enum.Material.Marble or raycastResult.Material == Enum.Material.Grass or raycastResult.Material == Enum.Material.LeafyGrass or raycastResult.Material == Enum.Material.Ground or raycastResult.Material == Enum.Material.Mud then
			local SoundFolder = game.ServerStorage.ServerLibrary.Assets.Grass:GetChildren()
			local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()	
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			EffectSound.Parent = attnew
			EffectSound:Play()
			wait(10)
			attnew:Destroy()
		elseif hitPart.Material == Enum.Material.Metal or hitPart.Material == Enum.Material.DiamondPlate or hitPart.Material == Enum.Material.CorrodedMetal or raycastResult.Material == Enum.Material.Metal then
			local SoundFolder = game.ServerStorage.ServerLibrary.Assets.Metal:GetChildren()
			local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()	
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			EffectSound.Parent = attnew
			EffectSound:Play()
			wait(10)
			attnew:Destroy()
		elseif hitPart.Material == Enum.Material.Wood or hitPart.Material == Enum.Material.Slate or hitPart.Material == Enum.Material.WoodPlanks or raycastResult.Material == Enum.Material.Wood then
			local SoundFolder = game.ServerStorage.ServerLibrary.Assets.Wood:GetChildren()
			local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()	
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			EffectSound.Parent = attnew
			EffectSound:Play()
			wait(10)
			attnew:Destroy()
		elseif hitPart.Material == Enum.Material.Water or raycastResult.Material == Enum.Material.Water then
			local SoundFolder = game.ServerStorage.ServerLibrary.Assets.Water:GetChildren()
			local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()	
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			EffectSound.Parent = attnew
			EffectSound:Play()
			wait(10)
			attnew:Destroy()
		else
			local SoundFolder = game.ServerStorage.ServerLibrary.Assets.Other:GetChildren()
			local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()	
			local attnew = Instance.new("Attachment",game.Workspace.Terrain)
			attnew.CFrame = CFrame.new(HitPos)
			EffectSound.Parent = attnew
			EffectSound:Play()
			wait(10)
			attnew:Destroy()
			end
		end
	end
end

function onBulletPierced(cast, rayResult: RaycastResult, segmentVelocity: Vector3, cosmeticBulletObject)

	local bulletType = cast.UserData.BulletType
	local subCategory = cast.UserData.SubCategory

	local damageMultipler: number = cast.UserData.DamageMultiplier
	--local velocity: Vector3 = cast:GetVelocity()
	local acceleration: Vector3 = cast:GetAcceleration()

	local instance = rayResult.Instance
	local position = rayResult.Position
	local material = rayResult.Material
	local maxDistance = AmmoTypes[bulletType][subCategory].MaxDistance

	local amountToAdd = 0;

	local pierceableMaterials = AmmoTypes[bulletType][subCategory].PierceableMaterials
	local maxHits = AmmoTypes[bulletType][subCategory].MaxPierceAmount
	
	local materialDamageModifier = nil;
	
	if pierceableMaterials[material] ~= nil then
		materialDamageModifier = pierceableMaterials[material].DamageMultipler
	else
		materialDamageModifier = 1
	end
	if cast.UserData.DamageMultiplier == nil then
		cast.UserData.DamageMultiplier = 1
	end
	
	cast.UserData.DamageMultiplier *= materialDamageModifier
	if material == Enum.Material.Glass or instance.Name == "Window" or instance.Transparency == .5 or instance.CanCollide == false or instance.Transparency == 1 then
		amountToAdd = 0
	else
		amountToAdd = 1
	end
	cast.UserData.Hits += amountToAdd
	
	local velocityMod = 1;
	
	if pierceableMaterials[material] then
		velocityMod = pierceableMaterials[material].VelocityModifier
	end
 	
	cast:SetVelocity(segmentVelocity * velocityMod)
	cast:SetAcceleration(Vector3.new(acceleration.X, acceleration.Y/velocityMod, acceleration.Z))

	checkAndDoDamage(cast.UserData.BulletType, instance, cast, rayResult, segmentVelocity,position)

end

function onBulletHit(cast, raycastResult: RaycastResult, segmentVelocity, cosmeticBulletObject)
	-- This function will be connected to the Caster's "RayHit" event.

	local bulletType = cast.UserData.BulletType
	local subCategory = cast.UserData.SubCategory

	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal
	local maxDistance = AmmoTypes[bulletType][subCategory].MaxDistance

	local damageMultipler = cast.UserData.DamageMultiplier

	if damageMultipler == nil then
		damageMultipler = 1
	end
	checkAndDoDamage(cast.UserData.BulletType, hitPart, cast, raycastResult, segmentVelocity,hitPoint)

end

function onLengthChanged(cast, lastPoint: Vector3, direction: Vector3, displacement: number, segmentVelocity: Vector3, cosmeticBulletObject: Instance)
	if cosmeticBulletObject ~= nil then
		local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
		local baseCFrame = CFrame.new(lastPoint, lastPoint + direction)
		cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(displacement - bulletLength))
	end
end

function onBulletTerminated(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet ~= nil then
		cosmeticBullet:Destroy()
	end
end

function fireBullet(tool: Tool, caster, firePoint: Attachment, direction, castBehavior, userData)
	if tool.Parent:IsA('Backpack') then return end
	if not tool.Parent:FindFirstChild("Head") then return end

	local directionalCF = CFrame.new(Vector3.new(), direction)
	local direction = directionalCF.LookVector

	local humanoidRootPart = tool.Parent:WaitForChild("HumanoidRootPart", 1)
	local myMovementSpeed = humanoidRootPart.Velocity

	castBehavior.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist	
	castBehavior.RaycastParams.FilterDescendantsInstances = {tool.Parent, workspace.Zones:GetDescendants(), }

	local bulletType = userData.BulletType
	local subCategory = userData.SubCategory


	local ammoType = AmmoTypes[bulletType][subCategory]

	local modifiedBulletSpeed = direction * ammoType.Velocity + myMovementSpeed

	local activeCast = caster:Fire(tool.Parent:FindFirstChild("Head").Position, directionalCF, modifiedBulletSpeed, castBehavior)
	
	activeCast.UserData = userData
	activeCast.UserData.LastPartPierced = nil
	
	local fireSound = firePoint.Parent.SoundOrigin:FindFirstChild('Fire')
	local originalVolume = fireSound.Volume
	fireSound.Volume *= ammoType.VolumeModifier
	
	fireSound:Play()
	
	fireSound.Volume = originalVolume
	
	return activeCast
end

local function EjectShell(tool,Char)
	if ItemsDatabase.Firearms[tostring(tool)].Caliber then
		local CanSound = true
		local NewShell = game.ServerStorage.ServerLibrary.Assets.Casings:FindFirstChild(tostring(ItemsDatabase.Firearms[tostring(tool)].Caliber)):Clone()
		NewShell.CFrame = tool.ShellEjection.CFrame
		NewShell.Velocity = tool.ShellEjection.CFrame.RightVector*Vector3.new(10,50,10)
		NewShell.Parent = game.Workspace.Zones.ShellCasings
		local SoundFolder = game.ServerStorage.ServerLibrary.Assets.ShellSounds:GetChildren()
		local EffectSound = SoundFolder[math.random(1,#SoundFolder)]:Clone()

		NewShell.Touched:Connect(function(hit)
			if hit:IsDescendantOf(Char) then
			elseif CanSound == true then
				CanSound = false
				EffectSound.Parent = NewShell
				EffectSound:Play()
			end	
		end)	
	end
end

function module:ClientFiredGun(player: Player, tool: Tool, unitRay)
	local loadedMagazine = tool.LoadedMagazine:FindFirstChildOfClass('Tool')
	local magazineBulletType = loadedMagazine.BulletType.Value
	local magazineBulletSubCategory = loadedMagazine.SubCategory.Value

	local maxDistance = AmmoTypes[magazineBulletType][magazineBulletSubCategory].MaxDistance

	local ammoInMag = loadedMagazine.Ammunition.Value
	
	local firePoint = tool:FindFirstChild('FirePoint', true)
	if ammoInMag == 0 or tool.ChamberEmpty.Value == true or tool.SlideBack.Value == true then
		firePoint.Parent.SoundOrigin.Empty:Play()
	end
	if ammoInMag >=1 and tool.ChamberEmpty.Value == false  and tool.SlideBack.Value == false then
		local jam = false
		local jampercent = math.random(1,50)
		if jampercent == 50 then
			jam = true
		end
		if jam == true then
			firePoint.Parent.SoundOrigin.Jam:Play()
			tool.SlideBack.Value = true
		else	
			
		local function getMousePos()
			local origin, direction = unitRay.Origin, unitRay.Direction * maxDistance

			local result = workspace:Raycast(origin, direction, RegisteredBehaviors[magazineBulletType .. ', '.. magazineBulletSubCategory].RaycastParams)

			return result and result.Position or origin + direction
		end
			
			local pos = getMousePos()
		local direction = (pos - player.Character.Head.Position).Unit

		fireBullet(
			tool,
			RegisteredCasters[magazineBulletType .. ', '.. magazineBulletSubCategory],
			firePoint,
			direction,
			RegisteredBehaviors[magazineBulletType .. ', '.. magazineBulletSubCategory],
			{ BulletType = magazineBulletType, SubCategory = magazineBulletSubCategory , DamageMultiplier = 1 }
		)
		
		loadedMagazine.Ammunition.Value -= 1
		if loadedMagazine.Ammunition.Value == 0 then
			firePoint.Parent.SoundOrigin.BoltBack:Play()
			tool.SlideBack.Value = true
		end
			EjectShell(tool,player.Character)
		firePoint.Flash:Emit(1)
		firePoint.GunSmoke.Enabled = true
		firePoint.PointLight.Enabled = true
		wait(.05)
		firePoint.PointLight.Enabled = false
		wait(5)
			firePoint.GunSmoke.Enabled = false
		end
	end
	
end

function module:ClientReloadedGun(player: Player, tool: Tool)
	local loadedMagazine = tool.LoadedMagazine:FindFirstChildOfClass('Tool')
	local magazineBulletType = loadedMagazine.BulletType.Value
	local magazineBulletSubCategory = loadedMagazine.SubCategory.Value

	local maxDistance = AmmoTypes[magazineBulletType][magazineBulletSubCategory].MaxDistance

	local ammoInMag = loadedMagazine.Ammunition.Value

	local firePoint = tool:FindFirstChild('FirePoint', true)
	local hasmag = nil
	
	if ammoInMag == 0 then
		tool.ChamberEmpty.Value = true
	end
		for i,v in pairs(player.Backpack:GetChildren()) do
			if v:IsA("Tool") then
				if v:FindFirstChild("Ammunition") then
					if v:FindFirstChild("Ammunition").Value >=1 then
						hasmag = v
					end
				end
			end
		end
		wait()
		if hasmag then
			firePoint.Parent.SoundOrigin.MagOut:Play()
		wait(1.03)
			firePoint.Parent.SoundOrigin.MagIn:Play()
			loadedMagazine:Destroy()
			hasmag.Parent = tool.LoadedMagazine
		
	
		end	
end


function module:ClientSlidedBack(player: Player, tool: Tool)
	local loadedMagazine = tool.LoadedMagazine:FindFirstChildOfClass('Tool')
	local magazineBulletType = loadedMagazine.BulletType.Value
	local magazineBulletSubCategory = loadedMagazine.SubCategory.Value

	local maxDistance = AmmoTypes[magazineBulletType][magazineBulletSubCategory].MaxDistance

	local ammoInMag = loadedMagazine.Ammunition.Value

	local firePoint = tool:FindFirstChild('FirePoint', true)
	local hasmag = nil
	tool.SlideBack.Value = true
	if ammoInMag >=1 then
		loadedMagazine.Ammunition.Value -= 1
		EjectShell(tool,player.Character)
	end
	firePoint.Parent.SoundOrigin.BoltBack:Play()
end

function module:ClientSlidedForward(player: Player, tool: Tool)
	local loadedMagazine = tool.LoadedMagazine:FindFirstChildOfClass('Tool')
	local magazineBulletType = loadedMagazine.BulletType.Value
	local magazineBulletSubCategory = loadedMagazine.SubCategory.Value

	local maxDistance = AmmoTypes[magazineBulletType][magazineBulletSubCategory].MaxDistance

	local ammoInMag = loadedMagazine.Ammunition.Value

	local firePoint = tool:FindFirstChild('FirePoint', true)
	local hasmag = nil
	tool.SlideBack.Value = false
	if ammoInMag >=1 then
		tool.ChamberEmpty.Value = false
	end
	firePoint.Parent.SoundOrigin.BoltForward:Play()
end

function module:ClientCheckedChamber(player: Player, tool: Tool)
	local loadedMagazine = tool.LoadedMagazine:FindFirstChildOfClass('Tool')
	local magazineBulletType = loadedMagazine.BulletType.Value
	local magazineBulletSubCategory = loadedMagazine.SubCategory.Value

	local maxDistance = AmmoTypes[magazineBulletType][magazineBulletSubCategory].MaxDistance

	local ammoInMag = loadedMagazine.Ammunition.Value

	if ammoInMag >=1 then
		tool.ChamberEmpty.Value = false
	else
		tool.ChamberEmpty.Value = true
	end
end

function module:ClientToggleLight(player: Player, tool: Tool)
	local loadedMagazine = tool.LoadedMagazine:FindFirstChildOfClass('Tool')
	local magazineBulletType = loadedMagazine.BulletType.Value
	local magazineBulletSubCategory = loadedMagazine.SubCategory.Value

	local maxDistance = AmmoTypes[magazineBulletType][magazineBulletSubCategory].MaxDistance
	local firePoint = tool:FindFirstChild('FirePoint', true)
	local ammoInMag = loadedMagazine.Ammunition.Value

	if tool.HasLight.Value == true then
		firePoint.Parent.SoundOrigin.Switch:Play()
		if tool.Light.SpotLight.Enabled == false then
			tool.Light.SpotLight.Enabled = true
			tool.Light.Material = "Neon"
		else
			tool.Light.SpotLight.Enabled = false
			tool.Light.Material = "Metal"
		end
	end
end

for name, ammoCategory in AmmoTypes do
	for subcatName, subCategory in ammoCategory do
		constructCaster(name, subcatName)
		constructBehavior(name, subcatName)
	end
end

return module
