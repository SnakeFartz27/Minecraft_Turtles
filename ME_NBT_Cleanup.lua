--[[
  Turtle ME Cleanup Script
  Description: Automatically removes blacklisted (NBT-heavy) items from an
               Applied Energistics ME System via an ME Bridge peripheral.
  Usage: Place this script on a Turtle connected to (or next to) the ME Bridge.
         Ensure there's a chest/trash block below the Turtle for disposing items.
--]]

-------------------------------------
-- 1) Configuration
-------------------------------------

-- Side or name of the ME Bridge peripheral.
-- Adjust if it's on a different side (e.g., "left", "right", "back", etc.).
local ME_BRIDGE_SIDE = "front"

-- How many items to export at once. 64 is typically safe for a single slot.
local EXPORT_BATCH_SIZE = 64

-- Interval in seconds between cleanup runs.
local SCAN_INTERVAL = 30

-- Blacklist: Items you want to remove from the ME system.
-- Add or remove item IDs as needed. The exact ID format depends on your modpack.
local blacklist = {
  "minecraft:enchanted_book",   -- Example; you might need exact item names/IDs.
  "forge:tools",
  "forge:swords",
}

-------------------------------------
-- 2) Utility Functions
-------------------------------------

-- Wrap the ME Bridge peripheral.
local meBridge = peripheral.wrap(ME_BRIDGE_SIDE)
if not meBridge then
  error("Could not find ME Bridge on side: " .. ME_BRIDGE_SIDE)
end

-- Function to check if an item name is blacklisted.
local function isBlacklisted(itemName)
  for _, blacklistedName in ipairs(blacklist) do
    if itemName == blacklistedName then
      return true
    end
  end
  return false
end

-------------------------------------
-- 3) Core Cleanup Logic
-------------------------------------

-- Main function to scan ME system and remove blacklisted items.
local function cleanupME()
  print("Starting ME cleanup...")

  -- 3.1) Get list of all items in the ME system.
  --     Adjust function call if your mod uses a different naming convention.
  local items = meBridge.listItems()  -- e.g., returns { {name="", amount=...}, ... }

  -- 3.2) Loop through each item and see if it's blacklisted.
  for _, item in ipairs(items) do

      -- 3.2aa) Actually checks if item is blacklisted.
      if isBlacklisted(item.name) then
      -- 3.2a) Calculate how many total we have to remove.
        local toRemove = item.amount

        print("Removing " .. toRemove .. " of " .. item.name .. "...")

      -- 3.2b) While there are still items to remove, export in batches.
        while toRemove > 0 do
        
        -- Select a turtle slot (1–16). We’ll assume slot 1 for simplicity,
        -- but you could cycle through multiple slots if needed.
          turtle.select(1)

        -- Determine how many items to export this pass (up to 64).
          local exportAmount = math.min(EXPORT_BATCH_SIZE, toRemove)

        -- Export items into the Turtle from the ME system.
        -- Adjust function if your mod has a different call pattern (e.g. exportItemToPeripheral).
          local exported = meBridge.exportItem(
            { name = item.name },  -- The item filter table (name, NBT, etc.)
            "west",              -- Destination: the Turtle’s inventory
            exportAmount           -- How many to export this time
          )

          if exported and exported > 0 then
          -- Drop the items below the Turtle (into a chest or trash).
            turtle.dropDown()
          -- Decrease remaining count.
            toRemove = toRemove - exported
          else
          -- If nothing was exported, break to avoid possible infinite loops.
            print("Failed to export: " .. item.name)
            break
          end
        end
      end
    end

---------------------------------------------------------------------------
  --  NOW cycle through all turtle slots and drop anything still inside.
  ---------------------------------------------------------------------------
  print("Dropping leftover items from the Turtle's inventory...")
  for slot = 1, 16 do
    turtle.select(slot)
    local itemCount = turtle.getItemCount(slot)
    if itemCount > 0 then
      turtle.dropDown()  -- deposit to the chest below
    end
  end
  
print("ME cleanup complete!")
print("Sleepy Time!")
end

-------------------------------------
-- 4) Main Loop
-------------------------------------

-- Run cleanup in a perpetual loop with a pause.
while true do
  -- Perform a cleanup pass.
  cleanupME()

  -- Wait for the specified interval before running again.
  sleep(SCAN_INTERVAL)
end
