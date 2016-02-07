# Modularizing inventory functions from dup-weap.rb

require 'net/http'
require 'json'
require 'erb'

module SteamInventory
  TF2_APP_ID = 440
  FILE_PATH = '.'
  ITEMS_FILE = "#{FILE_PATH}/items.json"
  SCHEMA_FILE = "#{FILE_PATH}/schema.json"

  # Will contain lookup methods for names
  class Item
    @@schema = nil
    @@defindex = nil
    def initialize(item)
      # puts "Hi" unless @@schema
      self.init_schema  unless @@schema
      @item = item
    end

    def name
      @@defindex[@item["defindex"]]["name"]
    end

    def quality
      @@quality[@item["quality"]]
    end

    def origin
      @@origin[@item["origin"]]
    end

    def tradable?
      !@item["flag_cannot_trade"]
    end

    def craftable?
      !@item["flag_cannot_craft"]
    end

    def level
      @item["level"]
    end

    def craft_class
      @@defindex[@item["defindex"]]["craft_class"]
    end

    # Allow direct access to the item values
    def raw
      @item
    end

    def init_schema
      schema = JSON.parse(File.read(SCHEMA_FILE))

      # Build lookup hash table for item descriptions because array index is sparse
      @@defindex = Hash.new
      schema["result"]["items"].each do | itemdef |
        @@defindex[itemdef["defindex"]] = itemdef
      end

      @@quality = Hash.new
      schema["result"]["qualities"].each do | key, value |
        @@quality[value] = key
      end

      @@origin = Hash.new
      schema["result"]["originNames"].each do | origin |
        @@origin[origin["origin"]] = origin["name"]
      end

      @@schema = schema
    end
  end

  class Items
    def initialize
      self.read_files
    end

    # While storing data in files, use this to read in data. Called from both initialize and get_items
    # Later need to use ActiveRecord or other data store
    def read_files
      @items = Array.new
      items = JSON.parse(File.read(ITEMS_FILE))
      items["result"]["items"].each do | item |
        @items.push(Item.new(item))
      end
    end

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
      self.read_files
    end

    def dup_weap
      weapons = Array.new
      @items
        .select { | item | item.craft_class.eql? "weapon"}
        .select { | item | @items.select{ | allitem | allitem.raw["defindex"] == item.raw["defindex"] }.count > 1 }
        .sort_by { | item | item.raw["quality"] }
        .reverse
        .sort_by { | item | item.raw["defindex"] }
        .each do | item |
          weapons.push(item)
        end
      weapons
    end

    def out_html
      # FIXME: ERB needs proper binding
      # renderer = ERB.new(File.read('out.html.erb'))
      # File.write('out.html', renderer.result)
    end

    def out_text(items)
      output = String.new
      items.each do | item |
        output << sprintf("%-12s %-13s %-10s Level %3s %-28s %-15s\n",
          item.tradable? ? "" : "Non-Tradable",
          item.craftable? ? "" : "Non-Craftable",
          item.quality,
          item.level,
          item.name,
          item.origin
        )
      end
      output
    end
  end
end
