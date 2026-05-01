module Weather
  # Final forecast data rendered by the UI
  Forecast = Struct.new(
    :location,
    :current_temperature,
    :high_temperature,
    :low_temperature,
    :conditions,
    :extended_periods,
    :cached,
    keyword_init: true
  ) do
    def cached?
      !!cached
    end

    def extended_periods
      self[:extended_periods] || []
    end
  end
end
