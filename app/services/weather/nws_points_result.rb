module Weather
  NwsPointsResult = Struct.new(
    :forecast_url,
    :forecast_hourly_url,
    :city,
    :state,
    :time_zone,
    keyword_init: true
  )
end
