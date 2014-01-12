require 'spec_helper'

class SlugHistoryRspecModel < RspecActiveModelBase
  simple_slug :name, history: true
end

describe SimpleSlug do
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
