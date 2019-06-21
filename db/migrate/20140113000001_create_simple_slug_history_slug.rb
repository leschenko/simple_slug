class CreateSimpleSlugHistorySlug < ActiveRecord::Migration
  def change
    create_table :simple_slug_history_slugs do |t|
      t.string :slug, null: false, limit: 191
      t.string :locale, limit: 10
      t.integer :sluggable_id, null: false
      t.string :sluggable_type, limit: 50, null: false
      t.timestamps
    end

    add_index :simple_slug_history_slugs, :slug
    add_index :simple_slug_history_slugs, [:sluggable_type, :sluggable_id], name: 'simple_slug_history_slugs_on_sluggable_type_and_sluggable_id'
  end
end
