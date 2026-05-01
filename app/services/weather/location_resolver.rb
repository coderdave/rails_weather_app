module Weather
  # Converts a normalized location query into displayable coordinates through the geocoder boundary.
  class LocationResolver
    def self.call(location_query)
      new.call(location_query)
    end

    def initialize(geocoding_client: GeocodingClient)
      @geocoding_client = geocoding_client
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)
      geocoding_result = geocoding_client.call(location_query)

      ResolvedLocation.new(
        display_name: geocoding_result.display_name,
        latitude: geocoding_result.latitude,
        longitude: geocoding_result.longitude
      )
    end

    private

    attr_reader :geocoding_client
  end
end
