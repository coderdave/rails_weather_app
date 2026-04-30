/** @format */

import { Application } from "@hotwired/stimulus";

const application = Application.start();

// configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };
