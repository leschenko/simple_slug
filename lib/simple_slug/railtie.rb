module SimpleSlug
  class Railtie < Rails::Railtie
    initializer 'simple_slug.model_additions' do
      ActiveSupport.on_load :active_record do
        include SimpleSlug::ModelAddition
      end
    end
  end
end