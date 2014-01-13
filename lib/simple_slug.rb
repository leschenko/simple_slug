require 'simple_slug/version'
require 'active_support/core_ext'
require 'simple_slug/model_addition'
require 'simple_slug/railtie' if Object.const_defined?(:Rails)

module SimpleSlug
  autoload :HistorySlug, 'simple_slug/history_slug'

  mattr_accessor :excludes
  @@excludes = %w(new edit index session login logout sign_in sign_out users admin stylesheets assets javascripts images)

  mattr_accessor :exclude_regexp
  @@exclude_regexp = /\A\d+\z/

  mattr_accessor :slug_column
  @@slug_column = 'slug'

  def self.setup
    yield self
  end

end
