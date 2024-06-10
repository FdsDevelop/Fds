require 'openssl'
module Aes
  def encrypt(data, key)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    cipher.key = key
    encrypted = cipher.update(data) + cipher.final
    Base64.strict_encode64(encrypted)
  end

  # 解密方法
  def decrypt(encrypted_data, key)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.decrypt
    cipher.key = key
    decrypted = cipher.update(Base64.strict_decode64(encrypted_data)) + cipher.final
    decrypted
  end
end