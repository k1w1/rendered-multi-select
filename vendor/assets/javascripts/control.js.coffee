(($, window) ->
  
  #
  # Content Editor controls
  #
  class ContentEditorControls
    constructor: (@editor, @options) ->
      @element = $(@controlsHtml)
      
      if @options["alwaysShowToolbar"]
        @element.addClass("always-show")
        @element.show()
        @element.insertBefore(@editor.element)
        @position()
      else
        @element.appendTo(@editor.element.parent())
        @position()
    
    destroy: () ->
      @editor.off()
      @element.destroy()
    
    attach: () ->
      $(window).resize =>
        @position()
      @element.show()
      @position()
      
    detach: ->
      @element.hide() unless @options["alwaysShowToolbar"]

    position: ->
      offset = @editor.element.position()
      actualWidth = @element[0].offsetWidth
      actualHeight = @element[0].offsetHeight
      @element.css
        top: (offset.top - actualHeight) + "px"
        left: offset.left + "px"
        width: @editor.element.outerWidth() + "px"
    
    addButton: (options) =>
      button = $("<li class='" + options.position + "'></li>").appendTo(@element.find("ul"))
      link = $("<a class='tool' data-remote='true' title='" + options.tooltip + "' tabindex='-1'>" + options.content + "</a>").appendTo(button)
      button.on "mousedown", =>
        options.action()
      
    controlsHtml: """
      <div class="content-editor-controls" style="display: none;" data-reactive-preserve="true">
        <ul class="wysihtml5-toolbar">
          <li>
            <a class='tool' data-wysihtml5-command='bold' data-remote='true' title='Bold CTRL+B' rel='tooltip' tabindex='-1'><i class='icon-bold'></i></a>
            <a class='tool' data-wysihtml5-command='italic' data-remote='true' title='Italic CTRL+I' rel='tooltip' tabindex='-1'><i class='icon-italic'></i></a>
            <a class='tool' data-wysihtml5-command='underline' data-remote='true' title='Underline CTRL+U' rel='tooltip' tabindex='-1'><i class='icon-underline'></i></a>
            <a class='tool' data-wysihtml5-command='strikeThrough' data-remote='true' title='Strikethrough' rel='tooltip' tabindex='-1'><i class='icon-strikethrough'></i></a>
            <span class='divider'>&nbsp;</span>
          </li>
          
          <li>
            <a class='tool' data-wysihtml5-command='insertUnorderedList' data-remote='true' title='Unordered list' rel='tooltip' tabindex='-1'><i class='icon-list-ul'></i></a>
            <a class='tool' data-wysihtml5-command='insertOrderedList' data-remote='true' title='Ordered list' rel='tooltip' tabindex='-1'><i class='icon-list-ol'></i></a>
            <a class='tool' data-wysihtml5-command='Outdent' data-remote='true' title='Outdent list' rel='tooltip' tabindex='-1'><i class='icon-indent-left'></i></a>
            <a class='tool' data-wysihtml5-command='Indent' data-remote='true' title='Indent list' rel='tooltip' tabindex='-1'><i class='icon-indent-right'></i></a>
          </li>

          
        </ul>
      </div>
      """

  window.ContentEditorControls = ContentEditorControls
  

)(jQuery, window)
