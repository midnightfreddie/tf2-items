require './steam_inventory'

tf2 = SteamInventory::Items.new

puts tf2.out_text(tf2.dup_weap)
puts ""
puts tf2.out_text(tf2.scrap_weap)

# File.write('out.html',tf2.out_html(tf2.dup_weap))
File.write('out.html',tf2.out_html(tf2.scrap_weap, "Possibly Scrappable Weapons"))
