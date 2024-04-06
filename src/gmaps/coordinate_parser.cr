require "set"
require "log"
require "./lat_lon"

module Gmaps
  class ParseException < Exception
  end

  # Parses geographic coordinates in various formats and returns a LatLon value.
  #
  # Supports formats like:
  #
  # * Degrees Minutes Seconds (DMS): 41°24'12.2"N 2°10'26.5"E
  # * Degrees Minutes (DM): 41°24.2'N 2°10.4'E
  # * Decimal Degrees (DD): 41.40333 2.17403
  #
  # Latitude ranges from -90 to 90. Longitude ranges from -180 to 180.
  #
  # Can raise a ParseException on invalid input.
  # Some Examples of usage:
  # CoordinateParser.parse("41°24'12.2"N 2°10'26.5"E")
  # CoordinateParser.parse("41.40333 2.17403")
  # CoordinateParser.parse("41°24.2'N 2°10.4'E")
  # CoordinateParser.parse("41.40333 2.17403")
  class CoordinateParser
    Log = ::Log.for("coord_parser")
    DMS = "\\s*(\\d{1,3})\\s*(?:°|d|º| |g|o)" +
          "\\s*([0-6]?\\d)\\s*(?:'|m| |´|’|′)" +
          "\\s*(?:" +
          "([0-6]?\\d(?:[,.]\\d+)?)" +
          "\\s*(?:\"|''|s|´´|″)?" + ")?\\s*"

    DM = "\\s*(\\d{1,3})\\s*(?:°|d|º| |g|o)" +
         "\\s*(?:" +
         "([0-6]?\\d(?:[,.]\\d+)?)" +
         "\\s*(?:'|m| |´|’|′)?" + ")?\\s*"

    D = "\\s*(\\d{1,3}(?:[,.]\\d+)?)\\s*(?:°|d|º| |g|o|)\\s*"

    NSEOW      = "([NSEOW])"
    SEPARATORS = "[ ,;/]?"

    DMS_SINGLE  = /#{DMS}$/i
    DM_SINGLE   = /#{DM}$/i
    D_SINGLE    = /#{D}$/i
    DMS_COORD   = /#{DMS}#{NSEOW}#{SEPARATORS}#{DMS}([NSEOW])$/i
    DMS_COORD_2 = /#{NSEOW}#{DMS}#{SEPARATORS}#{NSEOW}#{DMS}$/i
    DM_COORD    = /#{DM}#{NSEOW}#{SEPARATORS}#{DM}([NSEOW])$/i
    DM_COORD_2  = /#{NSEOW}#{DM}#{SEPARATORS}#{NSEOW}#{DM}$/i

    POSITIVE = "NEO"

    def self.parse(coordinates : String) : LatLon
      new().parse(coordinates)
    end

    def self.parse_lat_lng(latitude : String?, longitude : String?)
      new().parse_lat_lng(latitude, longitude)
    end

    def parse_lat_lng(latitude : String, longitude : String) : LatLon
      Log.info { "parsing lat:#{latitude} : lng : #{longitude}" }
      if latitude.nil? || latitude.empty? || longitude.nil? || longitude.empty?
        raise ParseException.new("nil or empty coordinates lat #{latitude} long #{longitude}")
      end

      lat = latitude.to_f?
      lon = longitude.to_f?

      if lat.nil? || lon.nil?
        # try degree minute seconds
        lat = parse_dms(latitude, true)
        lon = parse_dms(longitude, false)
      end

      validate_and_round(lat, lon)
    end

    def in_range(lat, lon)
      (lat <= 90.0 && lat >= -90.0) && (lon <= 180.0 && lon >= -180.0)
    end

    def is_lat?(direction)
      direction.upcase.chars.any? { |c| "NS".includes?(c) }
    end

    def coord_sign(direction)
      POSITIVE.upcase.includes?(direction.upcase) ? 1 : -1
    end

    def parse(coordinates : String) : LatLon
      if coordinates.nil? || coordinates.empty?
        raise(ArgumentError.new("null or empty coordinates"))
      end

      begin
        m = DMS_COORD.match(coordinates)
        if m
          dir1 = m[4]
          dir2 = m[8]
          c1 = coord_from_matcher(m, 1, 2, 3, dir1)
          c2 = coord_from_matcher(m, 5, 6, 7, dir2)
          return order_coordinates(dir1, dir2, c1, c2)
        else
          m = DMS_COORD_2.match(coordinates)
          if m
            dir1 = m[1]
            dir2 = m[5]
            c1 = coord_from_matcher(m, 2, 3, 4, dir1)
            c2 = coord_from_matcher(m, 6, 7, 8, dir2)
            return order_coordinates(dir1, dir2, c1, c2)
          else
            m = DM_COORD.match(coordinates)
            if m
              dir1 = m[3]
              dir2 = m[6]
              c1 = coord_from_matcher(m, 1, 2, dir1)
              c2 = coord_from_matcher(m, 4, 5, dir2)
              return order_coordinates(dir1, dir2, c1, c2)
            else
              m = DM_COORD_2.match(coordinates)
              if m
                dir1 = m[1]
                dir2 = m[4]
                c1 = coord_from_matcher(m, 2, 3, dir1)
                c2 = coord_from_matcher(m, 5, 6, dir2)
                return order_coordinates(dir1, dir2, c1, c2)
              elsif coordinates.size > 4
                ",;/ ".each_char do |delim|
                  cnt = count_matches(coordinates, delim)
                  if cnt == 1
                    latlon = coordinates.split(delim)
                    if latlon.size == 2
                      return parse_lat_lng(latlon[0], latlon[1])
                    end
                  end
                end
              end
            end
          end
        end
      rescue ex : Exception
        raise ParseException.new("invalid coordinates #{coordinates}")
      end
      raise ParseException.new("invalid coordinates #{coordinates}")
    end

    # def self.parse(coordinates) : LatLon
    #   if coordinates.nil? || coordinates.empty?
    #     raise ArgumentError.new("nil or empty coordinates")
    #   end
    #
    #   m = DMS_COORD.match(coordinates)
    #   if m
    #     dir1 = m[4]
    #     dir2 = m[8]
    #     c1 = coord_from_matcher(m, 1, 2, 3, dir1)
    #     c2 = coord_from_matcher(m, 5, 6, 7, dir2)
    #     if is_lat?(dir1) && !is_lat?(dir2)
    #       return validate_and_round(c1, c2)
    #     elsif !is_lat?(dir1) && is_lat?(dir2)
    #       return validate_and_round(c2, c1)
    #     else
    #       return ParseException.new("Parsing ")
    #     end
    #   elsif coordinates.length > 4
    #     delimiters = ",;/ "
    #     delimiters.chars.each do |delim|
    #       cnt = coordinates.count(delim)
    #       if cnt == 1
    #         latlon = coordinates.split(delim)
    #         if latlon.length == 2
    #           return parse_lat_lng(latlon[0], latlon[1])
    #         end
    #       elsif cnt > 1
    #         return ParseException.new("Parsing ")
    #       end
    #     end
    #   end
    #
    #   ParseException.new("Invalid coordinates '#{coordinates}'")
    # end

    def order_coordinates(dir1 : String, dir2 : String, c1 : Float64, c2 : Float64) : LatLon
      if is_lat?(dir1) && !is_lat?(dir2)
        validate_and_round(c1, c2)
      elsif !is_lat?(dir1) && is_lat?(dir2)
        validate_and_round(c2, c1)
      else
        raise ParseException.new("invalid coordinates 1: #{c1} 2: #{c2}")
      end
    end

    def count_matches(s : String, c : Char) : Int32
      count = 0
      s.each_char do |char|
        count += 1 if char == c
      end
      count
    end

    def validate_and_round(lat : Float64, lon : Float64) : LatLon
      lat = lat.round(8)
      lon = lon.round(8)

      if in_range(lat, lon)
        return LatLon.new(lat, lon)
      end

      if lat > 90.0 || lat < -90.0
        if in_range(lon, lat)
          return LatLon.new(lon, lat)
        end
      end

      raise ParseException.new("value(s) out of range lat #{lat} lon #{lon}")
    end

    def parse_dms(coord : String, is_lat_coord : Bool) : Float64
      directions = is_lat_coord ? "NS" : "EOW"
      coord = coord.strip.upcase

      if coord.size > 3
        dir = 'n'
        if directions.includes?(coord[0].to_s)
          dir = coord[0]
          coord = coord[1..-1]
        elsif directions.includes?(coord[-1].to_s)
          dir = coord[-1]
          coord = coord[0..-2]
        end

        m = DMS_SINGLE.match(coord)
        begin
          if m
            return coord_from_matcher(m, 1, 2, 3, dir)
          end
          m = DM_SINGLE.match(coord)
          if m
            return coord_from_matcher(m, 1, 2, dir)
          end
          m = D_SINGLE.match(coord)
          if m
            return coord_from_matcher(m, 1, dir)
          end
        rescue ex : Exception
          raise ParseException.new("#{coord} has wrong number format")
        end
      end

      raise ParseException.new("Parsing #{coord} failed")
    end

    def coord_from_matcher(m : Regex::MatchData, idx1 : Int32, idx2 : Int32, idx3 : Int32, sign : String | Char) : Float64
      minutes = m[idx2]
      seconds = m[idx3]
      (coord_sign(sign) * dms_to_decimal(m[idx1].to_f64, minutes ? minutes.to_f64 : 0.0, seconds ? seconds.to_f64 : 0.0)).round(8)
    end

    def coord_from_matcher(m : Regex::MatchData, idx1 : Int32, idx2 : Int32, sign : String | Char) : Float64
      minutes = m[idx2]
      (coord_sign(sign) * dms_to_decimal(m[idx1].to_f64, minutes ? minutes.to_f64 : 0.0, 0.0)).round(8)
    end

    def coord_from_matcher(m : Regex::MatchData, idx1 : Int32, sign : String | Char) : Float64
      (coord_sign(sign) * dms_to_decimal(m[idx1].to_f64, 0.0, 0.0)).round(8)
    end

    def dms_to_decimal(degree : Float64, minutes : Float64? = nil, seconds : Float64? = nil) : Float64
      minutes ||= 0.0
      seconds ||= 0.0
      degree + (minutes / 60.0) + (seconds / 3600.0)
    end

    def round_to_8_decimals(x : Float64?) : Float64?
      x ? ((x * 10.0**8) / 10.0**8).round : nil
    end
  end
end
