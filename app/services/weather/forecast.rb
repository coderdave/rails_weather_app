module Weather
  Forecast = Struct.new(
    :location,
    :current_temperature,
    :high_temperature,
    :low_temperature,
    :conditions,
    :cached,
    keyword_init: true
  ) do
    def cached?
      !!cached
    end
  end
end
