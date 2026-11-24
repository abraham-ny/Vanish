.pragma library

// ---- Edit these before building -------------------------------------------------
// Apps Script web-app URL (…/exec). Can also be changed at runtime in Settings > Backend.
var API_URL = "";

var APP_NAME = "Vanish";
var APP_VERSION = "0.1.0";
var DEV_NAME = "Abraham (Vitalsoft)";
var DEV_WEBSITE = "https://abrahamonline.netlify.app";
var DEV_GITHUB = "https://github.com/abraham-ny";
// TODO: point these at the real repo / feedback page / donation links.
var SOURCE_URL = "https://github.com/abraham-ny/vanish";
var FEEDBACK_URL = "https://abrahamonline.netlify.app";
var DONATE_LINKS = [
    { label: "Support on GitHub Sponsors", url: "https://github.com/sponsors/abraham-ny" },
    { label: "Visit developer website", url: "https://abrahamonline.netlify.app" }
];

// Master feedback chat (created by backend setup()).
var FEEDBACK_CODE = "FEEDBACK";
