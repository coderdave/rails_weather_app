/** @format */

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "button",
    "buttonText",
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
    this.resultTarget.hidden = true;
    this.validate();
  }

  validate() {
    this.buttonTarget.disabled = !this.hasEnoughCharacters();
  }

  submit(event) {
    // the same guard handles button clicks and Enter presses, so disabled UI
    // controls cannot be bypassed by keyboard submission
    event.preventDefault();
    if (!this.hasEnoughCharacters()) return;

    this.performMockSearch();
  }

  performMockSearch() {
    // the real lookup is still server-rendered later, this gives immediate
    // feedback and proves the search interaction before connecting services
    this.buttonTarget.disabled = true;
    this.buttonTarget.classList.add("is-loading");
    this.buttonTextTarget.textContent = "Searching";
    this.spinnerTarget.hidden = false;
    this.statusTarget.textContent = "Searching...";
    this.resultTarget.hidden = true;

    window.setTimeout(() => {
      this.buttonTarget.disabled = false;
      this.buttonTarget.classList.remove("is-loading");
      this.buttonTextTarget.textContent = "Search";
      this.spinnerTarget.hidden = true;
      this.statusTarget.textContent = "";
      this.resultTarget.hidden = false;
      this.validate();
    }, 500);
  }

  hasEnoughCharacters() {
    return this.inputTarget.value.trim().length >= this.minimumLengthValue;
  }
}
