class AddColumnsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :activity, :string
    add_column :users, :age, :integer
    add_column :users, :gender, :string
    add_column :users, :height, :integer
    add_column :users, :restrictions, :text
    add_column :users, :weight, :integer
  end
end
