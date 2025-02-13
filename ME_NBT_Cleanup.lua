-- Connect to the ME Bridge
local me = peripheral.find("meBridge")

if not me then
    print("No ME system found!")
    return
end
-- List of NBT-heavy items to remove (Modify this as needed)
local blacklist = {
    "minecraft:enchanted_book",
    "minecraft:potion",
    "silentgear:gear",
    "tconstruct:tool",
    "dankstorage:dank",
    "apotheosis:gem",
    "minecraft:spawn_egg",
    "sophisticatedbackpacks:backpack",
    "tetra:modular_tool"
}
-- Function to remove blacklisted items
function clearME()
    local items = me.listItems() -- Get all items in the ME system
    for _, item in pairs(items) do
        for _, name in ipairs(blacklist) do
            if string.find(item.name, name) then
                local count = item.amount
                if me.exportItem({name = item.name, count = count}) then
    for slot = 1, 16 do  -- Check all Turtle inventory slots
        turtle.select(slot)
        if turtle.getItemCount() > 0 then
            turtle.dropDown() -- Drops the item into a chest below
        end
    end
end
                print("Removed " .. count .. " of " .. item.name)
            end
        end
    end
end
-- Run cleanup every 30 seconds
while true do
    clearME()
    sleep(30)
end
