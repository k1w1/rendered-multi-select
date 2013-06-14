module RenderedMultiSelect
  module RenderedMultiSelectHelpers
    
    def rendered_multi_select(elements, options = {})
      options.symbolize_keys!
      
      content_tag(:ul, :class => "rendered-multi-select", :id => options[:id]) do
        s = ""
        elements.each do |element|
          text, value = option_text_and_value(element).map { |item| item.to_s }
          s << content_tag(:li, :class => "rendered-multi-select-element", "data-id" => value) do
            "#{h(text)}<b>x</b>".html_safe
          end
        end
        s.html_safe + content_tag(:li, :class => "rendered-multi-select-input") do
          content_tag(:input, "", :type => "text", :placeholder => options[:placeholder])
        end
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