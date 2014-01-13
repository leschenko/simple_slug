require 'spec_helper'

class SlugGenerationRspecModel < RspecActiveModelBase
  simple_slug :name
end

describe SimpleSlug::ModelAddition do
  describe 'slug generation' do
    before do
      SlugGenerationRspecModel.any_instance.stub(:simple_slug_exists?).and_return(false)
    end

    it 'after save' do
      SlugGenerationRspecModel.create(name: 'Hello').slug.should == 'hello'
    end

    it 'skip excludes' do
      SlugGenerationRspecModel.new(name: 'new').should_not be_valid
    end

    it 'skip integers' do
      SlugGenerationRspecModel.new(name: '123').should_not be_valid
    end
  end

  describe 'resolve conflicts' do
    it 'duplicate slug' do
      record = SlugGenerationRspecModel.new(name: 'Hi')
      record.should_receive(:simple_slug_exists?).once.ordered.with('hi').and_return(true)
      record.should_receive(:simple_slug_exists?).once.ordered.with(/hi--\d+/).and_return(false)
      record.save
      record.slug.should start_with('hi--')
    end

    it 'numeric slug' do
      record = SlugGenerationRspecModel.new(name: '123')
      record.should_receive(:simple_slug_exists?).with('_123').and_return(false)
      record.save
      record.slug.should == '_123'
    end
  end

  describe '#to_param' do
    before do
      SlugGenerationRspecModel.any_instance.stub(:simple_slug_exists?).and_return(false)
    end

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

    it 'find by slug' do
      SlugGenerationRspecModel.should_receive(:find_by!).with('slug' => 'title').and_return(double)
      SlugGenerationRspecModel.friendly_find('title')
    end
  end
end
