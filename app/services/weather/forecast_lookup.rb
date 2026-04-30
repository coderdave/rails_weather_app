module Weather
  class ForecastLookup
    def self.call(location_query)
      new.call(location_query)
    end

    def call(location_query)
      location_query = LocationQuery.new(location_query)
      # this fake response lets the controller and view integrate with a stable backend boundary
      Forecast.new(
        location: location_query.to_s,
        current_temperature: 72,
        high_temperature: 78,
        low_temperature: 63,
        conditions: "Partly cloudy",
        cached: false
      )
    end
  end
end
