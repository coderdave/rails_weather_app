require "rails_helper"

RSpec.describe Weather::NwsForecastClient do
  describe "#call" do
    it "returns forecast values from the nws forecast periods" do
      response = instance_double(Net::HTTPResponse, code: "200", body: forecast_response_body)
      http_client = class_double(Net::HTTP, get_response: response)
      forecast_url = "https://api.weather.gov/gridpoints/MTR/85,105/forecast"

      forecast_result = described_class.new(http_client: http_client).call(forecast_url)

      expect(forecast_result.current_temperature).to eq(72)
      expect(forecast_result.high_temperature).to eq(72)
      expect(forecast_result.low_temperature).to eq(58)
      expect(forecast_result.conditions).to eq("Partly Cloudy")
      expect(http_client).to have_received(:get_response) do |uri, headers|
        expect(uri.to_s).to eq(forecast_url)
        expect(headers["Accept"]).to eq("application/geo+json")
        expect(headers["User-Agent"]).to include("rails-weather-app")
      end
    end

    it "raises an error when the forecast response is not successful" do
      response = instance_double(Net::HTTPResponse, code: "503", body: "")
      http_client = class_double(Net::HTTP, get_response: response)

      expect do
        described_class.new(http_client: http_client).call("https://api.weather.gov/gridpoints/MTR/85,105/forecast")
      end.to raise_error(Weather::NwsForecastClient::Error, "nws forecast request failed")
    end

    it "raises an error when the forecast response cannot be parsed" do
      response = instance_double(Net::HTTPResponse, code: "200", body: "not json")
      http_client = class_double(Net::HTTP, get_response: response)

      expect do
        described_class.new(http_client: http_client).call("https://api.weather.gov/gridpoints/MTR/85,105/forecast")
      end.to raise_error(Weather::NwsForecastClient::Error, "nws forecast response could not be parsed")
    end

    it "raises an error when the forecast url is invalid" do
      http_client = class_double(Net::HTTP)

      expect do
        described_class.new(http_client: http_client).call("not a url")
      end.to raise_error(Weather::NwsForecastClient::Error, "nws forecast url is invalid")
    end

    def forecast_response_body
      {
        "properties" => {
          "periods" => [
            {
              "name" => "This Afternoon",
              "isDaytime" => true,
              "temperature" => 72,
              "shortForecast" => "Partly Cloudy"
            },
            {
              "name" => "Tonight",
              "isDaytime" => false,
              "temperature" => 58,
              "shortForecast" => "Mostly Clear"
            },
            {
              "name" => "Tomorrow",
              "isDaytime" => true,
              "temperature" => 76,
              "shortForecast" => "Sunny"
            }
          ]
        }
      }.to_json
    end
  end
end
