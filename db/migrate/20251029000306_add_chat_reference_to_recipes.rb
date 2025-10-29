class AddChatReferenceToRecipes < ActiveRecord::Migration[7.1]
  def change
    add_reference :recipes, :chat, foreign_key: true
  end
end
