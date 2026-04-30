require "rails_helper"

RSpec.describe "Forecast search", type: :request do
  describe "GET /" do
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
      expect(response.body).to include('data-forecast-search-minimum-length-value="5"')
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

    it "renders the fake forecast returned by the lookup boundary" do
      get root_path, params: { location: "Cupertino, CA" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Here's your forecast...")
      expect(response.body).to include("Cupertino, CA")
      expect(response.body).to include("72&deg;F")
      expect(response.body).to include("78&deg;F")
      expect(response.body).to include("63&deg;F")
      expect(response.body).to include("Partly cloudy")
    end

    it "keeps the search button disabled when the location query is too short" do
      expect(Weather::ForecastLookup).not_to receive(:call)

      get root_path, params: { location: "1234" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="1234"')
      expect(response.body).to include('class="search-button" disabled="disabled"')
    end
  end
end
