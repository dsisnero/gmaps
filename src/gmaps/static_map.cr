require "http/client"

module GoogleMaps

  class UrlSigner

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
      digest = OpenSSL::Digest.new('sha1')
      OpenSSL::HMAC.digest(digest, key, data)
    end

    def url_safe_base64_decode(base64_string)
      Base64.decode64(base64_string.tr('-_', '+/'))
    end

    def url_safe_base64_encode(raw)
      Base64.encode64(raw).tr('+/', '-_').strip
    end
  end

  end



  class Marker
    property latitude : Float64
    property longitude : Float64
    property label : String
    property color : String = "blue"
    property size : String?

    def initialize(@lat : Float64, @lng : Float64, @label : String)
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


  class StaticMap

    API_URL = "https://maps.googleapis.com/maps/api/staticmap"

    property key : String
    property size : String
    property center : String
    property zoom : Int32
    property path : String?
    property scale : Int32?
    property format : String? = "png"
    property markers : Array(Marker) = [] of Marker

    def self.build
      map = new
      yield map
      map
    end

    def add_marker(location : GoogleMaps::Locatable, label : String? = nil)
      @markers = Marker.new
      @markers.location = location
      @markers.label = label
    end


    def fetch
      url = URI.parse(API_URL)
      params = HTTP::Params.build do |form|
        form.add("size", size)
        form.add("center", center)
        form.add("zoom", zoom.to_s)
        form.add("path", path) if path
        markers.each do |marker|
          form.add("markers", marker.to_url_param)
        end
        form.add("key", API_KEY)
        form.add("signature", sign(API_SECRET))
      end


      HTTP::Client.get(url, params: params).body
    end
  end
end
