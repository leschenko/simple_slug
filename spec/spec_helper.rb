require 'active_record'
require 'i18n'
require 'active_support/core_ext'
require 'simple_slug'

# just silence warning
I18n.enforce_available_locales = false
I18n.default_locale = :uk

class RspecActiveModelBase
  include ActiveModel::Model
  include ActiveModel::AttributeMethods
  extend ActiveModel::Callbacks

  include SimpleSlug::ModelAddition

  define_model_callbacks :validation, :save, :destroy

  attr_accessor :id, :slug, :name, :created_at
  alias_method :slug_was, :slug

  def self.create(attributes, *)
    record = new(attributes)
    record.save
    record
  end

  def save
    run_callbacks(:validation) { run_callbacks(:save) { } }
  end

  def destroy
    run_callbacks(:destroy) { @destroyed = true }
  end

  def persisted?
    true
  end

  def slug_changed?
    slug.present?
  end

  def destroyed?
    !!@destroyed
  end
end
