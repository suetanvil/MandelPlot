# MandelPlot, Copyright (C) 2012 Chris Reuter, GPLv2, No Warranty

# This class lets the user select a rectangle on the given canvas
# whose proportions match those of the canvas itself.  The top-left
# corner and width of the selection are publicly accessible.
class ZoomSelection

  # Top-left corner of the selection rectangle
  topleft: null

  # Width of the selection
  width: null

  # Test if there is currently a region selected
  hasSelection: -> @topleft? && @width? && @width > 0

  # Constructor. Adds event hooks to the canves ID'd by canvas_id.
  # Also defines:
  #
  # clearSelection()
  constructor: (canvas_id) ->
    canvas = $(canvas_id).get(0)
    ctx = canvas.getContext("2d")
    ratio = canvas.height/canvas.width

    # Clear the visible selection rectangle
    clearZoomRect = => ctx.clearRect(0, 0, canvas.width, canvas.height)

    # Clear the given selection
    @clearSelection = =>
      clearZoomRect()
      @topleft = null
      @width = null

    # Draw the selection rectangle
    drawRect = =>
      if !@width? || @width < 0 || !@topleft then return
      [x, y] = @topleft
      ctx.strokeStyle = '#FF0000'
      ctx.strokeRect(x, y, @width, @width*ratio)

    # Return the absolute position x, y relative to the canvas
    relPos = (x, y) =>
      oo = $(canvas).offset()
      return [x - oo.left, y - oo.top]

    # Test if event point x,y is inside the canvas
    isInRect = (x, y) =>
      [rx, ry] = relPos(x,y)
      if rx < 0 || ry < 0 || rx >= canvas.width || ry >= canvas.height
        return false
      return true

    # Set @width from the coordinates of evt
    setWidth = (evt) =>
      return unless @topleft?
      [x, y] = relPos(evt.pageX, evt.pageY)
      @width = x - @topleft[0]

    # Mousedown handler.  Sets topleft from evt, then binds the
    # mousemove handler which in turn draws the selection rectangle
    # and sets the width for each movement.  Does nothing unless the
    # mouse is inside the plotting canvas.
    $(document).mousedown (evt) =>
      if (!isInRect(evt.pageX, evt.pageY)) then return
      @topleft = relPos(evt.pageX, evt.pageY)
      @width = 0
      clearZoomRect()

      $(document).mousemove (evt) =>
        setWidth(evt)
        clearZoomRect()
        drawRect()

    # Mouseup handler.  Unbinds the mousemove handler and sets the
    # width if the event happened inside the plotting canvas.
    $(document).mouseup (evt) =>
      $(document).unbind('mousemove')
      if (!isInRect(evt.pageX, evt.pageY)) then return
      setWidth(evt)
      if !@hasSelection() then clearZoomRect()
