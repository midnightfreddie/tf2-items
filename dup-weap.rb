# Want to find duplicate tf2 weapons to sell for scrap
# Using inventory json file and schema json file from Steam Api

# require 'rest-client'
require 'net/http'
require 'json'

TF2_APP_ID = 440
FILE_PATH = '.'
ITEMS_FILE = "#{FILE_PATH}/items.json"
SCHEMA_FILE = "#{FILE_PATH}/schema.json"

def get_items(steam_id = ENV['STEAM_ID'], steam_api_key = ENV['STEAM_API_KEY'], app_id = TF2_APP_ID)
  raise 'Need to provide Steam API key' if steam_api_key.nil?
  raise 'Need to provide Steam ID' if steam_id.nil?
  # Inventory
  uri = URI("http://api.steampowered.com/IEconItems_#{app_id}/GetPlayerItems/v0001/?key=#{steam_api_key}&SteamID=#{steam_id}")
  result = Net::HTTP.get_response(uri)
  raise 'Failure requesting inventory' unless result.is_a?(Net::HTTPSuccess)
  File.write(ITEMS_FILE, result.body)
  # Schema
  uri = URI("http://api.steampowered.com/IEconItems_#{app_id}/GetSchema/v0001/?key=#{steam_api_key}")
  result = Net::HTTP.get_response(uri)
  raise 'Failure requesting inventory' unless result.is_a?(Net::HTTPSuccess)
  File.write(SCHEMA_FILE, result.body)
end

# Download items and schema
# get_items

items = JSON.parse(File.read(ITEMS_FILE))
schema = JSON.parse(File.read(SCHEMA_FILE))

# Build lookup hash table for item descriptions because array index is sparse
defindex = Hash.new
schema["result"]["items"].each do | item |
  defindex[item["defindex"]] = item
end

quality = Hash.new
schema["result"]["qualities"].each do | key, value |
  quality[value] = key
end

items["result"]["items"]
  .select { | item | defindex[item["defindex"]]["craft_class"].eql? "weapon"}
  .sort_by { | item | item["quality"] }
  .reverse
  .sort_by { | item | item["defindex"] }
  .each do | item |
    defitem = defindex[item["defindex"]]
    printf("%-12s %-10s Level %3s %-28s %-15s\n",
      item["flag_cannot_trade"] ? "Non-Tradable" : "",
      quality[item["quality"]],
      item["level"],
      defitem["name"],
      schema["result"]["originNames"][item["origin"]]["name"]
    )
  end
