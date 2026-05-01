require "json"
require "net/http"

module Weather
  class NwsForecastClient
    # nws forecast urls come from the points endpoint, so this client follows that api-provided link
    EXTENDED_PERIOD_LIMIT = 4
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
      response = fetch_response(URI(forecast_url))

      raise Error, "nws forecast request failed" unless response.code.to_i == 200

      build_result(response.body)
    rescue URI::InvalidURIError
      raise Error, "nws forecast url is invalid"
    end

    private

    attr_reader :http_client

    def fetch_response(uri)
      http_client.get_response(uri, REQUEST_HEADERS)
    rescue StandardError
      raise Error, "nws forecast request failed"
    end

    def build_result(response_body)
      periods = JSON.parse(response_body).fetch("properties").fetch("periods")
      raise Error, "nws forecast response could not be parsed" unless periods.is_a?(Array) && periods.any?

      current_period = periods.first
      high_period = periods.find { |period| period["isDaytime"] == true } || current_period
      low_period = periods.find { |period| period["isDaytime"] == false } || current_period

      NwsForecastResult.new(
        # the first period is the nearest forecast period for the requested endpoint
        current_temperature: temperature_for(current_period),
        high_temperature: temperature_for(high_period),
        low_temperature: temperature_for(low_period),
        conditions: current_period.fetch("shortForecast"),
        extended_periods: extended_periods_from(periods)
      )
    rescue JSON::ParserError, KeyError, TypeError, ArgumentError, NoMethodError
      raise Error, "nws forecast response could not be parsed"
    end

    def temperature_for(period)
      Integer(period.fetch("temperature"))
    end

    def extended_periods_from(periods)
      periods.drop(1).first(EXTENDED_PERIOD_LIMIT).map do |period|
        ForecastPeriod.new(
          name: period.fetch("name"),
          temperature: temperature_for(period),
          conditions: period.fetch("shortForecast")
        )
      end
    end
  end
end
