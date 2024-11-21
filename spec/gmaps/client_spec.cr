require "../spec_helper"
require "../../src/gmaps/app"

describe Gmaps::Client do
  describe "#search_hospitals_by_name" do
    it "returns hospitals matching search query" do
      VCR.use_cassette("search_hospitals_bellevue") do
        api_key = ENV["GMAPS_API_KEY"]? || Gmaps.config.gmaps_api_key
        client = Gmaps::Client.new(api_key)

        hospitals = client.search_hospitals_by_name("Bellevue", 40.7128, -74.0060)

        hospitals.size.should be > 0
        hospital = hospitals.first

        hospital.name.should contain("Bellevue")
        hospital.place_id.should_not be_empty
        hospital.latitude.should be_a(Float64)
        hospital.longitude.should be_a(Float64)
        hospital.address.should_not be_empty
        hospital.rating.should be_a(Float64?)
      end
    end

    it "returns empty array when no hospitals found" do
      VCR.use_cassette("search_hospitals_nonexistent") do
        api_key = ENV["GMAPS_API_KEY"]? || Gmaps.config.gmaps_api_key
        client = Gmaps::Client.new(api_key)

        hospitals = client.search_hospitals_by_name("_NonexistentHospitalXYZ123", 40.7128, -74.0060)
        hospitals.should be_empty
      end
    end

    it "raises error on API failure" do
      VCR.use_cassette("search_hospitals_error") do
        api_key = "invalid_api_key"
        client = Gmaps::Client.new(api_key)

        expect_raises(Exception, /Failed to fetch hospital information/) do
          client.search_hospitals_by_name("ErrorTest", 40.7128, -74.0060)
        end
      end
    end
  end
end
