require "digest"
require 'securerandom'

class Token
    def initialize
        @cipher = Digest::SHA256.new
    end

    def gen
        msg = SecureRandom.hex(1024)
        digest = @cipher.digest msg
        return digest.unpack("H*")[0]
    end
end
