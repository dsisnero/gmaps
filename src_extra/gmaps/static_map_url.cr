map = StaticMapUrl.new("YOUR_API_KEY") do

# Define a StatikGMapsUrl class representing an URL for Google's Static Map API
class StaticMapUrl

  # builder for StaticMapUrl
  # url =StaticMapUrl.build("YOUR_API_KEY") do |it|
  #   it.language = "en"
  #   it.map_type = MapType::Roadmap
  #   it.image_format = ImageFormat::PNG
  #   it.size = {400, 300}
  #   it.scale = 2
  #   it.center = {48.8566, 2.3522}
  #   it.encoded_path = "akkvkfrieeeifixklllhlhl"
  # end.to_s
  #
  def self.build(api_key : String, base_url : String = "maps.googleapis.com/maps/api/staticmap")
    it = new(api_key, base_url)
    yield it
    it
  end
  # Initialize the class with required parameters
  def initialize(api_key : String, base_url : String = "maps.googleapis.com/maps/api/staticmap", &setup)
    @api_key = api_key
    @base_url = base_url
    @encoded_path = nil

    # Default values for optional parameters
    @https = true
    @premium_plan = false
    @downscale = true
    @markers = [] of StatikMapsLocation
    @path = [] of StatikMapsLocation
    @visible = [] of StatikMapsLocation
    @encode_path = false
    @simplify_path = false
  end

  # Accessors for properties
  property https : Bool
  property language : String?
  property region : String?
  property style : String?
  property premium_plan : Bool
  property downscale : Bool
  property map_type : MapType?
  property image_format : ImageFormat?
  property size : Tuple(Int32, Int32)?
  property scale : Int32
  property center : StatikMapsLocation?
  property zoom : Int32?
  property markers : Array(StatikMapsLocation)
  property path : Array(StatikMapsLocation)
  property encoded_path : String?
  property visible : Array(StatikMapsLocation)
  property encode_path : Bool
  property simplify_path : Bool

  # Convert the object to a string representation
  def to_s
    @setup.call

    # Validation checks
    raise "Size parameter is required" unless @size
    raise "Scale must be 1, 2 or 4 with premiumPlan or in 1, 2 without" unless (1..2).include?(@scale) || (@premium_plan && @scale == 4)
    raise "Allow downscaling or follow the size limitation as specified by Google" unless @downscale || @scaled_size.all? { |s| s <= @max_size }
    raise "Values for center and zoom or markers, path or visible are required" unless @center && @zoom || !@markers.empty? || (!@path.empty? || !@encoded_path.nil? || !@visible.empty?
    raise "Zoom values are required to be >= 0 and <= 20" unless !@zoom || (0..20).include?(@zoom)

    # Construct URL parameters
    params = {
      "key" => @api_key,
      "size" => "#{@size[0]}x#{@size[1]}",
      "scale" => @scale,
      "language" => @language,
      "region" => @region,
      "style" => @style,
      "maptype" => @map_type,
      "format" => @image_format,
      "center" => @center,
      "zoom" => @zoom,
      "markers" => @markers.to_url_param,
      "path" => path_to_url_param,
      "visible" => @visible.to_url_param
    }

    # Construct URL
    url = make_url(params)

    # Simplify path if URL length exceeds the limit
    simplified_url = simplify_path(url, params) if url.length > @max_url_length || @simplify_path

    # Return URL
    return simplified_url || url
  end


  # path_to_url_param
  # either use encoded_path or path
  # if using path and encode_path is true, path is encoded
  # if using encoded_path and encode_path is false, path is not encoded
  def path_to_url_param
    case {@encoded_path,@path, @encode_path}
    in {String, _, _}
      "enc:#{@encoded_path}"
    in {Nil, Array(StatikMapsLocation), true}
      "enc:#{@path.encode}"
    in {Nil, Array(StatikMapsLocation), false}
      @path.to_url_param
    end
  end

    @encoded_path ? @path.encode : @path.to_url_param



  # Define methods for internal use

  # Make the URL from parameters
  privte def make_url(params)
    protocol = @https ? "https" : "http"
    query_params = params.reject { |_, v| v.nil? }.map { |k, v| "#{k}=#{v}" }.join("&")
    return "#{protocol}://#{@base_url}?#{query_params}"
  end

  # Simplify path if URL length exceeds the limit
  private def simplify_path(url, params)
    epsilon = 0.1
    simplified_url = url
    simplified_path = @path

    while simplified_url.length > @max_url_length
      simplified_path = simplified_path.simplify(epsilon)
      params["path"] = @encode_path ? "enc:#{simplified_path.encode}" : simplified_path.to_url_param
      simplified_url = make_url(params)
      epsilon += epsilon / 2
    end

    return simplified_url
  end

  # Downscale the image size
  private def downscale
    max_actual_size = @size.max
    ratio = @max_size.to_f / max_actual_size
    @size = [@size[0] * ratio, @size[1] * ratio]
  end
end
