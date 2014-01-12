require 'spec_helper'

class SlugGenerationRspecModel < RspecActiveModelBase
  simple_slug :name
end

describe SimpleSlug do
  it 'generate slug after save' do
    SlugGenerationRspecModel.create(name: 'Hello').slug.should == 'hello'
  end
end
