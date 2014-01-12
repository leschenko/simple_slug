require 'active_model'
require 'i18n'
require 'active_support/core_ext'
require 'simple_slug'

class RspecActiveModelBase
  include ActiveModel::AttributeMethods
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks

  define_model_callbacks :validation, :destroy

  attr_reader :attributes
  attr_accessor :id, :created_at

  def initialize(attributes = {})
    @attributes = attributes
  end

  def method_missing(id, *)
    attributes[id.to_sym] || attributes[id.to_s] || super
  end

  def persisted?
    true
  end

  def save
    run_callbacks(:validation) {}
  end

  def destroy
    run_callbacks(:destroy) { @destroyed = true }
  end

  def destroyed?
    !!@destroyed
  end
end
