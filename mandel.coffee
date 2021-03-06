# MandelPlot, Copyright (C) 2012 Chris Reuter
#
# MandelPlot is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#
# MandelPlot is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MandelPlot; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
#

# This is the main entry-point for MandelPlot.

# Global plot state
Plotter = null  # This object handles the actual computation and plotting
Zoomer = null   # This object lets the user select a new region to plot
Ctrl = null     # This object constructs a bunch of controls


# The entry point.  This gets called when the document is ready.
$(document).ready ->
  initGlobals()
  setupControls()
  fetchUrlParams()
  startRendering()


# Create the global objects which hold everything
initGlobals = ->
  Plotter = new PlotState('#mandelplot_canvas')
  Zoomer = new ZoomSelection('#mandelplot_selection')
  Ctrl = new Quickform('mandelplot', 'mandelplot_ui')


# Create the controls that appear below the canvas
setupControls =  ->
  makeUI()
  writeToUI()
  updateCaption()


# Actually create the form UI
makeUI = ->
  Ctrl.numEntry('iter',     "Iterations per pixel")
  Ctrl.numEntry('slice',    "Pixels per Event:")
  Ctrl.gridSpacer()
  Ctrl.checkbox('cool', "   Reverse colors")
  Ctrl.checkbox('nohist',   "Disable histogram coloring")
  Ctrl.checkbox('nosmooth', "Disable smoothing")
  Ctrl.gridSpacer()
  Ctrl.button('rbtn', "Render the selected region", "Render", startRendering)
  Ctrl.button('zbtn', "Zoom out by 50% and re-render", "Zoom Out",
      zoomOutAndRender)
  Ctrl.button('rsbtn', "Reset zoom and re-render", "Reset", resetPosAndRender)


# If the URL contains coordinates after the hash ('#'), parse them and
# set them as the starting point.
fetchUrlParams = ->
  # Return unless there are parameters attached to the URL
  hash = $(location).attr('hash')
  return unless hash != ""

  # Update Plotter from the URL params
  Plotter.setFromLink(hash)

  # And update the UI
  writeToUI()


# Update the caption underneath the canvas to show the current
# coordinates and pixelsize
updateCaption = ->
  $('#mandelplot_region').text(Plotter.desc())

  baseUrl = $(location).attr('href').replace(/\#.*/, "")
  #console.debug(baseUrl)
  $('#mandelplot_link').attr('href', "#{baseUrl}##{Plotter.link()}")


# Overwrite the user's input with the actual values in Plotter
writeToUI = ->
  Ctrl.val('iter', Plotter.iter)
  Ctrl.val('slice', Plotter.slice)
  Ctrl.val('cool', Plotter.reverseColor)
  Ctrl.val('nohist', !Plotter.histColor)
  Ctrl.val('nosmooth', !Plotter.smoothing)


# Set Plotter's parameters from the user's input IF the input is
# valid.
readFromUI = ->
  iter = parseInt(Ctrl.val('iter'))
  Plotter.iter = iter   if iter >= 1

  slice = parseInt(Ctrl.val('slice'))
  Plotter.slice = slice if slice >= 1

  Plotter.reverseColor = Ctrl.val('cool')
  Plotter.histColor = !Ctrl.val('nohist')
  Plotter.smoothing = !Ctrl.val('nosmooth')



# Start rendering the Mandelbrot set.  If the user has selected a
# rectangle, first set Plotter to use it; otherwise, just use the
# current settings.
startRendering = ->
  if Zoomer.hasSelection()
    [x, y] = Zoomer.topleft
    Plotter.setRenderRect(x, y, Zoomer.width)
    Zoomer.clearSelection()
  readFromUI()
  writeToUI()   # reset any invalid inputs
  updateCaption()
  #startTime = new Date()
  Plotter.startRender() #-> console.debug("Elapsed: #{new Date() - startTime}"))


# Zoom out and start rendering.
zoomOutAndRender = ->
  Zoomer.clearSelection()
  Plotter.zoom(1.5)
  startRendering()


# Reset the Plot position to the default and re-render
resetPosAndRender = () ->
  Zoomer.clearSelection()
  Plotter.reset()
  startRendering()
