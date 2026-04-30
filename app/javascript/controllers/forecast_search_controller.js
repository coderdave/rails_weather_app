/** @format */

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "forecastResult",
    "loadingSpinner",
    "loadingStatus",
    "locationInput",
    "searchButton",
    "searchButtonText",
    "searchForm",
  ];
  static values = { minimumLength: Number };

  connect() {
    this.validate();
  }

  handleInput() {
    if (this.hasForecastResultTarget) this.forecastResultTarget.hidden = true;
    this.validate();
  }

  validate() {
    this.searchButtonTarget.disabled = !this.hasEnoughCharacters();
  }

  submit(event) {
    // the same guard handles button clicks and enter presses, so disabled UI
    // controls cannot be bypassed by keyboard submission
    event.preventDefault();

    if (!this.hasEnoughCharacters()) {
      return;
    }

    this.showLoading();
    this.searchFormTarget.submit();
  }

  showLoading() {
    // the server now renders the forecast, this only shows feedback while the GET request is in flight
    this.searchButtonTarget.disabled = true;
    this.searchButtonTarget.classList.add("is-loading");
    this.searchButtonTextTarget.textContent = "Searching";
    this.loadingSpinnerTarget.hidden = false;
    this.loadingStatusTarget.textContent = "Searching...";
    if (this.hasForecastResultTarget) this.forecastResultTarget.hidden = true;
  }

  hasEnoughCharacters() {
    return (
      this.locationInputTarget.value.trim().length >= this.minimumLengthValue
    );
  }
}
