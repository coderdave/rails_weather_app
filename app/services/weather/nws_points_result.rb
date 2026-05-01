module Weather
  # NWS grid-point metadata used to fetch daily and hourly forecasts
  NwsPointsResult = Struct.new(
    :forecast_url,
    :forecast_hourly_url,
    :city,
    :state,
    :time_zone,
    keyword_init: true
  )
end
