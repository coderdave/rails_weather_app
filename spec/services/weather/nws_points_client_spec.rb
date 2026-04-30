require "rails_helper"

RSpec.describe Weather::NwsPointsClient do
  describe "#call" do
    it "returns the forecast metadata for a resolved location" do
      response = instance_double(Net::HTTPResponse, code: "200", body: points_response_body)
      http_client = class_double(Net::HTTP, get_response: response)
      resolved_location = Weather::ResolvedLocation.new(latitude: 37.3229, longitude: -122.0322)

      points_result = described_class.new(http_client: http_client).call(resolved_location)

      expect(points_result.forecast_url).to eq("https://api.weather.gov/gridpoints/MTR/85,105/forecast")
      expect(points_result.city).to eq("Cupertino")
      expect(points_result.state).to eq("CA")
      expect(points_result.time_zone).to eq("America/Los_Angeles")
      expect(http_client).to have_received(:get_response) do |uri, headers|
        expect(uri.to_s).to eq("https://api.weather.gov/points/37.3229,-122.0322")
        expect(headers["Accept"]).to eq("application/geo+json")
        expect(headers["User-Agent"]).to include("rails-weather-app")
      end
    end

    it "raises an error when the points response is not successful" do
      response = instance_double(Net::HTTPResponse, code: "503", body: "")
      http_client = class_double(Net::HTTP, get_response: response)
      resolved_location = Weather::ResolvedLocation.new(latitude: 37.3229, longitude: -122.0322)

      expect do
        described_class.new(http_client: http_client).call(resolved_location)
      end.to raise_error(Weather::NwsPointsClient::Error, "nws points request failed")
    end

    it "raises an error when the points response cannot be parsed" do
      response = instance_double(Net::HTTPResponse, code: "200", body: "not json")
      http_client = class_double(Net::HTTP, get_response: response)
      resolved_location = Weather::ResolvedLocation.new(latitude: 37.3229, longitude: -122.0322)

      expect do
        described_class.new(http_client: http_client).call(resolved_location)
      end.to raise_error(Weather::NwsPointsClient::Error, "nws points response could not be parsed")
    end

    def points_response_body
      {
        "properties" => {
          "forecast" => "https://api.weather.gov/gridpoints/MTR/85,105/forecast",
          "timeZone" => "America/Los_Angeles",
          "relativeLocation" => {
            "properties" => {
              "city" => "Cupertino",
              "state" => "CA"
            }
          }
        }
      }.to_json
    end
  end
end
