require "../spec_helper"
require "../../src/gmaps/app"

describe Gmaps::Client do
  describe "with invalid API key" do
    describe "#search_hospitals_by_name" do
      it "raises an error" do
        VCR.use_cassette("edit_api_invalid_key") do
          client = Gmaps::Client.new("invalid_api_key")

          expect_raises(Gmaps::InvalidApiKeyError) do
            client.search_hospitals_by_name("Bellevue", 40.7128, -74.0060)
          end
        end
      end
    end
  end

  describe "with valid API key" do
    with_valid_api_key do
      describe "#search_hospitals_by_name" do
        it "returns hospitals matching search query" do
          VCR.use_cassette("search_hospitals_bellevue") do
            client = Gmaps::Client.new(VALID_API_KEY)

            hospitals = client.search_hospitals_by_name("Bellevue", 40.7128, -74.0060)
            hospitals.size.should be > 0
            hospital = hospitals.first

            hospital.name.should contain("Bellevue")
            hospital.place_id.should_not be_empty
            hospital.latitude.should be_a(Float64)
            hospital.longitude.should be_a(Float64)
            if address = hospital.address
              address.should_not be_empty
            end
            if rating = hospital.rating
              rating.should be_a(Float64?)
            end
          end
        end

        it "returns empty array when no hospitals found" do
          VCR.use_cassette("search_hospitals_nonexistent") do
            client = Gmaps::Client.new(VALID_API_KEY)

            hospitals = client.search_hospitals_by_name("XXXXXXXXXXXXXXXXXXXXXXXXXXX_NONEXISTENT_HOSPITAL_NAME_123456789", 40.7128, -74.0060)
            hospitals.should be_empty
          end
        end
      end

      describe "#find_nearest_hospitals" do
        it "returns nearby hospitals" do
          VCR.use_cassette("find_nearest_hospitals") do
            client = Gmaps::Client.new(VALID_API_KEY)

            # Using coordinates for New York City
            hospitals = client.find_nearest_hospitals(40.7128, -74.0060)
            hospitals.size.should be > 0

            hospital = hospitals.first
            hospital.name.should_not be_empty
            hospital.place_id.should_not be_empty
            hospital.latitude.should be_a(Float64)
            hospital.longitude.should be_a(Float64)
            if address = hospital.address
              address.should_not be_empty
            end
            if rating = hospital.rating
              rating.should be_a(Float64?)
            end
          end
        end

        it "returns empty array when no hospitals found" do
          VCR.use_cassette("find_nearest_hospitals_none") do
            api_key = Gmaps.key_provider.get_api_key.not_nil!
            client = Gmaps::Client.new(api_key)

            # Using coordinates for middle of ocean
            hospitals = client.find_nearest_hospitals(0.0, 0.0)
            hospitals.should be_empty
          end
        end

        it "accepts a Locatable object" do
          VCR.use_cassette("find_nearest_hospitals_locatable") do
            api_key = Gmaps.key_provider.get_api_key.not_nil!
            client = Gmaps::Client.new(api_key)

            # Create a mock Locatable object
            location = Gmaps::LatLon.new(40.7128, -74.0060)

            hospitals = client.find_nearest_hospitals(location)
            hospitals.size.should be > 0

            hospital = hospitals.first
            hospital.name.should_not be_empty
          end
        end
      end

      describe "#get_satellite_image" do
        it "returns image data for valid coordinates" do
          VCR.use_cassette("satellite_image") do
            api_key = Gmaps.key_provider.get_api_key.not_nil!
            client = Gmaps::Client.new(api_key)

            # New York City coordinates
            image_data = client.get_satellite_image(40.7128, -74.0060)

            # Check that we got image data back
            image_data.should be_a(Bytes)
            image_data.size.should be > 0
          end
        end

        it "accepts custom radius and adjusts zoom accordingly" do
          VCR.use_cassette("satellite_image_custom_radius") do
            api_key = Gmaps.key_provider.get_api_key.not_nil!
            client = Gmaps::Client.new(api_key)

            # Test with a larger radius
            image_data = client.get_satellite_image(40.7128, -74.0060, 5000)
            image_data.should be_a(Bytes)
            image_data.size.should be > 0
          end
        end
      end
    end
  end
end
