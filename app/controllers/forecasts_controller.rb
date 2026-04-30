class ForecastsController < ApplicationController
  def index
    @location_query = params[:location].to_s.strip
    @minimum_location_length = Weather::LocationQuery::MINIMUM_LENGTH
    @search_disabled = @location_query.length < @minimum_location_length
    return unless params.key?(:location)

    location_query = Weather::LocationQuery.new(@location_query)
    @location_query = location_query.to_s

    @location_error = location_query.validation_error
    return if @location_error

    @forecast = Weather::ForecastLookup.call(location_query)
  rescue Weather::GeocodingClient::LocationNotFound
    @forecast = nil
    @location_error = "We couldn't find a forecast for that location."
  rescue Weather::GeocodingClient::Error, Weather::NwsPointsClient::Error, Weather::NwsForecastClient::Error
    @forecast = nil
    @location_error = "Weather data is temporarily unavailable. Please try again."
  end
end
