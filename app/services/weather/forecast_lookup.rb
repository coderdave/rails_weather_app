module Weather
  class ForecastLookup
    # thirty minutes matches the assessment cache window for repeated searches
    CACHE_EXPIRATION = 30.minutes

    def self.call(location_query)
      new.call(location_query)
    end

    def initialize(cache: Rails.cache, location_resolver: LocationResolver)
      @cache = cache
      @location_resolver = location_resolver
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)
      resolved_location = location_resolver.call(location_query)

      cached_forecast = cache.read(resolved_location.cache_key)
      return mark_cached(cached_forecast) if cached_forecast

      # this fake response lets the controller and view integrate with a stable backend boundary
      forecast = Forecast.new(
        location: resolved_location.display_name,
        current_temperature: 72,
        high_temperature: 78,
        low_temperature: 63,
        conditions: "Partly cloudy",
        cached: false
      )

      cache.write(resolved_location.cache_key, forecast, expires_in: CACHE_EXPIRATION)
      forecast
    end

    private

    attr_reader :cache, :location_resolver

    # return a new forecast so the stored fresh value is not mutated after a cache hit
    def mark_cached(forecast)
      Forecast.new(**forecast.to_h.merge(cached: true))
    end
  end
end
