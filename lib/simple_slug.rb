require 'simple_slug/version'
require 'active_support/core_ext'
require 'simple_slug/model_addition'
require 'simple_slug/railtie' if Object.const_defined?(:Rails)

module SimpleSlug
  autoload :Adapter, 'simple_slug/adapter'
  autoload :ModelAddition, 'simple_slug/model_addition'
  autoload :HistorySlug, 'simple_slug/history_slug'

  mattr_accessor :excludes
  @@excludes = %w(new edit show index session login logout sign_in sign_out users admin stylesheets javascripts images fonts assets)

  mattr_accessor :slug_regexp
  @@slug_regexp = /\A(?:\w+[\w\d\-_]*|--\d+)\z/

  mattr_accessor :slug_column
  @@slug_column = 'slug'

  mattr_accessor :min_length
  @@min_length = 3

  mattr_accessor :max_length
  @@max_length = 191

  mattr_accessor :callback_type
  @@callback_type = :before_validation

  mattr_accessor :validation
  @@validation = true

  STARTS_WITH_NUMBER_REGEXP =/\A\d+/
  NUMBER_REGEXP =/\A\d+\z/
  RESOLVE_SUFFIX_REGEXP = /--\d+\z/

  def self.setup
    yield self
  end
end
