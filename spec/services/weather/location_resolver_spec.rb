require "rails_helper"

RSpec.describe Weather::LocationResolver do
  describe "#call" do
    it "returns a resolved location for a cleaned location query" do
      location_query = Weather::LocationQuery.new("  Cupertino,   CA  ")

      resolved_location = described_class.new.call(location_query)

      expect(resolved_location.display_name).to eq("Cupertino, CA")
      expect(resolved_location.zip_code).to be_nil
      expect(resolved_location.latitude).to eq(0.0)
      expect(resolved_location.longitude).to eq(0.0)
      expect(resolved_location.cache_key).to eq("forecast:location:cupertino-ca")
    end

    it "uses a zip code cache key when the query contains a zip code" do
      location_query = Weather::LocationQuery.new("6068 Saint Julian Dr. Sanford FL 32771")

      resolved_location = described_class.new.call(location_query)

      expect(resolved_location.display_name).to eq("6068 Saint Julian Dr. Sanford FL 32771")
      expect(resolved_location.zip_code).to eq("32771")
      expect(resolved_location.cache_key).to eq("forecast:zip:32771")
    end
  end
end
