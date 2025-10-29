class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user, to: :chat

  validates :content, presence: true
end
