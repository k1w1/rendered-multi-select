(($, window) ->
  
  class RenderedMultiSelect
    constructor: (element, @options) ->
      @element = $(element)
    
    destroy: () ->
      @editor.off()
      @element.destroy()
    
)(jQuery, window)
