require "rails_helper"

RSpec.describe Weather::ForecastClient do
  describe "#call" do
    let(:resolved_location) do
      Weather::ResolvedLocation.new(
        display_name: "Cupertino, CA",
        latitude: 37.3229,
        longitude: -122.0322
      )
    end
    let(:points_result) do
      Weather::NwsPointsResult.new(
        forecast_url: "https://api.weather.gov/gridpoints/MTR/85,105/forecast"
      )
    end
    let(:forecast_result) do
      Weather::NwsForecastResult.new(
        current_temperature: 72,
        high_temperature: 78,
        low_temperature: 63,
        conditions: "Partly Cloudy"
      )
    end
    let(:nws_points_client) { class_double(Weather::NwsPointsClient, call: points_result) }
    let(:nws_forecast_client) { class_double(Weather::NwsForecastClient, call: forecast_result) }

    it "returns a forecast from the nws forecast result" do
      forecast = described_class.new(
        nws_points_client: nws_points_client,
        nws_forecast_client: nws_forecast_client
      ).call(resolved_location)

      expect(forecast.location).to eq("Cupertino, CA")
      expect(forecast.current_temperature).to eq(72)
      expect(forecast.high_temperature).to eq(78)
      expect(forecast.low_temperature).to eq(63)
      expect(forecast.conditions).to eq("Partly Cloudy")
      expect(forecast).not_to be_cached
    end

    it "calls the nws points client with the resolved location" do
      described_class.new(
        nws_points_client: nws_points_client,
        nws_forecast_client: nws_forecast_client
      ).call(resolved_location)

      expect(nws_points_client).to have_received(:call).with(resolved_location)
    end

    it "calls the nws forecast client with the returned forecast url" do
      described_class.new(
        nws_points_client: nws_points_client,
        nws_forecast_client: nws_forecast_client
      ).call(resolved_location)

      expect(nws_forecast_client).to have_received(:call).with(
        "https://api.weather.gov/gridpoints/MTR/85,105/forecast"
      )
    end

    it "lets nws points errors bubble up" do
      nws_points_client = class_double(Weather::NwsPointsClient)

      allow(nws_points_client).to receive(:call).and_raise(
        Weather::NwsPointsClient::Error,
        "nws points request failed"
      )

      expect do
        described_class.new(
          nws_points_client: nws_points_client,
          nws_forecast_client: nws_forecast_client
        ).call(resolved_location)
      end.to raise_error(Weather::NwsPointsClient::Error, "nws points request failed")
    end

    it "lets nws forecast errors bubble up" do
      nws_forecast_client = class_double(Weather::NwsForecastClient)

      allow(nws_forecast_client).to receive(:call).and_raise(
        Weather::NwsForecastClient::Error,
        "nws forecast request failed"
      )

      expect do
        described_class.new(
          nws_points_client: nws_points_client,
          nws_forecast_client: nws_forecast_client
        ).call(resolved_location)
      end.to raise_error(Weather::NwsForecastClient::Error, "nws forecast request failed")
    end
  end
end
