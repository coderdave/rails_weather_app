module Weather
  NwsForecastResult = Struct.new(
    :current_temperature,
    :high_temperature,
    :low_temperature,
    :conditions,
    keyword_init: true
  )
end
