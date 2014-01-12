require 'spec_helper'

class SlugGenerationRspecModel < RspecActiveModelBase
  simple_slug :name
end

describe SimpleSlug do
  it 'generate slug after save' do
    SlugGenerationRspecModel.create(name: 'Hello').slug.should == 'hello'
  end

  describe '#to_param' do
    it 'slug if exists' do
      SlugGenerationRspecModel.create(name: 'Hello').to_param.should == 'hello'
    end

    it 'id without slug' do
      SlugGenerationRspecModel.create(id: 1).to_param.should == '1'
    end
  end
end
