module RenderedMultiSelect
  module RenderedMultiSelectHelpers
    
    def rendered_multi_select(elements, options = {})
      content_tag(:ul, :class => "rendered-multi-select") do
        elements.collect do |element|
          content_tag(:li, element.to_s, :class => "rendered-multi-select-element", "data-id" => element.to_s)
        end
        content_tag(:li, :class => "rendered-multi-select-input") do
          content_tag(:input, :type => "text")
        end
      end
    end
    
  end
end