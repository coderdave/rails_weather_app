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
      expect(response.body).to include("Here's your forecast...")
      expect(response.body).to include("hidden")
    end

    it "renders a form wired for validated mock searches" do
      get root_path

      expect(response.body).to include('action="/"')
      expect(response.body).to include('method="get"')
      expect(response.body).to include('name="location"')
      expect(response.body).to include('type="search"')
      expect(response.body).to include('data-search-form-minimum-length-value="5"')
      expect(response.body).to include('input-&gt;search-form#handleInput')
      expect(response.body).to include('submit-&gt;search-form#submit')
      expect(response.body).to include('keydown.enter-&gt;search-form#submit')
    end

    it "preserves a location query when one is present" do
      get root_path, params: { location: "Cupertino, CA" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Cupertino, CA"')
      expect(response.body).not_to include('class="search-button" disabled="disabled"')
    end

    it "keeps the search button disabled when the location query is too short" do
      get root_path, params: { location: "1234" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="1234"')
      expect(response.body).to include('class="search-button" disabled="disabled"')
    end
  end
end
