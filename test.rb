require './steam_inventory'

tf2 = SteamInventory::Items.new

# File.write('test.html',tf2.out_html(tf2.allitems.sort_by { | item | item.raw["quality"] }.reverse.sort_by { | item | item.raw["defindex"] }, images: false))
File.write('test.html',tf2.out_html(tf2.allitems.sort_by { | item | item.raw["quality"] }.reverse.sort_by { | item | item.raw["defindex"] }))
