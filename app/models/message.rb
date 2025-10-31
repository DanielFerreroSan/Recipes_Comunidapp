class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user, optional: true  #sin el optional true, no me estaba respondiendo la IA, porque los mensajes de la IA no tienen un USER

  validates :content, presence: true
end
