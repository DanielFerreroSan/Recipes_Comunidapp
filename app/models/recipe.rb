class Recipe < ApplicationRecord
  belongs_to :chat
  has_one :user, through: :chat

  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  
end
