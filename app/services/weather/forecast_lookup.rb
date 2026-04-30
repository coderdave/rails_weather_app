module Weather
  class ForecastLookup
    # thirty minutes matches the assessment cache window for repeated searches
    CACHE_EXPIRATION = 30.minutes

    def self.call(location_query)
      new.call(location_query)
    end

    def initialize(cache: Rails.cache, location_resolver: LocationResolver, forecast_client: ForecastClient)
      @cache = cache
      @location_resolver = location_resolver
      @forecast_client = forecast_client
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)
      resolved_location = location_resolver.call(location_query)
      cache_key = resolved_location.cache_key

      if cache_key.present?
        cached_forecast = cache.read(cache_key)
        return mark_cached(cached_forecast) if cached_forecast
      end

      forecast = forecast_client.call(resolved_location)

      cache.write(cache_key, forecast, expires_in: CACHE_EXPIRATION) if cache_key.present?
      forecast
    end

    private

    attr_reader :cache, :location_resolver, :forecast_client

    # return a new forecast so the stored fresh value is not mutated after a cache hit
    def mark_cached(forecast)
      Forecast.new(**forecast.to_h.merge(cached: true))
    end
  end
end
