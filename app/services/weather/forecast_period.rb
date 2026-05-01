module Weather
  ForecastPeriod = Struct.new(
    :name,
    :temperature,
    :conditions,
    keyword_init: true
  )
end
