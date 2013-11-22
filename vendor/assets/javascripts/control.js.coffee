class RenderedMultiSelect
  constructor: (@element, @options) ->
    return if @element.data("readonly") == "true"
    @inputContainer = @element.find(".rendered-multi-select-input")
    @input = @inputContainer.find("input")
    @createResultMenu()
    @registerEvents()
    @lastName = null
     
  registerEvents: ->
    @element.on "keydown", "input", (event) =>
      @inputKeyDown(event)
    @element.on "keyup", "input", (event) =>
      @updateQuery(event)
    @element.on "blur", "input", (event) =>
      setTimeout =>
          @input.val("")
          @resultMenu.fadeOut()
          @element.removeClass("rendered-multi-select-active")
        , 200
    @element.on "focus", "input", (event) =>
      @element.addClass("rendered-multi-select-active")
      @lastName = null
      @updateQuery()
    @element.on "click", ".rendered-multi-select-menu li", (event) =>
      @addItem($(event.target))
      event.stopPropagation()
    @element.on "click", ".rendered-multi-select-element b", (event) =>
      @deleteItem($(event.target).parent(".rendered-multi-select-element"))
      event.stopPropagation()
    @element.on "click", (event) =>
      # Focus the input when user clicks on the control.
      @input[0].focus()
  
  createResultMenu: ->
    @resultMenu = $("<div class='rendered-multi-select-menu'><ul class='rendered-multi-select-results'></ul></div")
    @resultMenu.insertAfter(@input)
    @resultList = @resultMenu.find("ul")
    
  inputKeyDown: (event) ->
    switch event.keyCode
      when 13 # Enter
        if (result = @resultList.find("li").filter(".selected")).length != 0
          @addItem(result)
        else if @options.allowNew
          @createNewItem(@input.val())
      when 40 # Down arrow
        @selectNextResult(1)
      when 38 # Up arrow
        @selectNextResult(-1)
      when 8 # Backspace
        if @input.val().length > 0
          return
        else
          @deleteLastItem()
      else
        # Perform the default.
        return
    event.stopPropagation()
    event.preventDefault()

  clearInput: ->
    @lastName = null
    @input.val("")
    @resultMenu.hide()
    
  createNewItem: (name) ->
    name = $.trim(name)
    return if name.length == 0
    return if @itemExists(name)
    if @options.onCreateItem
      return unless name = @options.onCreateItem(name)
    @addItemRow(name)
    @clearInput()
    @updateQuery()
  
  deleteLastItem: ->
    lastItem = @element.find(".rendered-multi-select-element").last()
    return if lastItem.length == 0
    @deleteItem(lastItem)
    @lastName = null
    @updateQuery()
    
  deleteItem: (item) ->
    if @options.onDeleteItem
      @options.onDeleteItem(item.attr("data-id"))
    item.remove()
    @element.trigger("change")
   
  updateQuery: ->
    q = $.trim(@input.val())
    return if @lastName == q
    @lastName = q
    if @options.onQuery
      @options.onQuery q, (results) =>
        @showQueryResults(results)
  
  showQueryResults: (results) ->
    @resultList.empty()
    # Compute existing items so we can remove duplicates.
    existingItems = @existingItems()
    resultAdded = false
    for result in results
      continue if $.inArray(result.name, existingItems) != -1
      @resultList.append("<li data-id='#{result.id}'>#{result.name}</li>")
      resultAdded = true
    #@resultMenu.css("left", @input.position().left + "px")
    if resultAdded
      # Only if we have focus.
      @resultMenu.show() if $(@input).is(":focus")
    else
      @resultMenu.hide()
    
  addItem: (result) ->
    id = result.attr("data-id")
    name = result.html()
    if @options.onAddItem
      @options.onAddItem(id, name)
    @addItemRow(name, id)
    @resultMenu.hide()
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
    @inputContainer.before("<li class='rendered-multi-select-element' data-id='#{id}' style='#{style}'>#{name}<b>&times;</b></li>")  
    @element.trigger("change")
    
  itemExists: (name) ->
    $.inArray(name, @existingItems()) != -1
    
  existingItems: ->
    @element.find(".rendered-multi-select-element")
      .map (index, element) ->
        $(element).text().slice(0,-1)
      .get()
      
$.fn.renderedMultiSelect = (options, args...) ->
  @each ->
    $this = $(this)
    data = $this.data('plugin_renderedMultiSelect')

    if !data
      $this.data 'plugin_renderedMultiSelect', (data = new RenderedMultiSelect( $this, options))
    if typeof options == 'string'
      data[options].apply(data, args)

