module SimpleSlug
  class HistorySlug < ActiveRecord::Base
    self.table_name = 'simple_slug_history_slugs'
    belongs_to :sluggable, polymorphic: true
  end
end