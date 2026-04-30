require "json"
require "net/http"

module Weather
  class NwsForecastClient
    # nws forecast urls come from the points endpoint, so this client follows that api-provided link
    REQUEST_HEADERS = {
      "Accept" => "application/geo+json",
      "User-Agent" => "rails-weather-app coding-assessment"
    }.freeze

    class Error < StandardError; end

    def self.call(forecast_url)
      new.call(forecast_url)
    end

    def initialize(http_client: Net::HTTP)
      @http_client = http_client
    end

    def call(forecast_url)
      response = http_client.get_response(URI(forecast_url), REQUEST_HEADERS)

      raise Error, "nws forecast request failed" unless response.code.to_i == 200

      build_result(response.body)
    rescue URI::InvalidURIError
      raise Error, "nws forecast url is invalid"
    end

    private

    attr_reader :http_client

    def build_result(response_body)
      periods = JSON.parse(response_body).fetch("properties").fetch("periods")
      raise Error, "nws forecast response could not be parsed" unless periods.is_a?(Array) && periods.any?

      current_period = periods.first
      high_period = periods.find { |period| period["isDaytime"] == true } || current_period
      low_period = periods.find { |period| period["isDaytime"] == false } || current_period

      NwsForecastResult.new(
        # nws forecast periods are not current observations, so use the first period as the current app value for now
        current_temperature: temperature_for(current_period),
        high_temperature: temperature_for(high_period),
        low_temperature: temperature_for(low_period),
        conditions: current_period.fetch("shortForecast")
      )
    rescue JSON::ParserError, KeyError, TypeError, ArgumentError, NoMethodError
      raise Error, "nws forecast response could not be parsed"
    end

    def temperature_for(period)
      Integer(period.fetch("temperature"))
    end
  end
end
