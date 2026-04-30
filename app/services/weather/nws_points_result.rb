module Weather
  NwsPointsResult = Struct.new(
    :forecast_url,
    :city,
    :state,
    :time_zone,
    keyword_init: true
  )
end
