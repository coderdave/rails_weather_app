require "rails_helper"

RSpec.describe Weather::LocationResolver do
  describe "#call" do
    it "returns a resolved location from the geocoding result" do
      location_query = Weather::LocationQuery.new("  Cupertino,   CA  ")
      geocoding_client = class_double(
        Weather::GeocodingClient,
        call: Weather::GeocodingResult.new(
          display_name: "Cupertino, Santa Clara County, California, United States",
          latitude: 37.3229,
          longitude: -122.0322
        )
      )

      resolved_location = described_class.new(geocoding_client: geocoding_client).call(location_query)

      expect(resolved_location.display_name).to eq("Cupertino, Santa Clara County, California, United States")
      expect(resolved_location.latitude).to eq(37.3229)
      expect(resolved_location.longitude).to eq(-122.0322)
      expect(geocoding_client).to have_received(:call) do |received_query|
        expect(received_query.to_s).to eq("Cupertino, CA")
      end
    end
  end
end
