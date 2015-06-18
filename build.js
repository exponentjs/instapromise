// Generated by CoffeeScript 1.9.3
(function() {
  var exec, fs;

  exec = require('child_process').exec;

  fs = require('fs');

  exec("coffee -c *.coffee", function(err, result) {
    return exec("coffee -e 'console.log(require(\".\").__doc__);'", function(err, result) {
      return fs.writeFileSync('./README.md', "# instapromise\nPromisify node style async functions by putting a `.promise` after them (or after the object for methods)\n\n" + result);
    });
  });

}).call(this);
