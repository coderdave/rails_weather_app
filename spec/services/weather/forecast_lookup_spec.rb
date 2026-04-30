require "rails_helper"

RSpec.describe Weather::ForecastLookup do
  describe "#call" do
    it "returns a fake forecast for the requested location" do
      forecast = described_class.new.call("Cupertino, CA")

      expect(forecast.location).to eq("Cupertino, CA")
      expect(forecast.current_temperature).to eq(72)
      expect(forecast.high_temperature).to eq(78)
      expect(forecast.low_temperature).to eq(63)
      expect(forecast.conditions).to eq("Partly cloudy")
      expect(forecast).not_to be_cached
    end

    it "uses the resolved display name in the fake response" do
      resolved_location = Weather::ResolvedLocation.new(display_name: "Resolved Cupertino")

      allow(Weather::LocationResolver).to receive(:call).and_return(resolved_location)

      forecast = described_class.new.call("Cupertino, CA")

      expect(forecast.location).to eq("Resolved Cupertino")
    end
  end
end
