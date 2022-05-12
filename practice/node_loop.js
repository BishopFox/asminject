/* partly based on https://stackoverflow.com/questions/14249506/how-can-i-wait-in-node-js-javascript-l-need-to-pause-for-a-period-of-time */

const util = require('util');

if (!Date.prototype.toISOString) {
  (function() {

    function pad(number) {
      var r = String(number);
      if (r.length === 1) {
        r = '0' + r;
      }
      return r;
    }

    Date.prototype.toISOString = function() {
      return this.getUTCFullYear() +
        '-' + pad(this.getUTCMonth() + 1) +
        '-' + pad(this.getUTCDate()) +
        'T' + pad(this.getUTCHours()) +
        ':' + pad(this.getUTCMinutes()) +
        ':' + pad(this.getUTCSeconds()) +
        '.' + String((this.getUTCMilliseconds() / 1000).toFixed(3)).slice(2, 5) +
        'Z';
    };

  }());
}

for (let i = 0; i < 1000000; i++)
{
	let ts = new Date();
	console.log(util.format('%s - Loop count %i', ts.toISOString(), i));
	let waitTill = new Date(new Date().getTime() + 5000);
	while(waitTill > new Date()){}
}


