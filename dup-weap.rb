# Want to find duplicate tf2 weapons to sell for scrap
# Using inventory json file and schema json file from Steam Api

# require 'rest-client'
require 'net/http'

TF2_APP_ID = 440

def get_items(steam_id = ENV['STEAM_ID'], steam_api_key = ENV['STEAM_API_KEY'], app_id = TF2_APP_ID)
  raise 'Need to provide Steam API key' if steam_api_key.nil?
  raise 'Need to provide Steam ID' if steam_id.nil?
  # Inventory
  uri = URI("http://api.steampowered.com/IEconItems_#{app_id}/GetPlayerItems/v0001/?key=#{steam_api_key}&SteamID=#{steam_id}")
  result = Net::HTTP(uri)
  raise 'Failure requesting inventory' unless result.is_a?(Net:HTTPSuccess)
  File.write('./inv.json', result.body)
  # Schema
  uri = URI("http://api.steampowered.com/IEconItems_#{app_id}/GetSchema/v0001/?key=#{steam_api_key}")
  result = Net::HTTP(uri)
  raise 'Failure requesting inventory' unless result.is_a?(Net:HTTPSuccess)
  File.write('./schema.json', result.body)
end

get_items
