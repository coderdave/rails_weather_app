module Weather
  class ForecastLookup
    def self.call(location)
      new.call(location)
    end

    def call(location)
      # this fake response lets the controller and view integrate with a stable backend boundary
      Forecast.new(
        location: location,
        current_temperature: 72,
        high_temperature: 78,
        low_temperature: 63,
        conditions: "Partly cloudy",
        cached: false
      )
    end
  end
end
