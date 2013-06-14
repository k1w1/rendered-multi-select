module RenderedMultiSelect
  module RenderedMultiSelectHelpers
    
    def rendered_multi_select(elements, options = {})
      options.symbolize_keys!
      
      html_options = options[:html] || {}
      tag_options = html_options.merge(
        :class => "rendered-multi-select #{html_options[:class]}",
        "data-readonly" => !!options[:readonly])
      
      if !!options[:readonly]
        close_box = ""
      else
        close_box = "<b>&times;</b>"
      end
      
      content_tag(:ul, tag_options) do
        s = ""
        elements.each do |element|
          text, value = option_text_and_value(element).map { |item| item.to_s }
          s << content_tag(:li, :class => "rendered-multi-select-element", "data-id" => value) do
            "#{h(text)}#{close_box}".html_safe
          end
        end
        
        if ! !!options[:readonly]
          input = content_tag(:li, :class => "rendered-multi-select-input") do
            content_tag(:input, "", :type => "text", :placeholder => options[:placeholder])
          end
        else
          input = ""
        end
        
        s.html_safe + input
      end
    end
    
    
    
  private
    def option_text_and_value(option)
      # Options are [text, value] pairs or strings used for both.
      case
      when Array === option
        option = option.reject { |e| Hash === e }
        [option.first, option.last]
      when !option.is_a?(String) && option.respond_to?(:first) && option.respond_to?(:last)
        [option.first, option.last]
      else
        [option, option]
      end
    end
  end
end