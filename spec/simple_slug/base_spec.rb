require 'spec_helper'

describe SimpleSlug do
  context 'defaults' do
    it 'slug column' do
      expect(SimpleSlug.slug_column).to eq 'slug'
    end

    it 'excludes' do
      expect(SimpleSlug.excludes).to include('new', 'edit')
    end

    it 'exclude regexps' do
     expect( SimpleSlug.exclude_regexp).to eq /\A\d+\z/
    end

    it 'max length' do
     expect( SimpleSlug.max_length).to eq 240
    end
  end
end
