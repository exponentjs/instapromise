__doc__ = """
If you use this library then if you put `.promise` after a Node-style async
function, it will turn it into a function that returns a Promise instead of
taking a callback.

Ex.
  promisify = require 'instapromise'
  p = fs.readFile.promise "/tmp/hello", 'utf8'
  p.then(console.log)

If you want to promisify methods, use `.promise` after the object and before
the method name.

Ex.
  promisify = require 'instapromise'
  p = fs.promise.readFile "/tmp/hello", 'utf8'
  p.then(console.log)

This code is based on the proxying code used in fibrous.
https://github.com/goodeggs/fibrous/blob/master/src/fibrous.coffee

"""

##{ promisify } = require 'bluebird'
#promisify = require 'es6-promisify'
promisify = require './thenify'

asyncArrayReturn = (nodeStyleAsyncFunction) ->
  """Transforms a Node-style async function that has multiple passed values
    (ex. (err, result, result2, result3)) into one that only has err and then
    an Array of those values (ex. (err, [result, result2, result3])) to
    conform to the (err, result) convention"""

  (args..., callback) ->
    args.push (err, cbArgs...) ->
      callback? err, cbArgs
    nodeStyleAsyncFunction.apply @, args

promisifyArray = (nodeStyleAsyncFunction) ->
  promisify asyncArrayReturn nodeStyleAsyncFunction

module.exports = promisify

proxyAll = (src, target, proxyFn) ->
  for key in Object.keys(src) # Gives back the keys on this object, not on prototypes
    do (key) ->
      return if Object::[key]? # Ignore any rewrites of toString, etc which can cause problems
      return if Object.getOwnPropertyDescriptor(src, key).get? # getter methods can have unintentional side effects when called in the wrong context
      return unless typeof src[key] is 'function' # getter methods may throw an exception in some contexts

      target[key] = proxyFn(key)

  target

proxyBuilder = (prop) ->
  (that) ->
    result =
      if typeof(that) is 'function'
        func = switch prop
          when 'promise' then promisify that
          when 'promiseArray' then promisifyArray that
          else throw new Error "Unknown proxy property `#{ prop }`"
        func.__proto__ = Object.getPrototypeOf(that)[prop] if Object.getPrototypeOf(that) isnt Function.prototype
        func
      else
        Object.create(Object.getPrototypeOf(that) and Object.getPrototypeOf(that)[prop] or Object::)

    result.that = that

    proxyAll that, result, (key) ->
      (args...) ->
          # Relookup the method every time to pick up reassignments of key on obj or an instance
          @that[key][prop].apply(@that, args)


defineMemoizedPerInstanceProperty = (target, propertyName, factory) ->
  cacheKey = "__instapromise#{propertyName}__"
  Object.defineProperty target, propertyName,
    enumerable: false
    set: (value) ->
      delete @[cacheKey]
      Object.defineProperty @, propertyName, value: value, writable:true, configurable: true, enumerable: true # allow overriding the property turning back to default behavior
    get: ->
      unless Object::hasOwnProperty.call(@, cacheKey) and @[cacheKey]
        Object.defineProperty @, cacheKey, value: factory(@), writable: true, configurable: true, enumerable: false # ensure the cached version is not enumerable
      @[cacheKey]

# Mixin sync and future to Object and Function
for base in [Object::, Function::]
  for prop in ['promise', 'promiseArray']
    defineMemoizedPerInstanceProperty(base, prop, proxyBuilder prop)
