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
      pending
    end
  end

  describe '#friendly_find' do
    it 'find from history' do
      pending
    end
  end

end
