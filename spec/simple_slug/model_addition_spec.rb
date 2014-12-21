require 'spec_helper'

class SlugGenerationRspecModel < RspecActiveModelBase
  simple_slug :name
end

describe SimpleSlug::ModelAddition do
  describe 'slug generation' do
    before do
      allow_any_instance_of(SlugGenerationRspecModel). to receive(:simple_slug_exists?).and_return(false)
    end

    it 'after save' do
      expect(SlugGenerationRspecModel.create(name: 'Hello').slug).to eq 'hello'
    end

    it 'skip excludes' do
      expect(SlugGenerationRspecModel.new(name: 'new')).not_to be_valid
    end

    it 'skip integers' do
      expect(SlugGenerationRspecModel.new(name: '123')).not_to be_valid
    end

    it 'skip slug generation' do
      allow_any_instance_of(SlugGenerationRspecModel).to receive(:should_generate_new_slug?).and_return(false)
      expect(SlugGenerationRspecModel.create(name: 'Hello').slug).to be_blank
    end
  end

  describe 'resolve conflicts' do
    it 'duplicate slug' do
      record = SlugGenerationRspecModel.new(name: 'Hi')
      expect(record).to receive(:simple_slug_exists?).once.ordered.with('hi').and_return(true)
      expect(record).to receive(:simple_slug_exists?).once.ordered.with(/hi--\d+/).and_return(false)
      record.save
      expect(record.slug).to start_with('hi--')
    end

    it 'numeric slug' do
      record = SlugGenerationRspecModel.new(name: '123')
      expect(record).to receive(:simple_slug_exists?).with('_123').and_return(false)
      record.save
      expect(record.slug).to eq '_123'
    end
  end

  describe '#to_param' do
    before do
      allow_any_instance_of(SlugGenerationRspecModel).to receive(:simple_slug_exists?).and_return(false)
    end

    it 'slug if exists' do
      expect(SlugGenerationRspecModel.create(name: 'Hello').to_param).to eq 'hello'
    end

    it 'id without slug' do
      expect(SlugGenerationRspecModel.create(id: 1).to_param).to eq '1'
    end
  end

  describe '#friendly_find' do
    it '#find if integer like' do
      expect(SlugGenerationRspecModel).to receive(:find).with(1)
      SlugGenerationRspecModel.friendly_find(1)
    end

    it '#find if numeric string' do
      expect(SlugGenerationRspecModel).to receive(:find).with('1')
      SlugGenerationRspecModel.friendly_find('1')
    end

    it 'find by slug' do
      expect(SlugGenerationRspecModel).to receive(:find_by!).with('slug' => 'title').and_return(double)
      SlugGenerationRspecModel.friendly_find('title')
    end
  end
end
