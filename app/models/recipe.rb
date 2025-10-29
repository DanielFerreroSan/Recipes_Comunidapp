class Recipe < ApplicationRecord
  belongs_to :chat
  belongs_to :user, through: :chat
end
