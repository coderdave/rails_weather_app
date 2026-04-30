module Weather
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
      zip_code = location_query.zip_code || geocoding_result.zip_code

      ResolvedLocation.new(
        display_name: geocoding_result.display_name,
        zip_code: zip_code,
        latitude: geocoding_result.latitude,
        longitude: geocoding_result.longitude,
        cache_key: cache_key_for(zip_code)
      )
    end

    private

    attr_reader :geocoding_client

    def cache_key_for(zip_code)
      return unless zip_code

      # user-provided or geocoded zip codes become the stable cache key for repeated searches
      "forecast:zip:#{zip_code}"
    end
  end
end
