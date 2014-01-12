module SimpleSlug
  class HistorySlug < ActiveRecord::Base
    belongs_to :sluggable, polymorphic: true
  end
end