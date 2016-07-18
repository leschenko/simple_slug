require 'spec_helper'

class SlugGenerationRspecModel < RspecActiveModelBase
  simple_slug :name
end

class SlugGenerationRspecModelWithoutValidation < RspecActiveModelBase
  simple_slug :name, add_validation: false
end

class SlugGenerationRspecModelWithoutCallback < RspecActiveModelBase
  simple_slug :name, callback_type: nil
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

  describe 'max length' do
    before do
      allow_any_instance_of(SlugGenerationRspecModel).to receive(:simple_slug_exists?).and_return(false)
    end

    after do
      SlugGenerationRspecModel.simple_slug_options.delete(:max_length)
    end

    it 'cuts slug to max length' do
      expect(SlugGenerationRspecModel.new(name: 'Hello' * 100).simple_slug_generate.length).to eq 240
    end

    it 'use max length from per model options' do
      SlugGenerationRspecModel.simple_slug_options[:max_length] = 100
      expect(SlugGenerationRspecModel.new(name: 'Hello' * 100).simple_slug_generate.length).to eq 100
    end

    it 'omit max length' do
      SimpleSlug.max_length = nil
      expect(SlugGenerationRspecModel.new(name: 'Hello' * 100).simple_slug_generate.length).to eq 500
    end
  end

  describe 'add_validation' do
    it 'skip validation' do
      expect(SlugGenerationRspecModelWithoutValidation.validators_on(:slug)).to be_blank
    end
  end

  describe 'callback_type' do
    it 'skip callback' do
      expect(SlugGenerationRspecModelWithoutCallback.new).not_to receive(:should_generate_new_slug?)
    end
  end
end
