require "http/client"
require "./direction_result"
require "openssl/hmac"

module Gmaps
  module UrlSigner
    def sign(url, key)
      parsed_url = URI.parse(url)
      full_path = "#{parsed_url.path}?#{parsed_url.query}"

      signature = generate_signature(full_path, key)

      "#{parsed_url.scheme}://#{parsed_url.host}#{full_path}&signature=#{signature}"
    end

    def generate_signature(path, key)
      raw_key = url_safe_base64_decode(key)
      raw_signature = encrypt(raw_key, path)
      url_safe_base64_encode(raw_signature)
    end

    def encrypt(key, data)
      OpenSSL::HMAC.digest(OpenSSL::Algorithm::SHA1, key, data)
    end

    def url_safe_base64_decode(base64_string)
      Base64.decode(base64_string.tr("-_", "+/"))
    end

    def url_safe_base64_encode(raw)
      Base64.encode(raw).tr("+/", "-_").strip
    end
  end

  class Marker
    property latitude : Float64
    property longitude : Float64
    property label : String
    property color : String = "blue"
    property size : String?

    def initialize(@latitude : Float64, @longitude : Float64, @label : String, @color : String = "blue", @size : String? = nil)
    end

    def initialize(location : Location, @label : String? = nil, @color : String = "blue", @size : String? = nil)
      @latitude = location.latitude
      @longitude = location.longitude
    end

    def add_marker
      # add a marker to the map using lat, lng, label
    end

    def to_url_param
      String.build do |io|
        io << "size:#{size}%7C" if size
        io << "color:#{color}%7C"
        io << "label:#{label}%7C"
        io << "#{latitude},#{longitude}"
      end
    end
  end

  enum ImageFormat
    PNG
    PNG32
    GIF
    JPEG
    JPEP_BASELINE
  end

  enum MapType
    Roadmap
    Satellite
    Terrain
    Hybrid
  end

  class StaticMap
    Log = ::Log.for(self)
    include UrlSigner

    API_URL = "https://maps.googleapis.com/maps/api/staticmap"

    property api_key : String?
    property size : String = "640x640"
    property center : String?
    property zoom : Int32
    property path : String?
    property scale : Int32?
    property format : String? = "png"
    property markers : Array(Marker) = [] of Marker
    property path : String?

    def initialize(@api_key = nil, @size = "640x640", @center = "0,0", @zoom = 0, @path = nil, @scale = nil)
    end

    def self.build
      map = new
      yield map
      map
    end

    def add_marker(location : GoogleMaps::Locatable, label : String? = nil, color : String? = "blue", size : String? = nil)
      marker = Marker.new(location, label, color, size)
      markers << marker
      self
    end

    def add_route_overlay(route : Gmaps::Route)
      self.path = route.path_string
      self
    end

    def fetch(format : String = format, api_key : String? = api_key)
      raise "key is required" if api_key.nil?
      url = URI.parse(API_URL)
      params = HTTP::Params.build do |form|
        form.add("size", size)
        form.add("center", center) if center && !path
        form.add("zoom", zoom.to_s) if zoom && !path
        form.add("path", path) if path
        markers.each do |marker|
          form.add("markers", marker.to_url_param)
        end
        form.add("format", format)
        form.add("key", api_key)
        # form.add("signature", sign(API_URL, api_key))
      end
      url.query = params

      Log.debug { "fetching #{url}" }

      HTTP::Client.get(url)
    end
  end
end
