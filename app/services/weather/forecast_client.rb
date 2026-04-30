module Weather
  class ForecastClient
    def self.call(resolved_location)
      new.call(resolved_location)
    end

    def call(resolved_location)
      # this fake response lets the real weather API replace only this client later
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
