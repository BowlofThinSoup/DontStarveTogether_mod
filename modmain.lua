_G = GLOBAL

local position_master=_G.Vector3(0,0,0)
local position_cave=_G.Vector3(0,0,0)
local modname = "DropEveryThing"
local keyboard = 104
local dir=""

_G.DropEverything =
{
SDays = GetModConfigData("SDays")
}
--从modinfo获取天数


-- load the file and return the position(Vector3)
    local function LoadFile(name)
        loadfile = _G.io.open(dir .. name, "r")
        if loadfile then
            position = _G.Vector3(loadfile:read('*l'), loadfile:read('*l'), loadfile:read('*l'))
            loadfile:close()
        else 
            position = _G.Vector3(0,0,0)
        end
        return position
    end

--save the position to the file
    local function SaveFile(name,pos)
        savefile = _G.io.open(dir .. name, "w")
        savefile:write(pos.x)
        savefile:write('\n')
        savefile:write(pos.y)
        savefile:write('\n')
        savefile:write(pos.z)
        savefile:close()
    end

-- drop item from container
    local function DropItemInContainer(item, pos)
        if item then
            item.Transform:SetPosition(pos:Get())
            if item.components.inventoryitem then
                item.components.inventoryitem:OnRemoved()
                item.components.inventoryitem:DoDropPhysics(pos.x, pos.y, pos.z, true, nil)
            end
            if item.ondropfn ~= nil then
                item.ondropfn(item.inst)
            end
            item:PushEvent("ondropped")
            if item.components.propagator ~= nil then
                item.components.propagator:Delay(5)
            end

        end
    end



-- drop items from backpack or other container.
    local function DropContainer(container, pos, inventory)
        print("DropContainer")
        for _, v in pairs(container.slots) do
            inventory:DropItem(v, true, true, pos)
        end
    end


-- drop things when palyer leave and then transfer to the set position
    local function DropEverythingTransfer(player, ondeath, keepequip, pos)
        self=player.components.inventory
        if self.activeitem ~= nil then
            self:DropItem(self.activeitem, true, true, pos)
            self:SetActiveItem(nil)
        end

        for k = 1, self.maxslots do
        	local v = self.itemslots[k]
        	if v ~= nil then
            	    self:DropItem(v, true, true, pos)
        	end
        end

        if not keepequip then
            for k, v in pairs(self.equipslots) do
                if not (ondeath and v.components.inventoryitem.keepondeath) then
                    if v:HasTag("backpack") then
                        DropContainer(v.components.container, pos, self)
                    end
                    self:DropItem(v, true, true, pos)
            	end
            end
        end

        if player.woby then
              DropContainer(player.woby.components.container, pos, self)
        end
    end

--Announce globally function when the player leaves    
    local function GlobalAnnounce(player_name)
        GLOBAL.TheNet:Announce(player_name.."离开游戏，生存不足".._G.DropEverything.SDays.."天，物品已经自动掉落，请到设置地点拾取")
    end

--Player say when login
    local function PlayerSay(player)
        player.components.talker:Say(player:GetDisplayName() .. ", " .. "清汤提醒您：生存不足".._G.DropEverything.SDays.."天，身上物品将自动掉落，请不要浪费资源呦",10)
    end


-- is the player a new guy?
    local function IsNewPlayer(player)
        return player and player.components.inventory and player.components.age:GetDisplayAgeInDays()<_G.DropEverything.SDays 
    end

-- "ms_playerdespawn" Event function
    local function PlayerdespawnEventProcess(inst, player)
        local position = _G.Vector3(0,0,0)
        if IsNewPlayer(player) then
            if _G.TheWorld:HasTag("cave") then 
                position = position_cave
            else
                position = position_master
            end
            DropEverythingTransfer(player, false, false, position) 
            GlobalAnnounce(player.name)
        end	
    end

-- "ms_playerspawn" Event function
    local function PlayerspawnEventProcess(inst, player)
        if IsNewPlayer(player)  then 
            player:DoTaskInTime(3, 
                function(target)
                    if target.components and target.components.talker then
	        PlayerSay(target)
                    end
                end
            )
        end
    end

--listening function for PlayerSpawner
   --[[ local function ListeningForPlayerSpawner(inst)
        AddComponentPostInit("playerspawner", 
            function(PlayerSpawner, inst)
                inst:ListenForEvent("ms_playerdespawn", PlayerdespawnEventProcess) 
                inst:ListenForEvent("ms_playerspawn", PlayerspawnEventProcess) 
            end
        ）      
    end
]]--


-----------------------Server init load . Code starts.
    position_master = LoadFile("master.txt")
    position_cave = LoadFile("cave.txt")
    AddComponentPostInit("playerspawner",   
        function(PlayerSpawner, inst)
            inst:ListenForEvent("ms_playerdespawn", PlayerdespawnEventProcess) 
            inst:ListenForEvent("ms_playerspawn", PlayerspawnEventProcess) 
        end
    )

--get player's position and save in right file.
    local function GetPlayerPositionDedicate(player)
        print("recieve RPC")
        if not player.Network:IsServerAdmin() then 
            print("you are not an admin")
            return
        end
        print("New position is:")
        position = _G.Vector3(player.Transform:GetWorldPosition())
        print(position)

        if _G.TheWorld:HasTag("cave") then 
            SaveFile("cave.txt",position)
            position_cave = position
        else
            SaveFile("master.txt",position)
            position_master = position
        end
            print("position complete")
    end
	
-- Add RPC
    AddModRPCHandler(modname, "GetPlayerPositionRPC", GetPlayerPositionDedicate)

--Send RPC
    local function SendGrowGiantRPC()
        if _G.TheNet:GetIsServerAdmin() then 
            SendModRPCToServer(MOD_RPC[modname]["GetPlayerPositionRPC"])
            print("sendok")
        end
    end

-- press 'H' to start the function
    _G.TheInput:AddKeyUpHandler(keyboard, SendGrowGiantRPC)











-----------------------------------------------------不足天数使用物品警告---------------------------------------------
--[[
if GetModConfigData("lang") == "zh" then
    common_string_warn = "清汤提醒您:"
    common_string_hammer = "正在砸"
    common_string_light = "正在烧"
    common_string_castspell = "正在使用"
else   
    common_string_warn = "Warning: "
    common_string_hammer = " is Hammering "
    common_string_light = "is lighting "
    common_string_castspell = "is castspelling"
end
common_string_timemark = "["..GLOBAL.os.date("%Y-%m-%d|%H:%M:%S").."] "

--警告熊大/巨鹿拆家
local function GetDebugString(inst,target)
    return common_string_timemark..GLOBAL.STRINGS.NAMES[string.upper(inst.prefab)].." | 在砸"..GLOBAL.STRINGS.NAMES[string.upper(target.prefab)]
end

local function GetAnnounceString(inst,target)
    return common_string_warn..GLOBAL.STRINGS.NAMES[string.upper(inst.prefab)].." 正在拆"..GLOBAL.STRINGS.NAMES[string.upper(target.prefab)]
end

local listener = {"deerclops","bearger"}
for k, v in pairs(listener) do
    AddPrefabPostInit(v, function(inst)
        inst:ListenForEvent("working", function(inst, data)
            if data and data.target and data.target:HasTag("structure") then
                print(GetDebugString(inst, data.target))
                GLOBAL.TheNet:Announce(GetAnnounceString(inst,data.target))
            end
        end)
    end)
end


--警告锤子敲击
local _ACTION_HAMMER = GLOBAL.ACTIONS.HAMMER.fn
GLOBAL.ACTIONS.HAMMER.fn = function(act)
    if act.doer and act.target and act.target.components.workable.workleft == 2 and act.doer.components.age:GetDisplayAgeInDays()<_G.DropEverything.SDays then
        local item = act.target
        if item:HasTag("structure") then--检测物品是否有建筑标签
        --if item and item.prefab == "firesuppressor" then--检测是否在砸雪球机
            if GetModConfigData("notice_method") == 1 then
                GLOBAL.TheNet:Announce(common_string_warn..act.doer.name..common_string_hammer..act.target.name)
            elseif GetModConfigData("notice_method") == 2 then
                GLOBAL.TheNet:SystemMessage(common_string_warn..act.doer.name..common_string_hammer..act.target.name)
            end
            if act.doer.userid then
            print(common_string_timemark..act.doer.name.."("..act.doer.userid..")"..common_string_hammer..act.target.name)
            end
        end
    end
    return _ACTION_HAMMER(act)
end


--警告点燃活动
local _ACTION_LIGHT = GLOBAL.ACTIONS.LIGHT.fn
GLOBAL.ACTIONS.LIGHT.fn = function(act)
    if act.doer and act.target and act.doer.components.age:GetDisplayAgeInDays()<_G.DropEverything.SDays then
        local item = act.target
        --local ProtectList = {"treasurechest","cookpot","researchlab","researchlab2","researchlab4","mushroom_light","tent"}--设置保护名单，一旦点燃列表中物品将警告
        --for k,v in pairs(ProtectList) do 
        if item:HasTag("structure") then
            if GetModConfigData("notice_method") == 1 then
                GLOBAL.TheNet:Announce(common_string_warn..act.doer.name..common_string_light..act.target.name)
            elseif GetModConfigData("notice_method") == 2 then
                GLOBAL.TheNet:SystemMessage(common_string_warn..act.doer.name..common_string_light..act.target.name)
            end
            if act.doer.userid then
                print(common_string_timemark..act.doer.name.."("..act.doer.userid..")"..common_string_light..act.target.name)
            end
         end
        --end
    end
    return _ACTION_LIGHT(act)
end


--警告使用唤星/唤月/传送/分解
local _ACTION_CASTSPELL = GLOBAL.ACTIONS.CASTSPELL.fn
GLOBAL.ACTIONS.CASTSPELL.fn = function(act)
    if act.doer and act.doer.components.age:GetDisplayAgeInDays()<_G.DropEverything.SDays then
        local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if GetModConfigData("notice_method") == 1 then
            GLOBAL.TheNet:Announce(common_string_warn..act.doer.name..common_string_castspell..tostring(GLOBAL.STRINGS.NAMES[string.upper(staff.prefab)]))
        elseif GetModConfigData("notice_method") == 2 then
            GLOBAL.TheNet:SystemMessage(common_string_warn..act.doer.name..common_string_castspell..tostring(GLOBAL.STRINGS.NAMES[string.upper(staff.prefab)]))
        end
        if act.doer.userid then
            print(common_string_timemark..act.doer.name.."("..act.doer.userid..")"..common_string_castspell..tostring(GLOBAL.STRINGS.NAMES[string.upper(staff.prefab)]))
        end
    end
    return _ACTION_CASTSPELL(act)
end
]]--
