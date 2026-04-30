class ForecastsController < ApplicationController
  MINIMUM_LOCATION_LENGTH = 5

  def index
    @location_query = params[:location].to_s.strip
    @minimum_location_length = MINIMUM_LOCATION_LENGTH
    # a 5-character guard keeps the mock UI aligned with the shortest valid
    # assessment input, a ZIP code, while deeper address validation remains in
    # the service layer when the real forecast lookup is connected
    @search_disabled = @location_query.length < @minimum_location_length
  end
end
