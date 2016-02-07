require './steam_inventory'

tf2 = SteamInventory::Items.new

puts tf2.out_text(tf2.dup_weap)

# puts tf2.test
