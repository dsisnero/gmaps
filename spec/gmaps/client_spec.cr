require "../spec_helper"

describe Gmaps::Client do
  describe "#search_hospitals_by_name" do
    it "returns hospitals matching search query" do
      api_key = "test_api_key"
      client = Gmaps::Client.new(api_key)
      
      # Mock HTTP response using test data
      response_body = File.read("#{TEST_DATA}/hospital_search_result.json")
      WebMock.stub(:get, "https://maps.googleapis.com/maps/api/place/textsearch/json?query=Bellevue&location=40.7128,-74.0060&type=hospital&key=#{api_key}")
        .to_return(body: response_body)

      # Test the search
      hospitals = client.search_hospitals_by_name("Bellevue", 40.7128, -74.0060)
      
      # Verify results
      hospitals.size.should eq(1)
      hospital = hospitals.first
      
      hospital.name.should eq("NYC Health + Hospitals/Bellevue")
      hospital.place_id.should eq("ChIJ1QA2GchZwokRJYX3IHa0-1Y")
      hospital.latitude.should eq(40.7409351)
      hospital.longitude.should eq(-73.9765372)
      hospital.address.should eq("462 1st Avenue")
      hospital.rating.should eq(3.7)
    end

    it "returns empty array when no hospitals found" do
      api_key = "test_api_key"
      client = Gmaps::Client.new(api_key)
      
      # Mock empty results response
      empty_response = {
        "status" => "OK",
        "results" => [] of String
      }.to_json
      
      WebMock.stub(:get, "https://maps.googleapis.com/maps/api/place/textsearch/json?query=NonexistentHospital&location=40.7128,-74.0060&type=hospital&key=#{api_key}")
        .to_return(body: empty_response)

      hospitals = client.search_hospitals_by_name("NonexistentHospital", 40.7128, -74.0060)
      hospitals.should be_empty
    end

    it "raises error on API failure" do
      api_key = "test_api_key"
      client = Gmaps::Client.new(api_key)
      
      # Mock error response
      error_response = {
        "status" => "INVALID_REQUEST",
        "error_message" => "Invalid request"
      }.to_json
      
      WebMock.stub(:get, "https://maps.googleapis.com/maps/api/place/textsearch/json?query=ErrorTest&location=40.7128,-74.0060&type=hospital&key=#{api_key}")
        .to_return(status: 400, body: error_response)

      expect_raises(Exception, /Failed to fetch hospital information/) do
        client.search_hospitals_by_name("ErrorTest", 40.7128, -74.0060)
      end
    end
  end
end
