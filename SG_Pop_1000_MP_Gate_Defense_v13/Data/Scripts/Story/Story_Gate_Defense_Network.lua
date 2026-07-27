-- Universal Gate Defense Network, v13
-- Monitors strategic structures and dynamically hides/restores raid slots.

require("PGStoryMode")
require("SGMGXmlEvents")

local GATE_DEFENSE_TYPE = "Universal_Gate_Defense_Network"
local protected_planets = {}

-- These planets are permanently blocked by the original campaign story.
-- Never reveal their raid slots if a temporary defense is removed.
local permanently_hidden = {
   UNIVERSE_L_ASURAS = true,
   UNIVERSE_L_EARTH = true,
   UNIVERSE_L_ORAKIS = true,
   UNIVERSE_L_OTHALA = true,
   UNIVERSE_L_WRAITH_HOMEWORLD = true,
}

function Definitions()
   StoryModeEvents = {
      Gate_Defense_Initialize = State_Gate_Defense_Initialize
   }
end

function State_Gate_Defense_Initialize(message)
   if message == OnEnter then
      XmlRewards.Initialize("Story_XmlRewards_Default.xml")
      Create_Thread("Thread_Monitor_Gate_Defenses")
   end
end

local function Get_Planet_Key(planet)
   if not TestValid(planet) then
      return nil
   end

   local planet_type = planet.Get_Type()
   if not planet_type then
      return nil
   end

   return string.upper(planet_type.Get_Name())
end

local function Hide_Gate_Slot(planet)
   XmlRewards.Trigger_Reward {
      Type = "HIDE_RAID_SLOT",
      Param1 = planet
   }
end

local function Show_Gate_Slot(planet)
   XmlRewards.Trigger_Reward {
      Type = "SHOW_RAID_SLOT",
      Param1 = planet
   }
end

function Thread_Monitor_Gate_Defenses()
   while true do
      local currently_protected = {}
      local defenses = Find_All_Objects_Of_Type(GATE_DEFENSE_TYPE)

      if defenses then
         for _, defense in pairs(defenses) do
            if TestValid(defense) then
               local planet = defense.Get_Planet_Location()
               local key = Get_Planet_Key(planet)

               if key then
                  currently_protected[key] = planet

                  if not protected_planets[key] then
                     Hide_Gate_Slot(planet)
                     protected_planets[key] = planet
                  end
               end
            end
         end
      end

      for key, planet in pairs(protected_planets) do
         if not currently_protected[key] then
            if not permanently_hidden[key] and TestValid(planet) then
               Show_Gate_Slot(planet)
            end
            protected_planets[key] = nil
         end
      end

      Sleep(2.0)
   end
end
