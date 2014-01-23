module RenderedMultiSelect
  class Engine < ::Rails::Engine
    
    initializer "rendered-multi-select" do
      ActionView::Base.send(:include, RenderedMultiSelect::RenderedMultiSelectHelpers)
    end
    
  end
end