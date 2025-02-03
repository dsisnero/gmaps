require "./lat_lon"

module PolylineUtils
  # Define a method to encode a list of Gmaps::Locatable objects
  # as a polyline string
  def encode(locations : Enumerable(Gmaps::Locatable)) : String
    # Initialize an empty array to store the result
    result = Array(String).new

    # Initialize variables to store previous latitude and longitude values
    prev_lat = 0
    prev_long = 0

    # Iterate through each location in the list
    locations.each do |location|
      # Convert latitude and longitude to integer values
      i_lat = (location.lat * 1e5).to_i32
      i_long = (location.long * 1e5).to_i32

      # Calculate delta values for latitude and longitude
      delta_lat = encode_value(i_lat - prev_lat)
      delta_long = encode_value(i_long - prev_long)

      # Update previous latitude and longitude values
      prev_lat = i_lat
      prev_long = i_long

      # Add delta values to the result array
      result << delta_lat
      result << delta_long
    end

    # Join the result array into a single string and return
    result.join("")
  end

  # step 1
  # convert the decimal value to binary. Note a negative value must
  # be calculated by using its twos complement by inverting the
  # binary and adding 1 to the result
  # step 2
  # left shift the binary result one bit
  # step 3
  # if the value is negative, invert the binary result
  # step 4

  private def encode_value(value : Int32)
    actual_value = if value < 0
                     (value << 1)
                       .else
                     value << 1
                   end
    chunks = split_into_chunks(actual_value)
    chunks.map { |chunk| (chunk + 63).chr }.join
  end

  # Define a method to split an integer into chunks for encoding
  private def split_into_chunks(to_encode : Int32) : Array(Int32)
    # Initialize an empty array to store chunks
    chunks = Array(Int32).new

    # Initialize a variable to store the value being encoded
    value = to_encode

    # Perform step 5-8: Split the value into chunks
    while value >= 32
      chunks << ((value & 31) | 0x20)
      value = value >> 5
    end

    # Add the remaining value as a chunk
    chunks << value

    # Return the array of chunks
    chunks
  end

  # Define a method to simplify a list of Gmaps::Locatable objects using the Ramer–Douglas–Peucker algorithm
  def simplify(epsilon : Float64) : Array(Gmaps::Locatable)
    # Find the point with the maximum distance
    dmax = 0.0
    index = 0
    end_index = size

    (1..(end_index - 2)).each do |i|
      d = perpendicular_distance(self[i], self[0], self[end_index - 1])
      if d > dmax
        index = i
        dmax = d
      end
    end

    # If max distance is greater than epsilon, recursively simplify
    if dmax > epsilon
      # Recursive call
      rec_results1 = self[0..index].simplify(epsilon)
      rec_results2 = self[index..end_index].simplify(epsilon)

      # Build the result list
      rec_results1[0..-2] + rec_results2
    else
      [self[0], self[end_index - 1]]
    end
  end

  # Define a method to calculate the perpendicular distance from a point to a line
  private def perpendicular_distance(pt : Gmaps::Locatable, line_from : Gmaps::Locatable, line_to : Gmaps::Locatable) : Float64
    numerator = ((line_to.longitude - line_from.longitude) * (line_from.latitude - pt.latitude) -
                 (line_from.longitude - pt.longitude) * (line_to.latitude - line_from.latitude)).abs
    denominator = Math.sqrt((line_to.longitude - line_from.longitude).pow(2.0) +
                            (line_to.latitude - line_from.latitude).pow(2.0))
    numerator / denominator
  end
end
# step 2 & 4
