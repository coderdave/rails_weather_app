class ForecastsController < ApplicationController
  MINIMUM_LOCATION_LENGTH = 5

  def index
    @location_query = params[:location].to_s.strip
    @minimum_location_length = MINIMUM_LOCATION_LENGTH
    # five characters allows zip code searches while blocking empty or obviously incomplete submissions
    @search_disabled = @location_query.length < @minimum_location_length
    return if @search_disabled

    location_query = Weather::LocationQuery.new(@location_query)
    @location_query = location_query.to_s

    if location_query.recognized?
      @forecast = Weather::ForecastLookup.call(location_query)
    else
      @location_error = "Enter a ZIP code, city and state, or full street address."
    end
  rescue Weather::GeocodingClient::LocationNotFound
    @forecast = nil
    @location_error = "We couldn't find that location. Try a ZIP code, city and state, or full street address."
  rescue Weather::GeocodingClient::Error, Weather::NwsPointsClient::Error, Weather::NwsForecastClient::Error
    @forecast = nil
    @location_error = "Weather data is temporarily unavailable. Please try again."
  end
end
