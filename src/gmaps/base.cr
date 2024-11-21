module Gmaps
  ROOT = Path["."].parent.expand

  def self.get_api_key : String?
    api_key = ENV["GMAPS_API_KEY"]? || config.gmaps_api_key
  end

  def self.config
    Config.load_from_config
  end
end
