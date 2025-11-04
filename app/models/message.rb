class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user, optional: true  #sin el optional true, no me estaba respondiendo la IA, porque los mensajes de la IA no tienen un USER
  has_one_attached :file
  validates :content, presence: true
end
