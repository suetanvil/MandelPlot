# MandelPlot, Copyright (C) 2012 Chris Reuter, GPLv2, No Warranty

# Instances of this class can construct a simple control panel
# containing a 2-column grid of descriptions on the left and the
# matching control on the right.
class Quickform

  # Constructor.  Arguments are:
  #
  # prefix     -- the prefix that is appended to each control's name with '_'
  # element    -- the name of the HTML element (a div) that will be the
  #               controls' parent.
  # percentage -- The percentage of the horizontal space that the
  #               first column (the descriptive text) will take.
  #
  # Defines the following methods:
  #
  # prefix()
  # element()
  # numEntry(id, text)
  # button(id, text, label, action)
  # gridSpacer()
  # val(id, value)
  constructor: (prefix, element, percentage = 60) ->
    container = $('#'+element)

    # Return the prefix
    @prefix = -> prefix

    # Return the element
    @element = -> element

    # Private hash mapping IDs to setters/getters
    getters = {}
    setters = {}

    addAccessors = (id, set, get) ->
      getters[pfx(id)] = set
      setters[pfx(id)] = get

    addItem = (percent, value) ->
      section = $('<section/>')
      section.css('float', 'left')
      section.css('width', "#{percent}%")
      section.append(value)
      container.append(section)
      return section.height()

    addRow = (desc, ctrl) ->
      h1 = addItem(percentage, desc)
      h2 = addItem(100 - percentage, ctrl)
      container.height(Math.max(h1, h2) + container.height())

    pfx = (id) -> "#{prefix}_#{id}"

    # Append a numerical entry field with given ID and description text
    @numEntry = (id, text) ->
      e = $("<input maxlength=5 size=5 type=\"number\" id=#{pfx(id)}>")
      addRow(text, e)
      addAccessors(id,
        (pfid) -> $('#'+pfid).val(),
        (pfid, val) -> $('#'+pfid).val(val))

    # Append a button with label 'label' and adjacent text 'text'.
    # 'action' is the function called when the button is pressed.
    @button = (id, text, label, action) ->
      e = $("<button id=\"#{pfx(id)}\">#{label}</button>")
      addRow(text, e)
      $("##{pfx(id)}", container).click(action)

    @checkbox = (id, text) ->
      e = $("<input type=\"checkbox\" id=\"#{pfx(id)}\">#{text}</input>")
      addRow("&nbsp;", e)
      addAccessors(id,
        (pfid) -> $('#'+pfid).prop('checked'),
        (pfid, val) -> $('#'+pfid).prop('checked', !!val) )

    # Append an empty row
    @gridSpacer = ->
      addRow("&nbsp;", "&nbsp;")

    # Get or set the value of the control with id given by 'id'.
    @val = (id, value = null) ->
      sg = if value? then setters else getters
      sg[pfx(id)](pfx(id), value)
