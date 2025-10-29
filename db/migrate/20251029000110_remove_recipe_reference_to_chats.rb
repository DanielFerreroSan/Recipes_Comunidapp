class RemoveRecipeReferenceToChats < ActiveRecord::Migration[7.1]
  def change
    remove_reference :chats, :recipe, foreign_key: true
  end
end
