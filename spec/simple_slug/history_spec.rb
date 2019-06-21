require 'spec_helper'

class SlugHistoryRspecModel < RspecActiveRecordBase
  simple_slug :name, history: true

  def should_generate_new_slug?
    true
  end
end

class SlugLocalizedHistoryRspecModel < RspecActiveRecordBase
  simple_slug :name_for_slug, history: true, locales: [nil, :en]

  def name_for_slug
    [name, (I18n.locale unless I18n.locale == I18n.default_locale)].compact.join(' ')
  end

  def should_generate_new_slug?
    true
  end
end

describe 'history' do
  before :each do
    RspecActiveRecordBase.delete_all
    SimpleSlug::HistorySlug.delete_all
  end

  describe 'persistence' do
    it 'save previous on change' do
      sluggable = SlugHistoryRspecModel.create(id: 1, name: 'Hello')
      expect(SimpleSlug::HistorySlug.where(sluggable_type: 'SlugHistoryRspecModel', sluggable_id: 1).exists?).to be_falsey
      sluggable.update(name: 'Bye')
      hs = SimpleSlug::HistorySlug.where(sluggable_type: 'SlugHistoryRspecModel', sluggable_id: 1).to_a
      expect(hs.size).to eq 1
      expect(hs.first.locale).to be_falsey
      expect(hs.first.slug).to eq 'hello'
    end

    it 'remove on destroy' do
      sluggable = SlugHistoryRspecModel.create(id: 1, name: 'Hello')
      sluggable.update(name: 'Bye')
      expect{ sluggable.destroy }.to change{ SimpleSlug::HistorySlug.where(sluggable_type: 'SlugHistoryRspecModel', sluggable_id: 1).count }.from(1).to(0)
    end

    context 'localized' do
      it 'save previous on change' do
        SlugLocalizedHistoryRspecModel.create(id: 1, name: 'Hello').update(name: 'Bye')
        hs = SimpleSlug::HistorySlug.where(sluggable_type: 'SlugLocalizedHistoryRspecModel', sluggable_id: 1).to_a
        expect(hs.map(&:locale)).to match_array [nil, 'en']
        expect(hs.map(&:slug)).to match_array %w(hello hello-en)
      end
    end
  end

  describe 'conflicts' do
    it 'resolve with suffix' do
      SlugHistoryRspecModel.create(name: 'Hello').update(name: 'Bye')
      record = SlugHistoryRspecModel.create(name: 'Hello')
      expect(record.slug).to start_with('hello--')
    end

    context 'localized' do
      it 'resolve with suffix' do
        SlugLocalizedHistoryRspecModel.create(name: 'Hello').update(name: 'Bye')
        record = SlugLocalizedHistoryRspecModel.create(name: 'Hello')
        expect(record.slug).to start_with('hello--')
        expect(record.slug_en).to start_with('hello-en--')
      end
    end
  end

  describe 'find' do
    it 'use history' do
      SlugLocalizedHistoryRspecModel.create(id: 1, name: 'Hello').update(name: 'Bye')
      expect(SlugLocalizedHistoryRspecModel.friendly_find('hello')).to be_truthy
    end
  end
end
