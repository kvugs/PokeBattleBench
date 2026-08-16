'use strict';

/**
 * Local, disposable Pokémon Showdown configuration for PokeBattleBench.
 *
 * Showdown overlays these exports on its pinned config-example.js defaults.
 * Keep security-sensitive boundaries explicit here so an upstream revision
 * update cannot silently change the local operating model.
 *
 * Tokenless identities are safe only while Compose publishes port 8000 on the
 * host loopback address. This configuration is not suitable for a public server.
 */

// Network contract shared with the Dockerfile, Compose, and health check.
exports.port = 8000;
exports.bindaddress = '0.0.0.0';

// Local traffic needs neither compression nor TLS termination. No reverse
// proxy exists, so forwarded client IP headers must not be trusted.
exports.wsdeflate = null;
exports.ssl = null;
exports.proxyip = false;
exports.lazysockets = false;

// A single MVP battle uses Showdown's supported in-process worker fallback.
// Revisit this only when measured concurrency or fault isolation requires it.
exports.subprocesses = 0;

// Allow tokenless local names while retaining throttles, IP checks, and the
// anti-impersonation name filter. The three negative names are easy to invert:
// false keeps each protection enabled.
exports.noguestsecurity = true;
exports.nothrottle = false;
exports.noipchecks = false;
exports.disablebasicnamefilter = false;

// Keep random teams free from Pokémon-of-the-Day injection. Force an inactivity
// deadline and disallow voluntary draws so orchestration reaches a clear result.
exports.potd = '';
exports.forcetimer = true;
exports.allowrequestingties = false;

// The container supervisor owns recovery and configuration changes. Disable
// privileged runtime paths that can evaluate or reload code inside the server.
exports.crashguard = false;
exports.backdoor = false;
exports.consoleips = [];
exports.repl = false;
exports.watchconfig = false;
exports.disablehotpatchall = true;

// Keep each run disposable. Showdown's filesystem abstraction performs no
// writes, and log-search features stay disabled because no logs should exist.
exports.nofswriting = true;
exports.logchat = false;
exports.logchallenges = false;
exports.nobattlesearch = true;
