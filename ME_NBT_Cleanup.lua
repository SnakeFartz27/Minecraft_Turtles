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

-- Blacklist: Items you want to remove from the ME system by exact item name.
-- For example, "minecraft:enchanted_book"
local blacklist = {
  "minecraft:enchanted_book",
}

-- Tag keywords you want to remove (Method 3):
-- e.g., if an item has "forge:shovels" or "forge:tools" in its tags, remove it.
local TAG_KEYWORDS = {
  "forge:shovels",
  "forge:tools",
  -- add more strings if needed
}

-------------------------------------
-- 2) Utility Functions
-------------------------------------

-- Wrap the ME Bridge peripheral.
local meBridge = peripheral.wrap(ME_BRIDGE_SIDE)
if not meBridge then
  error("Could not find ME Bridge on side: " .. ME_BRIDGE_SIDE)
end

-- Check if the item name is explicitly in the 'blacklist' table.
local function isNameBlacklisted(itemName)
  for _, blacklistedName in ipairs(blacklist) do
    if itemName == blacklistedName then
      return true
    end
  end
  return false
end

-- Check if an item has any of the tags we care about (Method 3).
local function hasTagKeyword(item, keywords)
  -- If the item doesn't have a 'tags' table or it's empty, skip
  if not item.tags then return false end

  -- The mod might store tags like: tags = { "minecraft:item/forge:shovels", ... }
  -- We can search each string for our keyword(s).
  for _, tagString in pairs(item.tags) do
    for _, keyword in ipairs(keywords) do
      if string.find(tagString, keyword) then
        return true
      end
    end
  end

  return false
end

-- Our master function to decide whether an item should be removed.
local function isBlacklisted(item)
  -- 1) If it's in the name-based blacklist, remove it
  if isNameBlacklisted(item.name) then
    return true
  end

  -- 2) If it has any matching tag keywords, remove it
  if hasTagKeyword(item, TAG_KEYWORDS) then
    return true
  end

  -- Otherwise, not blacklisted
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
  local items = meBridge.listItems()  -- e.g., returns { {name="", amount=..., tags={...}}, ... }

  -- 3.2) Loop through each item and see if it's blacklisted (either by name or tag).
  for _, item in ipairs(items) do
    if isBlacklisted(item) then
      -- 3.2a) Calculate how many total we have to remove.
      local toRemove = item.amount or 0
      print("Removing " .. toRemove .. " of " .. item.name .. "...")

      -- 3.2b) While there are still items to remove, export in batches.
      while toRemove > 0 do
        -- Select a turtle slot (1–16). 
        turtle.select(1)

        -- Determine how many items to export this pass (up to 64).
        local exportAmount = math.min(EXPORT_BATCH_SIZE, toRemove)

        -- Export items into the Turtle from the ME system.
        local exported = meBridge.exportItem(
          { name = item.name }, -- item filter table
          "west",               -- Destination side/peripheral
          exportAmount
        )

        -- 'exported' is a number, how many items were successfully exported
        if exported and exported > 0 then
          -- Drop the items below the Turtle (into a chest or trash).
          turtle.dropDown()
          -- Decrease remaining count.
          toRemove = toRemove - exported
        else
          print("Failed to export: " .. item.name)
          break
        end
      end
    end
  end

  ---------------------------------------------------------------------------
  -- At the end, cycle through all turtle slots and drop anything still inside.
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

while true do
  cleanupME()
  sleep(SCAN_INTERVAL)
end
