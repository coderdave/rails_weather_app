/** @format */

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "button",
    "buttonText",
    "form",
    "input",
    "spinner",
    "status",
    "result",
  ];
  static values = { minimumLength: Number };

  connect() {
    this.validate();
  }

  handleInput() {
    if (this.hasResultTarget) this.resultTarget.hidden = true;
    this.validate();
  }

  validate() {
    this.buttonTarget.disabled = !this.hasEnoughCharacters();
  }

  submit(event) {
    // the same guard handles button clicks and enter presses, so disabled UI
    // controls cannot be bypassed by keyboard submission
    event.preventDefault();

    if (!this.hasEnoughCharacters()) {
      return;
    }

    this.showLoading();
    this.formTarget.submit();
  }

  showLoading() {
    // the server now renders the forecast, this only shows feedback while the GET request is in flight
    this.buttonTarget.disabled = true;
    this.buttonTarget.classList.add("is-loading");
    this.buttonTextTarget.textContent = "Searching";
    this.spinnerTarget.hidden = false;
    this.statusTarget.textContent = "Searching...";
    if (this.hasResultTarget) this.resultTarget.hidden = true;
  }

  hasEnoughCharacters() {
    return this.inputTarget.value.trim().length >= this.minimumLengthValue;
  }
}
