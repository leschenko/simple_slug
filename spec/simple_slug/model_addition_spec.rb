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

  describe '#friendly_find' do
    it '#find if integer like' do
      SlugGenerationRspecModel.should_receive(:find).with(1)
      SlugGenerationRspecModel.friendly_find(1)
    end

    it '#find if numeric string' do
      SlugGenerationRspecModel.should_receive(:find).with('1')
      SlugGenerationRspecModel.friendly_find('1')
    end

    it '#find if numeric string' do
      SlugGenerationRspecModel.should_receive(:find_by).with('slug' => 'title')
      SlugGenerationRspecModel.friendly_find('title')
    end
  end
end
