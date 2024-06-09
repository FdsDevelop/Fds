class FdssApiKey < ApplicationRecord

  def self.generate_new_api_key
    FdssApiKey.create!(serial: SecureRandom.hex(4), secret: SecureRandom.hex(16), sign: SecureRandom.hex(128))
  end

  validates :serial, presence: { message: "can't be blank" }
  validates :serial, uniqueness: true
  validates :secret, presence: { message: "can't be blank" }
  validates :secret, uniqueness: true
  validates :sign, presence: { message: "can't be blank" }
  validates :sign, uniqueness: true
end
