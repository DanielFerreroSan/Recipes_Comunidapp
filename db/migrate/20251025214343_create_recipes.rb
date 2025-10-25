class CreateRecipes < ActiveRecord::Migration[7.1]
  def change
    create_table :recipes do |t|
      t.string :category
      t.text :content
      t.text :ingredients
      t.string :name

      t.timestamps
    end
  end
end
