class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user, optional: true  #sin el optional true, no me estaba respondiendo la IA, porque los mensajes de la IA no tienen un USER
  has_one_attached :file
  validates :content, presence: true
validates :content, length: { minimum: 10, maximum: 1000 }, if: -> { role == "user" }
  validate :file_size_validation

  MAX_FILE_SIZE_MB = 10

  private

  def file_size_validation
    if file.attached? && file.byte_size > MAX_FILE_SIZE_MB.megabytes
      errors.add(:file, "size must be less than #{MAX_FILE_SIZE_MB}MB")
    end
  end

end
