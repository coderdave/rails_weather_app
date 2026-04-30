require "rails_helper"

RSpec.describe Weather::ForecastLookup do
  describe "#call" do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }

    it "returns a fake forecast for the requested location" do
      forecast = described_class.new(cache: cache).call("Cupertino, CA")

      expect(forecast.location).to eq("Cupertino, CA")
      expect(forecast.current_temperature).to eq(72)
      expect(forecast.high_temperature).to eq(78)
      expect(forecast.low_temperature).to eq(63)
      expect(forecast.conditions).to eq("Partly cloudy")
      expect(forecast).not_to be_cached
    end

    it "uses the resolved display name in the fake response" do
      resolved_location = Weather::ResolvedLocation.new(
        display_name: "Resolved Cupertino",
        cache_key: "forecast:location:resolved-cupertino"
      )
      location_resolver = class_double(Weather::LocationResolver, call: resolved_location)

      forecast = described_class.new(cache: cache, location_resolver: location_resolver).call("Cupertino, CA")

      expect(forecast.location).to eq("Resolved Cupertino")
    end

    it "returns the first lookup without a cached flag" do
      forecast = described_class.new(cache: cache).call("95014")

      expect(forecast).not_to be_cached
    end

    it "returns the second lookup for the same cache key with a cached flag" do
      lookup = described_class.new(cache: cache)

      lookup.call("95014")
      forecast = lookup.call("95014")

      expect(forecast).to be_cached
    end

    it "writes the forecast using the resolved cache key" do
      resolved_location = Weather::ResolvedLocation.new(
        display_name: "Resolved Cupertino",
        cache_key: "forecast:zip:95014"
      )
      location_resolver = class_double(Weather::LocationResolver, call: resolved_location)

      described_class.new(cache: cache, location_resolver: location_resolver).call("95014")

      expect(cache.read("forecast:zip:95014").location).to eq("Resolved Cupertino")
    end
  end
end
