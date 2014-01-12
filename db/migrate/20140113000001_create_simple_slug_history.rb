class CreateSimpleSlugHistory < ActiveRecord::Migration
  def change
    create_table :simple_slug_history do |t|
      t.string :slug, null: false
      t.integer :sluggable_id, null: false
      t.string :sluggable_type, limit: 50, null: false
      t.datetime :created_at
    end

    add_index :simple_slug_history, [:slug, :sluggable_type], unique: true
    add_index :simple_slug_history, [:sluggable_type, :sluggable_id]
  end
end
