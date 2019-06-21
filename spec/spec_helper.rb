require 'sqlite3'
require 'active_record'
require 'i18n'
require 'active_support/core_ext'
require 'byebug'
require 'simple_slug'

I18n.enforce_available_locales = false
I18n.default_locale = :uk

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# ActiveRecord::Base.logger = Logger.new(STDOUT)

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define do
      create_table :rspec_active_record_bases, force: true do |t|
        t.string :name
        t.string :slug, limit: 191
        t.string :slug_en, limit: 191
        t.timestamps
      end

      create_table :simple_slug_history_slugs, force: true do |t|
        t.string :slug, null: false, limit: 191
        t.string :locale, limit: 10
        t.integer :sluggable_id, null: false
        t.string :sluggable_type, limit: 50, null: false
        t.timestamps
      end
    end
  end
end


class RspecActiveRecordBase < ActiveRecord::Base
  include SimpleSlug::ModelAddition
end