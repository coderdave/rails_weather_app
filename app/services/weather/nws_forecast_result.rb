module Weather
  NwsForecastResult = Struct.new(
    :current_temperature,
    :high_temperature,
    :low_temperature,
    :conditions,
    :extended_periods,
    keyword_init: true
  ) do
    def extended_periods
      self[:extended_periods] || []
    end
  end
end
