# MandelPlot, Copyright (C) 2012 Chris Reuter, GPLv2, No Warranty

# An instance of this class does the actual plotting.  It also holds
# on to the parameters to use (location, scale, iteration count) and
# manages the "background process" that does the actual plotting.
class PlotState

  # Top-left corner of the zone to render on the complex plane
  topLeft: null

  # The magnification.  Specifically, the width (and height) of the
  # area on the complex plane represented by one pixel.
  pixelSize: null

  # Number of iterations to attempt before assuming a value never converges.
  iter: 100

  # Number of pixels to compute per JavaScript timer event
  slice: 1000


  # Constructor.  Defines the following methods:
  #
  # reset()
  # startRender(doneFn = null)
  # isPlotting()
  # canvasExtent()
  constructor: (canvasId) ->
    renderState = undefined

    canvas = $(canvasId).get(0)
    ctx = canvas.getContext("2d")

    # Resets to default settings
    @reset = ->
      @topLeft = [-2.2, -1.1]
      @pixelSize = 2 * Math.abs(@topLeft[1]) / canvas.height

    @reset()

    # Render the plot according to the current set of parameters.  The
    # actual rendering is done in the background via class
    # ResumeableAction.  If 'doneFn' is given, it is called if and
    # when the render process completes.
    @startRender = (doneFn = null) ->
      renderState? && renderState.cancelTimerLoop()
      ctx.clearRect(0, 0, canvas.width, canvas.height)

      ps = @pixelSize
      ii = @iter
      [tx, ty] = @topLeft

      plotFn = (point) =>
        [x, y] = point

        fx = tx + x*ps
        fy = ty + y*ps

        ctx.fillStyle = @pixelColor(fx, fy, @iter)
        ctx.fillRect(x, y, 1, 1)

      rr = range(0, canvas.width-1).permutedWith(range(0,canvas.height-1))
      renderState = rr.forEach plotFn, doneFn
      renderState.timerLoop(@slice)

    # Test if plotting is in progress
    @isPlotting = -> renderState? && renderState.notDone()

    # Return the dimensions of the canvas
    @canvasExtent = -> [canvas.width, canvas.height]

  # Compute the color for the pixel at point (ptX, ptY) on the
  # complex plane.
  pixelColor: (ptX, ptY, iter) ->
    [x, y, xx, yy] = [0, 0, 0, 0]

    for count in [0 .. iter]
      if xx + yy >= 4
        return @colorFor(count, iter)

      xNew = xx - yy + ptX
      y = 2*x*y + ptY
      x = xNew

      xx = x*x
      yy = y*y

    return '#000000'

  # Give back a linear colour.  Colours are mapped from "cold" to
  # "hot" as described at
  # http://paulbourke.net/texture_colour/colourramp/
  colorFor: (count, maxCount) ->
    rgb = (r,g,b) ->
      rgb = [r,g,b].map (c) -> Math.round(0x100+c*0xFF).toString(16).slice(1,2)
      '#' + rgb.join("")

    range = count/maxCount
    if range <= 0.25
      return rgb(0, range/0.25, 1)
    else if range <= 0.5
      return rgb(0, 1, 1 - (range - 0.25)/0.25)
    else if range <= 0.75
      return rgb((range - 0.5)/0.25, 1, 0)
    else
      return rgb(1, 1 - (range - 0.75)/0.25, 0)

  # Return a textual description of the plot parameters
  desc: ->
    stats = [@topLeft[0], @topLeft[1]]
    stats = stats.map (x) -> Math.round(x * 1000000000) / 1000000000
    "(#{stats[0]}, #{stats[1]}), pixel size = #{@pixelSize}"

  # Return the URL of the current rendering parameters.  baseUrl must
  # be the URL of this page.
  link: (baseUrl) ->
    "#{baseUrl}##{@topLeft[0]},#{@topLeft[1]},#{@pixelSize},#{@iter}"

  # Zoom in or out (i.e. set the parameters to a new position zoomed
  # from the current position).  Zooms out if scale is > 1.0 and in if
  # 0 < scale < 1.0.
  zoom: (scale) ->
    [cw, ch] = @canvasExtent()
    newps = @pixelSize * scale
    scaleDiff = (newps - @pixelSize)/2

    @topLeft[0] -= cw * scaleDiff
    @topLeft[1] -= ch * scaleDiff
    @pixelSize = newps

  # Sets the render parameters to render a rectangle selected by the
  # user (we only need the top-left corner and width because the
  # selection rectangle will have the same proportions as the canvas.)
  # The selection is assumed to be a region inside the current
  # rendered region.
  setRenderRect: (x, y, width) ->
    @topLeft[0] += x*@pixelSize
    @topLeft[1] += y*@pixelSize

    [cw, ch] = @canvasExtent()
    @pixelSize *= width
    @pixelSize /= cw

