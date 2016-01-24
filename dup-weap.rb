# Want to find duplicate tf2 weapons to sell for scrap
# Using inventory json file and schema json file from Steam Api

# require 'rest-client'
require 'net/http'

TF2_APP_ID = 440

def get_items(steam_id = ENV['STEAM_ID'], steam_api_key = ENV['STEAM_API_KEY'], app_id = TF2_APP_ID)
  raise 'Need to provide Steam API key' if steam_api_key.nil?
  raise 'Need to provide Steam ID' if steam_id.nil?
  puts 'Yay'
  File.write('./inv.json', 'Inventory!')
  File.write('./schema.json', 'Schema!')
end

get_items
