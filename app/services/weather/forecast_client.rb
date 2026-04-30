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
      forecast_result = nws_forecast_client.call(points_result.forecast_url)

      Forecast.new(
        location: resolved_location.display_name,
        current_temperature: forecast_result.current_temperature,
        high_temperature: forecast_result.high_temperature,
        low_temperature: forecast_result.low_temperature,
        conditions: forecast_result.conditions,
        cached: false
      )
    end

    private

    attr_reader :nws_points_client, :nws_forecast_client
  end
end
