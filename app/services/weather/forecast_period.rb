module Weather
  # One NWS forecast period shown in the extended forecast
  ForecastPeriod = Struct.new(
    :name,
    :temperature,
    :conditions,
    keyword_init: true
  )
end
