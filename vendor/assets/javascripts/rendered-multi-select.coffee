_ = require('lodash')

class RenderedMultiSelect
  constructor: (@element, @options) ->
    return if @element.data("readonly") == "true"
    @body = $('body')
    @win  = $(window)
    @inputContainer = @element.find(".rendered-multi-select-input")
    @input = @inputContainer.find(".editable-input")
    @createResultMenu()
    @registerEvents()
    @multiple = @element.data("multiple") == true
    @lastName = null
    @configureMultiple()
    @blurTimeout = null
    
  registerEvents: ->
    @element.on "keydown", ".editable-input", (event) =>
      @inputKeyDown(event)
    @element.on 'keyup', '.editable-input', _.throttle((=>
      @updateQuery()
      ), 200)
    @element.on "blur", ".editable-input", (event) =>
      # Create any partially edited item if it allows new options
      if @input.text() && (index = @resultList.find("li").map(() -> $(this).text().toLowerCase()).get().indexOf(@input.text().toLowerCase())) >= 0
        @addItem(@resultList.find("li").eq(index))
      else if @options.allowNew
        @createNewItem(@input.text())

      @blurTimeout = setTimeout =>
          @blurTimeout = null
          @input.html("")
          @hideResultMenu(true)
          @element.removeClass("rendered-multi-select-active")
        , 200
    @element.on "focus", ".editable-input", (event) =>
      clearTimeout @blurTimeout if @blurTimeout
      @element.addClass("rendered-multi-select-active")
      @lastName = null
      @updateQuery()
    @resultMenu.on "click", "li", (event) =>
      @addItem($(event.target))
      event.stopPropagation()
    @resultMenu.on "focus", (event) =>
      unless @input.is(":focus")
        clearTimeout @blurTimeout if @blurTimeout
        @input[0].focus() if @input[0]
    @resultMenu.on "mousedown", (event) =>
      false
    @element.on "click", ".rendered-multi-select-element b", (event) =>
      @deleteItem($(event.target).parent(".rendered-multi-select-element"))
      event.stopPropagation()
    @element.on "click", (event) =>
      # Focus the input when user clicks on the control.
      unless @input.is(":focus")
        clearTimeout @blurTimeout if @blurTimeout
        @input[0].focus() if @input[0]
      
    @element.on "change", (event) =>
      @configureMultiple()
      
  configureMultiple: ->
      # For non-multiple item controls hide input if an item exists.
      unless @multiple 
        if @element.find(".rendered-multi-select-element").length > 0
          @inputContainer.hide()
        else
          @inputContainer.show()
  
  createResultMenu: ->
    @resultMenu = $("<div class='rendered-multi-select-menu'><ul class='rendered-multi-select-results'></ul></div")

    if @element.attr("data-fixed-menu") == "true"
      @resultMenu.addClass('fixed')
      @body.append(@resultMenu)
    else
      @resultMenu.insertAfter(@input)

    @resultList = @resultMenu.find("ul")

  showResultMenu: ->
    return @resultMenu.show() unless @element.attr("data-fixed-menu") == "true"

    winHeight = @win.height()
    inputTop  = @inputContainer.offset().top
    elemLeft  = @element.offset().left
    scrollTop = @body.scrollTop()
    rules     = 
      display: 'block'
      left:    elemLeft - @body.scrollLeft()
      width:   @element.width()

    if winHeight / 2 < inputTop - scrollTop
      rules.bottom = winHeight - inputTop + scrollTop
    else
      rules.top = inputTop - scrollTop + @inputContainer.height()

    @resultMenu.css(rules)
    @body.css(overflow: 'hidden')
    return

  hideResultMenu: (fade=false) ->
    @body.css(overflow: 'auto') if @element.attr("data-fixed-menu") == "true"
    @resultMenu[if fade then 'fadeOut' else 'hide']()
    
  inputKeyDown: (event) ->
    switch event.keyCode
      when 13 # Enter
        if (result = @resultList.find("li").filter(".selected")).length != 0
          @addItem(result)
        else if @resultList.find("li").length == 1
          @addItem(@resultList.find("li").first())
        else if (index = @resultList.find("li").map(() -> $(this).text().toLowerCase()).get().indexOf(@input.text().toLowerCase())) >= 0
          @addItem(@resultList.find("li").eq(index))
        else if @options.allowNew
          @createNewItem(@input.text())
      when 40 # Down arrow
        @selectNextResult(1)
      when 38 # Up arrow
        @selectNextResult(-1)
      when 8 # Backspace
        if @input.text().length > 0
          return
        else
          @deleteLastItem()
      else
        # Perform the default.
        return
    event.stopPropagation()
    event.preventDefault()
  
  escapeAttr: (v) ->
    v.replace(/'/g, '&apos;').replace(/"/g, '&quot;') if v?
  
  clearInput: ->
    @lastName = null
    @input.text("")
    @hideResultMenu()
    
  createNewItem: (name) ->
    name = $.trim(name)
    return if name.length == 0
    return if @itemExists(name)
    if @options.onCreateItem
      return unless name = @options.onCreateItem(name)
    @addItemRow(_.escape(name), _.escape(name))
    @clearInput()
    @updateQuery()
  
  deleteLastItem: ->
    lastItem = @element.find(".rendered-multi-select-element").last()
    return if lastItem.length == 0
    @deleteItem(lastItem)
    @lastName = null
    @updateQuery()
    
  deleteItem: (item) ->
    item.remove()
    if @options.onDeleteItem
      @options.onDeleteItem(item.attr("data-id"))
    @element.trigger("change")
   
  updateQuery: ->
    q = $.trim(@input.text())
    return if @lastName == q
    @lastName = q
    if @options.onQuery
      @options.onQuery q, (results) =>
        @showQueryResults(results)
  
  showQueryResults: (results) ->
    @resultList.empty()
    @resultData = {}
    
    if results.length > 0 && results[0].parent
      groupedResults = @groupResults(results)
      for parent, results of groupedResults
        if results.length > 0
          @resultList.append("<li class='header-row'>#{parent}</li>")
          resultAdded = @appendResults(results, "has-parent")
    else    
      resultAdded = @appendResults(results, "")

    if resultAdded
      # Only if we have focus.
      @showResultMenu() if $(@input).is(":focus")
    else
      @hideResultMenu()
    
  groupResults: (results) ->
    groupedResults = {}
    for result in results
      groupedResults[result.parent] ||= []
      groupedResults[result.parent].push(result)
    groupedResults

  appendResults: (results, classes) ->
    # Compute existing items so we can remove duplicates.
    existingIds = @existingIds()
    newExistingNames = @newExistingNames()

    resultAdded = false
    i = 0
    max = 500
    if results.length < max
      max = results.length
    else
      tooMany = true
    while i < max
      result = results[i]
      i++
      if $.inArray(result.id, existingIds) != -1 or $.inArray(result.name, newExistingNames) != -1
        continue

      name = result.name
      if newExistingNames.length > 0 || existingIds.length > 0
        name = name.replace(/^(&nbsp;)+/, "")
      
      cleanName = _.escape($("<div>#{name}</div>").text())

      @resultData[result.id] = name
      @resultList.append("<li class='#{classes}' data-id='#{@escapeAttr(result.id)}'>#{cleanName}</li>")
      resultAdded = true
    if tooMany
      @resultList.append("<li class='#{classes}' style='color: #ccc;'><small>Too many results, search to display more&#8230;</small></li>")
    resultAdded

  addItem: (result) ->
    id = result.attr("data-id")
    unless id
      return false
    name = @resultData[id]
    @addItemRow(name, id)
    if @options.onAddItem
      @options.onAddItem(id, name)
    @hideResultMenu()
    @clearInput()
    @updateQuery()
  
  selectNextResult: (offset) ->
    items = @resultList.find("li")
    currentIndex = items.index(items.filter(".selected"))
    items.removeClass("selected")
    currentIndex += offset
    if currentIndex >= items.length
      @resultList.find("li").first().addClass("selected")
    else if currentIndex < 0
      @resultList.find("li").last().addClass("selected")
    else
      $(items[currentIndex]).addClass("selected")
    
  addItemRow: (name, id) ->
    if @options.onStyleItem
      style = @options.onStyleItem(name)
    else
      style = ""
    row = $("<li class='rendered-multi-select-element' data-id='#{@escapeAttr(id)}' style='#{style}'></li>")
    row.html(name)
    row.append("<b>&times;</b>")
    @inputContainer.before(row)  
    @element.trigger("change")
    
  itemExists: (name) ->
    $.inArray(name, @existingNames()) != -1
  
  existingNames: ->
    @element.find(".rendered-multi-select-element")
      .map (index, element) ->
        $(element).text().slice(0,-1)
      .get()

  newExistingNames: ->
    @element.find(".rendered-multi-select-element[data-id=undefined]")
      .map (index, element) ->
        $(element).text().slice(0,-1)
      .get()
      
  existingIds: ->
    @element.find(".rendered-multi-select-element")
      .map (index, element) ->
        $(element).attr("data-id")
      .get()
      
$.fn.renderedMultiSelect = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_renderedMultiSelect')

    if !data
      $this.data 'plugin_renderedMultiSelect', (data = new RenderedMultiSelect( $this, options))
    if typeof options == 'string'
      data[options].apply(data, args)

