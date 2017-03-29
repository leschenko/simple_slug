require 'spec_helper'

class SlugHistoryRspecModel < RspecActiveModelBase
  simple_slug :name, history: true
end

describe 'slug history' do
  describe 'history records handling' do
    before do
      expect_any_instance_of(SlugHistoryRspecModel).to receive(:simple_slug_exists?).and_return(false)
    end

    it 'create' do
      relation = double
      expect(::SimpleSlug::HistorySlug).to receive(:where).once.ordered.with(sluggable_type: 'SlugHistoryRspecModel', slug: 'hello').and_return(relation)
      expect(relation).to receive(:first_or_create)
      SlugHistoryRspecModel.create(id: 1, name: 'Hello')
    end

    it 'cleanup' do
      relation = double
      expect(relation).to receive(:first_or_create)
      allow(::SimpleSlug::HistorySlug).to receive(:where).and_return(relation)
      expect(relation).to receive(:delete_all)
      SlugHistoryRspecModel.create(name: 'Hello', id: 1).destroy
    end
  end

  describe 'conflicts' do
    it 'history slug exists' do
      record = SlugGenerationRspecModel.new(name: 'Hi')
      allow(record).to receive(:simple_slug_base_exists?).and_return(false)
      expect(record).to receive(:simple_slug_history_exists?).once.ordered.and_return(true)
      expect(record).to receive(:simple_slug_history_exists?).once.ordered.and_return(false)
      record.save
      expect(record.slug).to start_with('hi--')
    end
  end

  describe '#friendly_find' do
    before do
      allow(SlugHistoryRspecModel).to receive(:find_by)
    end

    it 'find from history' do
      record = double('history')
      allow(record).to receive(:sluggable_id).and_return(1)
      expect(::SimpleSlug::HistorySlug).to receive(:find_by!).with(slug: 'title').and_return(record)
      expect(SlugHistoryRspecModel).to receive(:find).with(1).and_return(record)
      SlugHistoryRspecModel.friendly_find('title')
    end
  end

end
