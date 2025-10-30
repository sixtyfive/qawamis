// ms@2.1.3 downloaded from https://ga.jspm.io/npm:ms@2.1.3/index.js

var e={};var s=1e3;var r=60*s;var a=60*r;var n=24*a;var t=7*n;var c=365.25*n;
/**
 * Parse or format the given `val`.
 *
 * Options:
 *
 *  - `long` verbose formatting [false]
 *
 * @param {String|Number} val
 * @param {Object} [options]
 * @throws {Error} throw an error if val is not a non-empty string or a number
 * @return {String|Number}
 * @api public
 */e=function(e,s){s=s||{};var r=typeof e;if("string"===r&&e.length>0)return parse(e);if("number"===r&&isFinite(e))return s.long?fmtLong(e):fmtShort(e);throw new Error("val is not a non-empty string or a valid number. val="+JSON.stringify(e))};
/**
 * Parse the given `str` and return milliseconds.
 *
 * @param {String} str
 * @return {Number}
 * @api private
 */function parse(e){e=String(e);if(!(e.length>100)){var u=/^(-?(?:\d+)?\.?\d+) *(milliseconds?|msecs?|ms|seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d|weeks?|w|years?|yrs?|y)?$/i.exec(e);if(u){var o=parseFloat(u[1]);var i=(u[2]||"ms").toLowerCase();switch(i){case"years":case"year":case"yrs":case"yr":case"y":return o*c;case"weeks":case"week":case"w":return o*t;case"days":case"day":case"d":return o*n;case"hours":case"hour":case"hrs":case"hr":case"h":return o*a;case"minutes":case"minute":case"mins":case"min":case"m":return o*r;case"seconds":case"second":case"secs":case"sec":case"s":return o*s;case"milliseconds":case"millisecond":case"msecs":case"msec":case"ms":return o;default:return}}}}
/**
 * Short format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 */function fmtShort(e){var t=Math.abs(e);return t>=n?Math.round(e/n)+"d":t>=a?Math.round(e/a)+"h":t>=r?Math.round(e/r)+"m":t>=s?Math.round(e/s)+"s":e+"ms"}
/**
 * Long format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 */function fmtLong(e){var t=Math.abs(e);return t>=n?plural(e,t,n,"day"):t>=a?plural(e,t,a,"hour"):t>=r?plural(e,t,r,"minute"):t>=s?plural(e,t,s,"second"):e+" ms"}function plural(e,s,r,a){var n=s>=1.5*r;return Math.round(e/r)+" "+a+(n?"s":"")}var u=e;export default u;

