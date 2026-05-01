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
      expect(resolved_location.zip_code).to be_nil
      expect(resolved_location.latitude).to eq(37.3229)
      expect(resolved_location.longitude).to eq(-122.0322)
      expect(resolved_location.cache_key).to be_nil
      expect(geocoding_client).to have_received(:call) do |received_query|
        expect(received_query.to_s).to eq("Cupertino, CA")
      end
    end

    it "uses the user-provided zip code for the cache key when the query contains one" do
      location_query = Weather::LocationQuery.new("123 Main St. Exampleville FL 32771")
      geocoding_client = class_double(
        Weather::GeocodingClient,
        call: Weather::GeocodingResult.new(
          display_name: "123 Main Street, Exampleville, Florida, United States",
          zip_code: "32773",
          latitude: 28.7583,
          longitude: -81.3187
        )
      )

      resolved_location = described_class.new(geocoding_client: geocoding_client).call(location_query)

      expect(resolved_location.display_name).to eq("123 Main Street, Exampleville, Florida, United States")
      expect(resolved_location.zip_code).to eq("32771")
      expect(resolved_location.cache_key).to eq("forecast:zip:32771")
    end

    it "keeps a geocoded zip code without making the query cacheable" do
      location_query = Weather::LocationQuery.new("1 Apple Park Way, Cupertino, CA")
      geocoding_client = class_double(
        Weather::GeocodingClient,
        call: Weather::GeocodingResult.new(
          display_name: "Apple Park, Cupertino, California, United States",
          zip_code: "95014",
          latitude: 37.3346,
          longitude: -122.009
        )
      )

      resolved_location = described_class.new(geocoding_client: geocoding_client).call(location_query)

      expect(resolved_location.zip_code).to eq("95014")
      expect(resolved_location.cache_key).to be_nil
    end
  end
end
