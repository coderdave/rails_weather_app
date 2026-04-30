require "rails_helper"

RSpec.describe Weather::ForecastClient do
  describe "#call" do
    it "returns a fake forecast for the resolved location" do
      resolved_location = Weather::ResolvedLocation.new(display_name: "Cupertino, CA")

      forecast = described_class.new.call(resolved_location)

      expect(forecast.location).to eq("Cupertino, CA")
      expect(forecast.current_temperature).to eq(72)
      expect(forecast.high_temperature).to eq(78)
      expect(forecast.low_temperature).to eq(63)
      expect(forecast.conditions).to eq("Partly cloudy")
      expect(forecast).not_to be_cached
    end
  end
end
