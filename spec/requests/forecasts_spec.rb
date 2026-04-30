require "rails_helper"

RSpec.describe "Forecast search", type: :request do
  describe "GET /" do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(cache)

      allow(Weather::LocationResolver).to receive(:call) do |location_query|
        normalized_query = Weather::LocationQuery.new(location_query)

        Weather::ResolvedLocation.new(
          display_name: normalized_query.to_s,
          zip_code: normalized_query.zip_code,
          latitude: 37.3229,
          longitude: -122.0322,
          cache_key: resolved_cache_key_for(normalized_query)
        )
      end

      allow(Weather::ForecastClient).to receive(:call) do |resolved_location|
        Weather::Forecast.new(
          location: resolved_location.display_name,
          current_temperature: 72,
          high_temperature: 78,
          low_temperature: 63,
          conditions: "Partly cloudy",
          cached: false
        )
      end
    end

    it "renders the mock search UI" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rails Weather App")
      expect(response.body).to include('placeholder="Search for a location"')
      expect(response.body).to include(">Search<")
      expect(response.body).to include("disabled")
      expect(response.body).not_to include("Here's your forecast...")
    end

    it "renders a form wired for validated searches" do
      get root_path

      expect(response.body).to include('action="/"')
      expect(response.body).to include('method="get"')
      expect(response.body).to include('name="location"')
      expect(response.body).to include('type="search"')
      expect(response.body).to include('data-forecast-search-minimum-length-value="3"')
      expect(response.body).to include('data-forecast-search-target="searchForm"')
      expect(response.body).to include('data-forecast-search-target="locationInput"')
      expect(response.body).to include('data-forecast-search-target="searchButton"')
      expect(response.body).to include('input-&gt;forecast-search#handleInput')
      expect(response.body).to include('submit-&gt;forecast-search#submit')
      expect(response.body).to include('keydown.enter-&gt;forecast-search#submit')
    end

    it "preserves a location query when one is present" do
      get root_path, params: { location: "Cupertino, CA" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Cupertino, CA"')
      expect(response.body).not_to include('class="search-button" disabled="disabled"')
    end

    it "renders the forecast returned by the lookup boundary" do
      get root_path, params: { location: "Cupertino, CA" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Here's your forecast...")
      expect(response.body).to include("Cupertino, CA")
      expect(response.body).to include("72&deg;F")
      expect(response.body).to include("78&deg;F")
      expect(response.body).to include("63&deg;F")
      expect(response.body).to include("Partly cloudy")
    end

    it "lets the api try a simple location name" do
      get root_path, params: { location: "Cupertino" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Here's your forecast...")
      expect(response.body).to include("Cupertino")
    end

    it "renders the forecast for a zip code search" do
      get root_path, params: { location: "95014" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Here's your forecast...")
      expect(response.body).to include("95014")
    end

    it "shows when a repeated search is loaded from cache" do
      get root_path, params: { location: "95014" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Loaded from cache")

      get root_path, params: { location: "95014" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Loaded from cache")
      expect(Weather::ForecastClient).to have_received(:call).once
    end

    it "does not cache repeated searches without a zip code" do
      get root_path, params: { location: "Cupertino" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Loaded from cache")

      get root_path, params: { location: "Cupertino" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Loaded from cache")
      expect(Weather::ForecastClient).to have_received(:call).twice
    end

    it "renders the forecast for a full address without commas" do
      get root_path, params: { location: "123 Main St. Exampleville FL 32771" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Here's your forecast...")
      expect(response.body).to include("123 Main St. Exampleville FL 32771")
    end

    it "shows a validation error for a blank location" do
      expect(Weather::ForecastLookup).not_to receive(:call)

      get root_path, params: { location: "   " }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Enter a location")
      expect(response.body).not_to include("Here's your forecast...")
    end

    it "shows a validation error for a location that is too long" do
      expect(Weather::ForecastLookup).not_to receive(:call)

      get root_path, params: { location: "a" * 256 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Location is too long")
      expect(response.body).not_to include("Here's your forecast...")
    end

    it "shows a validation error for unsupported characters" do
      expect(Weather::ForecastLookup).not_to receive(:call)

      get root_path, params: { location: "Cupertino | CA" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Location contains unsupported characters")
      expect(response.body).not_to include("Here's your forecast...")
    end

    it "shows a validation error when a recognized location cannot be geocoded" do
      allow(Weather::ForecastLookup).to receive(:call).and_raise(Weather::GeocodingClient::LocationNotFound)

      get root_path, params: { location: "Missing, CA" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("We couldn&#39;t find a forecast for that location.")
      expect(response.body).not_to include("Here's your forecast...")
    end

    it "shows a service error when weather data cannot be loaded" do
      allow(Weather::ForecastLookup).to receive(:call).and_raise(Weather::NwsPointsClient::Error)

      get root_path, params: { location: "32771" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Weather data is temporarily unavailable.")
      expect(response.body).not_to include("Here's your forecast...")
    end

    it "keeps the search button disabled when the location query is too short" do
      expect(Weather::ForecastLookup).not_to receive(:call)

      get root_path, params: { location: "NY" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="NY"')
      expect(response.body).to include("Enter a more specific location")
      expect(response.body).to include('class="search-button" disabled="disabled"')
    end

    def resolved_cache_key_for(location_query)
      if location_query.zip_code
        "forecast:zip:#{location_query.zip_code}"
      end
    end
  end
end
