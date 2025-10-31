class MakeUserIdOptionalInMessages < ActiveRecord::Migration[7.1]
  def change

    change_column_null :messages, :user_id, true #cambia la columna para que acepte NULL, es decir, que no tenga valor si corresponde a la IA.

  end
end
