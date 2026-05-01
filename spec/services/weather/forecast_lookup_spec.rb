require "rails_helper"

RSpec.describe Weather::ForecastLookup do
  describe "#call" do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }
    let(:resolved_location) do
      Weather::ResolvedLocation.new(
        display_name: "Resolved Cupertino"
      )
    end
    let(:fresh_forecast) do
      Weather::Forecast.new(
        location: "Resolved Cupertino",
        current_temperature: 72,
        high_temperature: 78,
        low_temperature: 63,
        conditions: "Partly cloudy",
        cached: false
      )
    end
    let(:location_resolver) { class_double(Weather::LocationResolver, call: resolved_location) }
    let(:forecast_client) { class_double(Weather::ForecastClient, call: fresh_forecast) }

    it "returns a forecast from the forecast client" do
      forecast = described_class.new(
        cache: cache,
        location_resolver: location_resolver,
        forecast_client: forecast_client
      ).call("95014")

      expect(forecast.location).to eq("Resolved Cupertino")
      expect(forecast.current_temperature).to eq(72)
      expect(forecast.conditions).to eq("Partly cloudy")
      expect(forecast_client).to have_received(:call).with(resolved_location)
    end

    it "returns the first lookup without a cached flag" do
      forecast = described_class.new(
        cache: cache,
        location_resolver: location_resolver,
        forecast_client: forecast_client
      ).call("95014")

      expect(forecast).not_to be_cached
    end

    it "returns the second lookup for the same cache key with a cached flag" do
      lookup = described_class.new(
        cache: cache,
        location_resolver: location_resolver,
        forecast_client: forecast_client
      )

      lookup.call("95014")
      forecast = lookup.call("95014")

      expect(forecast).to be_cached
      expect(location_resolver).to have_received(:call).once
      expect(forecast_client).to have_received(:call).once
    end

    it "does not resolve the location or call the forecast client on a submitted zip cache hit" do
      cache.write("forecast:v1:zip:95014", fresh_forecast)
      location_resolver = class_double(Weather::LocationResolver)
      forecast_client = class_double(Weather::ForecastClient)

      expect(location_resolver).not_to receive(:call)
      expect(forecast_client).not_to receive(:call)

      forecast = described_class.new(
        cache: cache,
        location_resolver: location_resolver,
        forecast_client: forecast_client
      ).call("95014")

      expect(forecast).to be_cached
    end

    it "writes the forecast using the versioned submitted zip cache key" do
      described_class.new(
        cache: cache,
        location_resolver: location_resolver,
        forecast_client: forecast_client
      ).call("95014")

      expect(cache.read("forecast:v1:zip:95014").location).to eq("Resolved Cupertino")
    end

    it "does not read the previous unversioned cache key" do
      cache.write(
        "forecast:zip:95014",
        Weather::Forecast.new(location: "Old cached Cupertino", cached: false)
      )

      forecast = described_class.new(
        cache: cache,
        location_resolver: location_resolver,
        forecast_client: forecast_client
      ).call("95014")

      expect(forecast).not_to be_cached
      expect(forecast.location).to eq("Resolved Cupertino")
      expect(forecast_client).to have_received(:call).once
    end

    it "does not cache lookups when the submitted query does not include a zip code" do
      resolved_location = Weather::ResolvedLocation.new(
        display_name: "Resolved Cupertino"
      )
      cache = instance_spy(ActiveSupport::Cache::MemoryStore)
      location_resolver = class_double(Weather::LocationResolver, call: resolved_location)

      forecast = described_class.new(
        cache: cache,
        location_resolver: location_resolver,
        forecast_client: forecast_client
      ).call("Cupertino, CA")

      expect(forecast).not_to be_cached
      expect(cache).not_to have_received(:read)
      expect(cache).not_to have_received(:write)
    end
  end
end
