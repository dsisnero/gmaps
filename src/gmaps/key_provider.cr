require "./config"

module Gmaps
  module IKeyProvider
    def get_api_key : String?
    end
  end

  class KeyProvider
    include IKeyProvider

    def get_api_key
      ENV["GOOGLE_MAPS_API_KEY"]? || Gmaps.config.gmaps_api_key
    end
  end

  class_property key_provider : IKeyProvider = KeyProvider.new
end
