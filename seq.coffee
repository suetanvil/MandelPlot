# MandelPlot, Copyright (C) 2012 Chris Reuter, GPLv2, No Warranty

##
#
# Traversable Collections:
#
# This file provides collections which may be enumerated in a subset
# of the usual ways.  The enumeration itself is done in chunks,
# allowing the caller to do other things while the work is being done.
#
# Typically, you call a collection's enumeration method with the
# function(s) to apply and it returns an instance of ResumableAction.
# You call its 'resume()' method from an outer loop that also does
# other things until 'isDone()' returns true.  At this point, the
# resulting value is stored in the fields 'result'.
#
# Alternately, you can call the method 'timerLoop()' to perform the
# processing in the background via the event loop.  (Note that this is
# still single-threaded.)
#
##


# Represents an action being performed on the elements of a Collection
# (i.e. subclass of AbstractResumableCollection).  Each call to
# 'resume()' processes more of the entries.
class ResumableAction

  # The results of the action, if required
  result: []

  # Methods defined in the constructor:
  #
  # isDone()
  # restart()
  # resume(count = 1000)
  # finish()
  constructor: (collection, completionHook, action) ->
    index = 0
    currentCompletionHook = completionHook

    finishEarly = () -> index = collection.size()

    # Test if the action is finished
    @isDone = -> index >= collection.size()

    # Restart the action from scratch
    @restart = ->
      index = 0;
      result = []
      currentCompletionHook = completionHook

    # Perform the action for 'count' iterations
    @resume = (count = 1000) ->
      if @isDone() then return
      for n in [1..count]
        action(collection.at(index), @result, finishEarly)
        ++index
        if (@isDone())
          if currentCompletionHook?
            currentCompletionHook(this)
            currentCompletionHook = undefined
          return

    # Run the action to completion
    @finish = -> @resume(collection.size())

  # Sets a timer event to continue performing this action, then
  # returns.  Each timer event handler will set a new event handler if
  # there is still work to do.  In the meantime, the JavaScript system
  # can process other events.  'count' is the number of iterations per
  # event, 'delay' is the number of milliseconds the interpreter
  # should wait before launching the event handler.
  timerLoop: (count = 1000, delay = 1) ->
    @cancelTimerLoop()

    quitNow = false
    loopFn = () =>
      if quitNow then return
      @resume(count)
      if @isDone() then return
      setTimeout(loopFn, delay)

    setTimeout(loopFn, delay)

    # Cancel this timer loop.
    @cancelTimerLoop = -> quitNow = true

  # Cancel the timer loop if present.  Redefined by timerLoop()
  cancelTimerLoop: -> true

  # Test if the action is not complete
  notDone: -> !@isDone()


# Basic class representing array-like things (but not actual arrays)
# that can have functions applied to them elementwise.  The interface
# is somewhat different from JavaScript arrays because there is no way
# to implement the '[]' operator.  We use 'at' instead.
class AbstractResumableCollection

  # Return the value at 'index'.  Subclasses must override.
  at: (index) -> throw "'at' not implemented."

  # Return the number of elements.  Subclasses must override.
  size: () -> -1

  # Return a PermutationCollection wrapping this and 'otherCollection'
  permutedWith: (otherCollection) ->
    new PermutationCollection(this, otherCollection)

  # Basic enumerations.  Each one returns a ResumableAction that
  # performs the described enumeration.  The result, if any, is
  # stored in this object.  If completionHook is a function, it is
  # called once the action finishes with the ResumableAction object
  # as its argument.

  # Call 'callback' on each element, first to last, ignoring the result.
  forEach: (callback, completionHook = undefined) ->
    wrapper = (item, result, exit) -> callback(item)
    return new ResumableAction(this, completionHook, wrapper)

  # Call 'callback' on each element, first to last, and store the
  # resulting values in the 'result' field.
  map: (callback, completionHook = undefined) ->
    wrapper = (item, result, exit) -> result.push(callback(item))
    return new ResumableAction(this, completionHook, wrapper)

  # Call 'callback' on each element, first to last, and store the
  # element in the 'result' field if and only if the result of
  # 'callback' is true.
  filter: (callback, completionHook = undefined) ->
    wrapper = (item, result, exit) -> result.push(item) if callback(item)
    return new ResumableAction(this, completionHook, wrapper)

  # Sets the first element of 'result' to true if 'callback' answers
  # true for every element.  Sets it to false otherwise.
  every: (callback, completionHook = undefined) ->
    foundException = false
    result = true
    wrapper = (item, result, exit) ->
      foundException = !callback(item)
      if foundException
        result.push(false)
        exit()

    exitWrapper = (result) ->
      if !foundException
        result.push(true)
      completionHook(result) if completionHook?

    return new ResumableAction(this, exitWrapper, wrapper)

  # Sets the first element in 'result' to true if 'callback' returns
  # true for at least one element; sets 'false' otherwise.
  some: (callback, completionHook = undefined) ->
    @every ((elem) -> !callback(elem)), completionHook



# Class that mimics an array of integers in increasing or decreasing
# order, suitable for enumeration.
class Range extends AbstractResumableCollection

  # Constructor:
  #
  # start       -- First element of the range
  # end         -- Last element of the range
  # incr        -- Increment value to count by
  #
  # Methods defined:
  # at
  # size
  constructor: (start, end, incr = 1) ->
    throw "Zero increment value for Range" if incr == 0

    length = ((end - start) / incr) + 1
    length = Math.abs(Math.round(length))
    @size = -> length

    @at = (index) ->
      return undefined if index >= length || index < 0
      return start + (index * incr)


# Create and return a Range object.  Here so you don't need to type
# 'new'.
range = (start, end, incr = 1) -> new Range(start, end, incr)


# Class which, when instantiated with two other
# AbstractResumableCollection-derived classes, mimics an array
# containing all possible combinations of all of the elements in both
# of the lists.
class PermutationCollection extends AbstractResumableCollection

  # Constructor:
  #
  # first       -- The first collection
  # second      -- The second collection
  #
  # Methods defined:
  # at
  # size
  constructor: (first, second) ->

    length = first.size() * second.size()
    @size = -> length

    @at = (index) ->
      throw "Index #{index} is out of bounds." if index >= length
      li = index % first.size()
      ri = Math.floor(index / first.size())
      return [ first.at(li), second.at(ri) ]


# Class which wraps Javascript array-like objects and provides at()
# and size() methods.
class ArrayCollection extends AbstractResumableCollection

  # Constructor:
  #
  # array       -- The JavaScript array to wrap.
  #
  # Method defined:
  # at
  # size
  constructor: (array) ->
    @size = -> array.length
    @at   = (index) -> array[index]

# Create and return an ArrayCollection wrapped around the argument.
# Saves typing 'new'.
wrap = (array) -> new ArrayCollection(array)
