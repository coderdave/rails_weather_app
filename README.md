<!-- @format -->

# Rails Weather App

Rails Weather App is a small Rails application for looking up US weather forecasts by address, city/state, or ZIP code. It resolves a submitted location to coordinates, fetches forecast data from the National Weather Service, and displays the result in a simple web UI.

## Features

- Search by street address, city/state, or ZIP code
- Current hourly forecast temperature and conditions, plus daily high/low
- Extended forecast for the next four NWS forecast periods
- 30-minute forecast caching for submitted ZIP-code searches
- Visible cache-hit indicator when a forecast is served from cache
- User-friendly validation and external-service error handling
- Service-oriented weather lookup code with request and unit specs

## Requirements

- Ruby 3.4.9, as defined in `.ruby-version`
- Bundler
- Outbound HTTPS access to Nominatim and `api.weather.gov`

The app does not use a database. Active Record is not loaded, and no database setup step is required.

## Setup

Install dependencies:

```bash
bundle install
```

Run the test suite:

```bash
bundle exec rspec
```

Run the app locally:

```bash
bin/rails server
```

Then open `http://localhost:3000`.

## Caching Behavior

Forecasts are cached only when the submitted search includes a ZIP code. The cache key format is:

```text
forecast:zip:<zip_code>
```

For ZIP-code searches, the app checks the cache before resolving the location. A cache hit skips geocoding and weather API calls. A cache miss resolves the location, fetches the forecast, stores it for 30 minutes, and returns the fresh forecast.

Cached search examples:

- `95014`
- `Cupertino CA 95014`
- `1 Apple Park Way, Cupertino, CA 95014`

Uncached search examples:

- `Cupertino`
- `Cupertino, CA`
- `1 Apple Park Way, Cupertino, CA`

If the user does not submit a ZIP code, the forecast is not cached, even if geocoding resolves the address to a ZIP code.

Development uses an in-memory cache by default so the ZIP-code cache behavior is visible during local manual testing. This differs from the default Rails development setting, where caching is usually off to avoid stale data while editing code. The tradeoff is that repeated ZIP-code searches can return cached forecast data for up to 30 minutes.

Restart the Rails server or clear `Rails.cache` in the console to reset cached forecasts:

```ruby
Rails.cache.clear
```

To temporarily disable caching in development, change `config.cache_store` to `:null_store` in `config/environments/development.rb` and restart the server:

```ruby
config.action_controller.perform_caching = false
config.cache_store = :null_store
```

Restore the checked-in `:memory_store` settings when you want local cache-hit behavior again.

## External Services

The app uses two public services:

- Nominatim, OpenStreetMap's geocoding API, converts submitted US locations into latitude and longitude.
- National Weather Service API resolves coordinates to forecast endpoints and returns forecast periods.

No API keys are required. Requests are made through a shared HTTP client with explicit open, read, and write timeouts so upstream services cannot hang the Rails request indefinitely.

Optional environment variables:

- `WEATHER_USER_AGENT` sets the outbound `User-Agent` header. Defaults to `rails-weather-app`.
- `WEATHER_CONTACT` adds contact information to the default `User-Agent` and sends a `From` header. This is useful for identifying the app to public weather and geocoding services.
- `WEATHER_HTTP_OPEN_TIMEOUT_SECONDS` sets the connection timeout. Defaults to `5`.
- `WEATHER_HTTP_READ_TIMEOUT_SECONDS` sets the response read timeout. Defaults to `5`.
- `WEATHER_HTTP_WRITE_TIMEOUT_SECONDS` sets the request write timeout. Defaults to `5`.

## Architecture

The forecast flow is split into small service objects under `app/services/weather`.

```text
User input
  -> LocationQuery validates and normalizes the submitted search
  -> ForecastLookup checks the submitted ZIP cache key, when present
  -> LocationResolver geocodes the search into coordinates
  -> ForecastClient coordinates the NWS clients
  -> NwsPointsClient resolves coordinates to NWS daily and hourly forecast URLs
  -> NwsForecastClient parses daily and hourly forecast periods
  -> Forecast is rendered by ForecastsController
```

Primary objects:

- `Weather::LocationQuery` normalizes input, validates length and unsupported characters, and extracts submitted ZIP codes.
- `Weather::ForecastLookup` owns cache lookup/write behavior and coordinates the lookup flow.
- `Weather::LocationResolver` turns a valid query into a `ResolvedLocation`.
- `Weather::GeocodingClient` wraps Nominatim requests and response parsing.
- `Weather::ForecastClient` combines NWS points and forecast clients into one app-level forecast.
- `Weather::NwsPointsClient` fetches NWS metadata for resolved coordinates.
- `Weather::NwsForecastClient` fetches and parses forecast periods.
- `Weather::Forecast` is the final value object rendered by the UI.
- `Weather::ForecastPeriod` represents one item in the extended forecast.

## Project Structure

```text
app/
  controllers/
    forecasts_controller.rb
  javascript/controllers/
    forecast_search_controller.js
  services/weather/
    forecast_lookup.rb
    forecast_period.rb
    http_client.rb
    location_query.rb
    location_resolver.rb
    geocoding_client.rb
    forecast_client.rb
    nws_points_client.rb
    nws_forecast_client.rb
  views/forecasts/
    index.html.erb
spec/
  requests/
    forecasts_spec.rb
  services/weather/
```

## Quality Checks

Run the full verification set:

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman -q
bin/importmap audit
```

The GitHub Actions workflow runs security scans, dependency audit, RuboCop, and the RSpec suite.

## Production Notes

- The app is stateless and can run behind a standard Rails-compatible web server.
- The default Rails cache store is process-local. Use Redis or another shared cache store if running multiple application instances.
- External API latency and availability are handled with explicit HTTP timeouts and user-facing error messages. A production deployment should also add request instrumentation and rate limiting around upstream calls.
- NWS forecasts cover the United States. The geocoder is also restricted to US results.
