
require "base64"
require "openssl"

module GoogleUrl
    def self.sign(url : String, key_string : String) : String
      # Convert key to bytes
      usable_private_key = key_string.replace("-", "+").replace("_", "/")
      private_key_bytes = Base64.decode(usable_private_key)

      uri = URI.parse(url)
      encoded_path_and_query_bytes = (uri.path + uri.query).to_slice

      # Compute the hash
      hmac = OpenSSL::HMAC.new(OpenSSL::Digest.new("sha1"), private_key_bytes)
      hash = hmac.update(encoded_path_and_query_bytes).digest

      # Convert the bytes to string and make URL-safe
      signature = Base64.strict_encode64(hash).replace("+", "-").replace("/", "_")

      # Add the signature to the existing URI
      return "#{uri.scheme}://#{uri.host}#{uri.path}#{uri.query}&signature=#{signature}"
    end
  end
end
