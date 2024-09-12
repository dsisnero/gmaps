require "../spec_helper"
puts "SRC #{SRC}"
require "../../src/gmaps/coordinate_parser"

describe Gmaps::CoordinateParser do
  it "doItAsOsm" do
    test_coordinates = [
      "50.06773 14.37742", "50.06773, 14.37742",
      "+50.06773 +14.37742", "+50.06773, +14.37742",
    ]

    test_coordinates.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end

    nsew_formats = [
      "N50.06773 E14.37742", "N50.06773, E14.37742",
      "50.06773N 14.37742E", "50.06773N, 14.37742E",
      # Add more test cases for different NSEW formats
    ]

    nsew_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end

    # Add more test cases for different NSEW formats

    nsew_west_formats = [
      "N50.06773 W14.37742", "N50.06773, W14.37742",
      "50.06773N 14.37742W", "50.06773N, 14.37742W",
      # Add more test cases for different NSEW west formats
    ]

    nsew_west_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(-14.37742, 0.000005)
    end

    se_formats = [

      "S50.06773 E14.37742", "S50.06773, E14.37742", "50.06773S 14.37742E", "50.06773S, 14.37742E",
    ]

    se_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(-50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end

    sw_formats = [

      "S50.06773 W14.37742", "S50.06773, W14.37742", "50.06773S 14.37742W", "50.06773S, 14.37742W",
    ]

    sw_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(-50.06773, 0.000005)
      ll.longitude.should be_close(-14.37742, 0.000005)
    end

    ne_formats = [

      "N 50° 04.064 E 014° 22.645", "N 50° 04.064' E 014° 22.645", "N 50° 04.064', E 014° 22.645'",
      "N50° 04.064 E14° 22.645", "N 50 04.064 E 014 22.645", "N50 4.064 E14 22.645", "50° 04.064' N, 014° 22.645' E",
    ]

    ne_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end

    nw_formats = [

      "N 50° 04.064 W 014° 22.645", "N 50° 04.064' W 014° 22.645", "N 50° 04.064', W 014° 22.645'",
      "N50° 04.064 W14° 22.645", "N 50 04.064 W 014 22.645", "N50 4.064 W14 22.645", "50° 04.064' N, 014° 22.645' W",
    ]

    nw_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(-14.37742, 0.000005)
    end

    se_formats = [

      "S 50° 04.064 E 014° 22.645", "S 50° 04.064' E 014° 22.645", "S 50° 04.064', E 014° 22.645'",
      "S50° 04.064 E14° 22.645", "S 50 04.064 E 014 22.645", "S50 4.064 E14 22.645", "50° 04.064' S, 014° 22.645' E",
    ]

    se_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(-50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end

    sw_formats = [

      "S 50° 04.064 W 014° 22.645", "S 50° 04.064' W 014° 22.645", "S 50° 04.064', W 014° 22.645'",
      "S50° 04.064 W14° 22.645", "S 50 04.064 W 014 22.645", "S50 4.064 W14 22.645", "50° 04.064' S, 014° 22.645' W",
    ]

    sw_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(-50.06773, 0.000005)
      ll.longitude.should be_close(-14.37742, 0.000005)
    end

    ne_dms_formats = [

      "N 50° 4' 03.828\" E 14° 22' 38.712\"", "N 50° 4' 03.828\", E 14° 22' 38.712\"",
      "N 50° 4′ 03.828″, E 14° 22′ 38.712″", "N50 4 03.828 E14 22 38.712", "N50 4 03.828, E14 22 38.712", "50°4'3.828\"N 14°22'38.712\"E",
    ]

    ne_dms_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end

    nw_dms_formats = [

      "N 50° 4' 03.828\" W 14° 22' 38.712\"", "N 50° 4' 03.828\", W 14° 22' 38.712\"",
      "N 50° 4′ 03.828″, W 14° 22′ 38.712″", "N50 4 03.828 W14 22 38.712", "N50 4 03.828, W14 22 38.712", "50°4'3.828\"N 14°22'38.712\"W",
    ]

    nw_dms_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(-14.37742, 0.000005)
    end
    se_dms_formats = [

      "S 50° 4' 03.828\" E 14° 22' 38.712\"", "S 50° 4' 03.828\", E 14° 22' 38.712\"",
      "S 50° 4′ 03.828″, E 14° 22′ 38.712″", "S50 4 03.828 E14 22 38.712", "S50 4 03.828, E14 22 38.712", "50°4'3.828\"S 14°22'38.712\"E",
    ]

    se_dms_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(-50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end
    # Todo SW and up

    sw_dms_formats = [

      "S 50° 4' 03.828\" W 14° 22' 38.712\"", "S 50° 4' 03.828\", W 14° 22' 38.712\"",
      "S 50° 4′ 03.828″, W 14° 22′ 38.712″", "S50 4 03.828 W14 22 38.712", "S50 4 03.828, W14 22 38.712", "50°4'3.828\"S 14°22'38.712\"W",
    ]

    sw_dms_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(-50.06773, 0.000005)
      ll.longitude.should be_close(-14.37742, 0.000005)
    end

    # Add more test cases for different NSEW west formats

    # Add similar tests for other NSEW and S formats

    dms_formats = [
      "N 50° 04.064 E 014° 22.645",
      "N 50° 04.064' E 014° 22.645",
      "N 50° 04.064', E 014° 22.645'",
      "N50° 04.064 E14° 22.645",
      "N 50 04.064 E 014 22.645",
      "N50 4.064 E14 22.645",
      "50° 04.064' N, 014° 22.645' E",
      # Add more test cases for different DMS formats
    ]

    dms_formats.each do |c|
      ll = Gmaps::CoordinateParser.parse(c)
      ll.latitude.should be_close(50.06773, 0.000005)
      ll.longitude.should be_close(14.37742, 0.000005)
    end

    # Add similar tests for other DMS formats

    # Add tests for DM and D formats

    # Add tests for various combinations of formats

    # Add tests for negative latitude.tudes and longitude.itudes
  end

  it "other" do
    expect_raises(Gmaps::ParseException) do
      ll = Gmaps::CoordinateParser.parse("N 1° E 2°")
      ll.latitude.should be_close(1, 0.000005)
      ll.longitude.should be_close(2, 0.000005)
    end
  end
end
