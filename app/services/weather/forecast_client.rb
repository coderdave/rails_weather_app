module Weather
  class ForecastClient
    def self.call(resolved_location)
      new.call(resolved_location)
    end

    def initialize(nws_points_client: NwsPointsClient, nws_forecast_client: NwsForecastClient)
      @nws_points_client = nws_points_client
      @nws_forecast_client = nws_forecast_client
    end

    def call(resolved_location)
      points_result = nws_points_client.call(resolved_location)
      daily_forecast = nws_forecast_client.call(points_result.forecast_url)
      hourly_forecast = nws_forecast_client.call(points_result.forecast_hourly_url)

      Forecast.new(
        location: resolved_location.display_name,
        current_temperature: hourly_forecast.current_temperature,
        high_temperature: daily_forecast.high_temperature,
        low_temperature: daily_forecast.low_temperature,
        conditions: hourly_forecast.conditions,
        cached: false
      )
    end

    private

    attr_reader :nws_points_client, :nws_forecast_client
  end
end
