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
  end
end
