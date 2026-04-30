module Weather
  class ForecastLookup
    def self.call(location_query)
      new.call(location_query)
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)
      resolved_location = LocationResolver.call(location_query)

      # this fake response lets the controller and view integrate with a stable backend boundary
      Forecast.new(
        location: resolved_location.display_name,
        current_temperature: 72,
        high_temperature: 78,
        low_temperature: 63,
        conditions: "Partly cloudy",
        cached: false
      )
    end
  end
end
