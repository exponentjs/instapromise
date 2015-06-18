// Generated by CoffeeScript 1.9.3
(function() {
  var __doc__, createCallback, createWrapper, thenify;

  __doc__ = "\n\nBased on the `thenify` code here:\nhttps://github.com/thenables/thenify/blob/master/index.js\n";

  thenify = function($$___thenifyFunction___$$) {
    "Turns a Node-style async function into a Promise";
    if (typeof $$___thenifyFunction___$$ === 'function') {
      return eval(createWrapper($$___thenifyFunction___$$.name));
    } else {
      throw new Error("Can't thenify a non-function");
    }
  };

  createCallback = function(resolve, reject) {
    return function(err, result) {
      if (err != null) {
        return reject(err);
      } else {
        return resolve(result);
      }
    };
  };

  createWrapper = function(name) {
    return "(function " + (name != null ? name : '') + "() {\n  var self = this;\n  var len = arguments.length;\n  var args = new Array(len + 1);\n  for (var i = 0; i < len; ++i) {\n    args[i] = arguments[i];\n  }\n  var lastIndex = i;\n  return new Promise(function (resolve, reject) {\n    args[lastIndex] = createCallback(resolve, reject);\n    $$___thenifyFunction___$$.apply(self, args);\n  });\n});";
  };

  module.exports = thenify;

}).call(this);
