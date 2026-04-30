module Weather
  class LocationResolver
    PLACEHOLDER_LATITUDE = 0.0
    PLACEHOLDER_LONGITUDE = 0.0

    def self.call(location_query)
      new.call(location_query)
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)

      ResolvedLocation.new(
        display_name: location_query.to_s,
        zip_code: location_query.zip_code,
        latitude: PLACEHOLDER_LATITUDE,
        longitude: PLACEHOLDER_LONGITUDE,
        cache_key: cache_key_for(location_query)
      )
    end

    private

    def cache_key_for(location_query)
      if location_query.zip_code
        "forecast:zip:#{location_query.zip_code}"
      else
        # city/state searches will later cache by a representative resolved location because no user-provided zip is available
        "forecast:location:#{location_query.to_s.parameterize}"
      end
    end
  end
end
