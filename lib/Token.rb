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

    def insert(token, team_id, service_id, round)
        db = SQLite3::Database.open(AdminConfig.db)

        begin
            db.execute( "insert into flags (token, team_id, service_id, round) values (:token, :team_id, :service_id, :round)",
                       "token" => token,
                       "team_id" => team_id,
                       "service_id" => service_id,
                       "round" => round)
        rescue
            fail "Query teams error" 
        end
    end
end
