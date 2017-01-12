require 'simple_slug/version'
require 'active_support/core_ext'
require 'simple_slug/model_addition'
require 'simple_slug/railtie' if Object.const_defined?(:Rails)

module SimpleSlug
  autoload :HistorySlug, 'simple_slug/history_slug'

  mattr_accessor :excludes
  @@excludes = %w(new edit show index session login logout sign_in sign_out users admin stylesheets assets javascripts images)

  mattr_accessor :slug_regexp
  @@slug_regexp = /\A\w+[\w\d\-_]*\z/

  mattr_accessor :slug_column
  @@slug_column = 'slug'

  mattr_accessor :max_length
  @@max_length = 240

  mattr_accessor :callback_type
  @@callback_type = :before_validation

  mattr_accessor :add_validation
  @@add_validation = true

  STARTS_WITH_NUMBER_REGEXP =/\A\d+/
  CYRILLIC_LOCALES = [:uk, :ru, :be].freeze

  def self.setup
    yield self
  end

  def self.normalize_cyrillic(base)
    base.tr('АаВЕеіКкМНОоРрСсТуХх', 'AaBEeiKkMHOoPpCcTyXx')
  end
end
