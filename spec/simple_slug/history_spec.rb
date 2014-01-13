require 'spec_helper'

class SlugHistoryRspecModel < RspecActiveModelBase
  simple_slug :name, history: true
end

describe 'slug history' do
  describe 'history records handling' do
    before do
      SlugHistoryRspecModel.any_instance.stub(:simple_slug_exists?).and_return(false)
    end

    it 'create' do
      relation = double
      ::SimpleSlug::HistorySlug.should_receive(:where).with(sluggable_type: 'SlugHistoryRspecModel', sluggable_id: nil).and_return(relation)
      relation.should_receive(:first_or_create)
      SlugHistoryRspecModel.create(name: 'Hello')
    end

    it 'cleanup' do
      relation = double
      relation.stub(:first_or_create)
      ::SimpleSlug::HistorySlug.stub(:where).and_return(relation)
      relation.should_receive(:delete_all)
      SlugHistoryRspecModel.create(name: 'Hello', id: 1).destroy
    end
  end

  describe 'conflicts' do
    it 'history slug exists' do
      record = SlugGenerationRspecModel.new(name: 'Hi')
      record.stub(:simple_slug_base_exists?).and_return(false)
      record.should_receive(:simple_slug_history_exists?).once.ordered.and_return(true)
      record.should_receive(:simple_slug_history_exists?).once.ordered.and_return(false)
      record.save
      record.slug.should start_with('hi--')
    end
  end

  describe '#friendly_find' do
    before do
      SlugHistoryRspecModel.stub(:find_by)
    end

    it 'find from history' do
      record = double('history')
      record.stub(:sluggable).and_return(double('record'))
      ::SimpleSlug::HistorySlug.should_receive(:find_by!).with(slug: 'title').and_return(record)
      SlugHistoryRspecModel.friendly_find('title')
    end
  end

end
