-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("routes", Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local RewardItems = {}
local ActiveRoutes = {}
local RouteCost = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- REWARD
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Deliver()
    local Passport = vRP.Passport(source)	
    if Passport and ActiveRoutes[Passport] then	
        local Active = ActiveRoutes[Passport]
        local Route = Config[Active['Route']]
		local Items = Route['List']		
		RewardItems[Passport] = {}		
		for _, Index in pairs(Active['Items']) do
			table.insert(RewardItems[Passport],Items[Index])
		end	
        if Route then
			local RewardAmountItem = 1
			for _ = 1, RewardAmountItem do
				local Reward = RandPercentage(RewardItems[Passport])
				local Item = Reward['Item']
				local Amount = Reward["Valuation"]
				vRP.GenerateItem(Passport, Item, Amount, true)
			end			
			if Route['Experience'] then
				local MaxExperience = 100
				local Experience = vRP.GetExperience(Passport, Route['Experience']['Name'])
				local Amount = ((Experience + Route['Experience']['Amount']) <= MaxExperience) and Route['Experience']['Amount'] or (MaxExperience - Experience)
				vRP.PutExperience(Passport, Route['Experience']['Name'], Amount)
			end
			return true
        end
    end
    return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permission(Name)
    local Passport = vRP.Passport(source)
    if Passport then
        local Route = Config[Name]
        if Route and (not Route["Permission"] or vRP.HasPermission(Passport, Route["Permission"])) then
            return true
        end
    end
    return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- START
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Start(Items, Name)
    local Passport = vRP.Passport(source)	
	if Passport then
		RouteCost[Passport] = 0		
		for _, Index in pairs(Items) do
			local Price = Config[Name]?['List']?[Index]?['Price'] or 0
			RouteCost[Passport] += Price
		end
		if vRP.PaymentFull(Passport,RouteCost[Passport]) or (RouteCost[Passport] == 0) then
			ActiveRoutes[Passport] = { Route = Name, Items = Items }
			return true
		end
	end
    return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISH
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Finish()
    local Passport = vRP.Passport(source)
    if Passport and ActiveRoutes[Passport] then	
		ActiveRoutes[Passport],
		RewardItems[Passport],
		RouteCost[Passport] = nil,nil,nil		
        return true
    end
    return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
    if ActiveRoutes[Passport] then
        ActiveRoutes[Passport],
        RewardItems[Passport],
        RouteCost[Passport] = nil,nil,nil
    end
end)