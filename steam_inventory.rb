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

    def test
      out = Array.new
      out.push("Test")
      out.push(@@defindex[@item["defindex"]]["name"])
      out.push(@@quality[@item["quality"]])
      out.push(@@origin[@item["origin"]])
      out
    end

    # debug
    # def puts_schema
    #   puts @@schema
    # end
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

    def test
      @items[0].test
    end

    # While storing data in files, use this to read in data. Called from both initialize and get_items
    # Later need to use ActiveRecord or other data store
    def read_files
      @items = Array.new
      items = JSON.parse(File.read(ITEMS_FILE))
      items["result"]["items"].each do | item |
        @items.push(Item.new(item))
      end
      # TODO: Delete these in favor of Items kookups
      @olditems = items
      @schema = JSON.parse(File.read(SCHEMA_FILE))
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

    # Download items and schema
    # get_items

    def dup_weap
      # Build lookup hash table for item descriptions because array index is sparse
      defindex = Hash.new
      @schema["result"]["items"].each do | item |
        defindex[item["defindex"]] = item
      end

      quality = Hash.new
      @schema["result"]["qualities"].each do | key, value |
        quality[value] = key
      end

      weapons = Array.new

      @olditems["result"]["items"]
        .select { | item | defindex[item["defindex"]]["craft_class"].eql? "weapon"}
        .each do | item |
          defitem = defindex[item["defindex"]]
          weapons.push({
            "tradable" => !item["flag_cannot_trade"],
            "craftable" => !item["flag_cannot_craft"],
            "quality" => quality[item["quality"]],
            "level" => item["level"],
            "name" => defitem["name"],
            "origin" => @schema["result"]["originNames"][item["origin"]]["name"],
            "defindex" => item["defindex"],
            "qualindex" => item["quality"]
          })
        end

      output = Array.new

      weapons
      .select { | row | weapons.select{ | weapon | weapon["defindex"] == row["defindex"] }.count > 1 }
      .sort_by { | row | row["qualindex"] }
      .reverse
      .sort_by { | row | row["defindex"] }
      .each do | row |
        output.push(row)
      end

      output.each do | row |
        printf("%-12s %-13s %-10s Level %3s %-28s %-15s\n",
          row["tradable"] ? "" : "Non-Tradable",
          row["craftable"] ? "" : "Non-Craftable",
          row["quality"],
          row["level"],
          row["name"],
          row["origin"]
        )
      end

      # FIXME: ERB needs proper binding
      # renderer = ERB.new(File.read('out.html.erb'))
      # File.write('out.html', renderer.result)
    end
  end
end
