require 'spec_helper'

class SlugRspecModel < RspecActiveRecordBase
  simple_slug :name
end

class SlugWithFallbackOnBlankRspecModel < RspecActiveRecordBase
  simple_slug :name, fallback_on_blank: true
end

class SlugWithoutMaxLengthRspecModel < RspecActiveRecordBase
  simple_slug :name, max_length: nil
end


class SlugWithoutValidationRspecModel < RspecActiveRecordBase
  simple_slug :name, validation: false
end

class SlugWithoutCallbackRspecModel < RspecActiveRecordBase
  simple_slug :name, callback_type: nil
end

class SlugLocalizedRspecModel < RspecActiveRecordBase
  simple_slug :name_for_slug, history: true, locales: [nil, :en]

  def name_for_slug
    [name, (I18n.locale unless I18n.locale == I18n.default_locale)].compact.join(' ')
  end
end

describe SimpleSlug::ModelAddition do
  before :each do
    RspecActiveRecordBase.delete_all
    SimpleSlug::HistorySlug.delete_all
  end

  describe 'slug' do
    it 'generate on save' do
      expect(SlugRspecModel.create(name: 'Hello').slug).to eq 'hello'
    end

    it 'add prefix for numbers' do
      expect(SlugRspecModel.create(name: '123').slug).to eq '_123'
    end

    it 'reject excludes' do
      expect(SlugRspecModel.new(name: 'new')).not_to be_valid
    end

    it 'reject spaces' do
      expect(SlugRspecModel.new(slug: 'test test')).not_to be_valid
    end

    it 'reject punctuation' do
      expect(SlugRspecModel.new(slug: 'test.test')).not_to be_valid
    end

    it 'fallback to prefixed id on blank slug source' do
      expect(SlugWithFallbackOnBlankRspecModel.create({}).slug).to start_with '__'
    end

    describe '#should_generate_new_slug?' do
      it 'can omit generation' do
        allow_any_instance_of(SlugRspecModel).to receive(:should_generate_new_slug?).and_return(false)
        expect(SlugRspecModel.create(name: 'Hello').slug).to be_blank
      end
    end
  end

  describe 'conflicts' do
    it 'resolve with suffix' do
      SlugRspecModel.create(name: 'Hello')
      record = SlugHistoryRspecModel.create(name: 'Hello')
      expect(record.slug).to start_with('hello--')
    end

    context 'localized' do
      it 'resolve with suffix' do
        SlugLocalizedRspecModel.create(name: 'Hello')
        record = SlugLocalizedRspecModel.create(name: 'Hello')
        expect(record.slug).to start_with('hello--')
        expect(record.slug_en).to start_with('hello-en--')
      end
    end
  end

  describe '#to_param' do
    before do
      allow_any_instance_of(SlugRspecModel).to receive(:simple_slug_exists?).and_return(false)
    end

    it 'use slug if present' do
      expect(SlugRspecModel.create(name: 'Hello').to_param).to eq 'hello'
    end

    it 'do not use unsaved slug' do
      expect(SlugRspecModel.new(name: 'Hello').to_param).to be_falsey
    end

    it 'use id if slug blank' do
      expect(SlugRspecModel.create(id: 1).to_param).to eq '1'
    end
  end

  describe 'find' do
    it 'by id on integer like param' do
      expect(SlugRspecModel).to receive(:find).with('1')
      SlugRspecModel.friendly_find('1')
    end

    it 'by slug' do
      expect(SlugRspecModel).to receive(:find_by!).with('slug' => 'title').and_return(double)
      SlugRspecModel.friendly_find('title')
    end
  end

  describe 'max length' do
    it 'cuts slug to max length' do
      record = SlugRspecModel.new(name: 'Hello' * 100)
      record.simple_slug_generate
      expect(record.slug.length).to eq 191
    end

    it 'return full slug without max_length option' do
      record = SlugWithoutMaxLengthRspecModel.new(name: 'Hello' * 100)
      record.simple_slug_generate
      expect(record.slug.length).to eq 500
    end
  end

  describe 'validation' do
    it 'optionally skip validations' do
      expect(SlugWithoutValidationRspecModel.validators_on(:slug)).to be_blank
    end
  end

  describe 'callbacks' do
    it 'optionally skip callback' do
      expect(SlugWithoutCallbackRspecModel.new).not_to receive(:should_generate_new_slug?)
    end
  end

  describe 'localized' do
    it 'generate slug for locales' do
      record = SlugLocalizedRspecModel.create(name: 'Hello')
      expect(record.slug).to eq 'hello'
      expect(record.slug_en).to eq 'hello-en'
    end

    describe '#should_generate_new_slug?' do
      it 'keep slug when present' do
        record = SlugLocalizedRspecModel.create(name: 'Hello')
        expect{ record.update(name: 'Bye') }.not_to change{ record.slug }
      end

      it 'generate slug when blank' do
        record = SlugLocalizedRspecModel.create(name: 'Hello')
        record.name = 'bye'
        record.slug_en = nil
        expect{ record.save }.to change{ record.slug_en }.to('bye-en')
      end
    end

    describe '#to_param' do
      it 'use unlocalized column for default locale' do
        record = SlugLocalizedRspecModel.create(name: 'Hello')
        expect(record.to_param).to eq 'hello'
      end

      it 'use localized column for non-default locales' do
        record = SlugLocalizedRspecModel.create(name: 'Hello')
        I18n.with_locale(:en) do
          expect(record.to_param).to eq 'hello-en'
        end
      end
    end

    describe 'find' do
      it 'use default slug column for default locale' do
        record = SlugLocalizedRspecModel.create(name: 'Hello')
        expect(SlugLocalizedRspecModel.simple_slug_find('hello')).to eq record
      end

      it 'use localized slug column for non-default locale' do
        record = SlugLocalizedRspecModel.create(name: 'Hello')
        I18n.with_locale(:en) do
          expect(SlugLocalizedRspecModel.simple_slug_find('hello-en')).to eq record
        end
      end
    end
  end
end
