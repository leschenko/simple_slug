require 'spec_helper'

describe SimpleSlug do
  describe 'config' do
    it 'has column name' do
      expect(SimpleSlug.slug_column).to eq 'slug'
    end

    it 'has excludes' do
      expect(SimpleSlug.excludes).to include('new', 'edit')
    end

    it 'has max length' do
     expect( SimpleSlug.max_length).to eq 191
    end
  end
end
