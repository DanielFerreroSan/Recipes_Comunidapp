class Recipe < ApplicationRecord
  belongs_to :chat
  has_one :user, through: :chat

  has_many :ratings, dependent: :destroy

  def average_rating
    ratings.average(:score)&.round(1) || 0
  end

   def rating_by(user)
    ratings.find_by(user: user)&.score
  end
  
end
