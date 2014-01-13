require 'spec_helper'

class SlugGenerationRspecModel < RspecActiveModelBase
  simple_slug :name
end

describe SimpleSlug do
  describe 'slug generation' do
    it 'after save' do
      SlugGenerationRspecModel.create(name: 'Hello').slug.should == 'hello'
    end

    it 'skip excludes' do
      SlugGenerationRspecModel.create(name: 'new').should_not be_valid
    end

    it 'skip integers' do
      SlugGenerationRspecModel.create(name: '123').should_not be_valid
    end

    it 'resolve conflicts' do
      SlugGenerationRspecModel.create(name: 'hi')
      SlugGenerationRspecModel.create(name: 'hi').slug.should =~ /hi--\d+/
    end
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
