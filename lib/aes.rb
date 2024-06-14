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

  def api_auth

    begin
      deadline_time = Rails.application.config.fds.deadline_s
      serial = params[:serial]
      payload_encrypt = params[:payload]
      fdss_api_key = FdssApiKey.find_by!(serial: serial)
      secret = fdss_api_key.secret
      sign = fdss_api_key.sign
      payload_str = decrypt(payload_encrypt, secret)
      payload = JSON.parse!(payload_str)
      if sign != payload["sign"]
        raise "sign invalid"
      end
      time_diff = Time.current.to_i - payload["time_stamp"].to_i
      if time_diff > deadline_time
        raise "api request deadline"
      end
      params[:data] = payload["data"]
    rescue => e
      puts "Error #{e.message}"
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end