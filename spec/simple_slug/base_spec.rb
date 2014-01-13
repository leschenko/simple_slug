require 'spec_helper'

describe SimpleSlug do
  context 'defaults' do
    it 'slug column' do
      SimpleSlug.slug_column.should == 'slug'
    end

    it 'excludes' do
      SimpleSlug.excludes.should include('new', 'edit')
    end

    it 'exclude regexps' do
      SimpleSlug.exclude_regexp.should == /\A\d+\z/
    end
  end
end
