
require "open3"

class Workstation
    def initialize(host, user, private_key)
        fail "Private key is missing." if not File.exist?(private_key)
        @host = host
        @user = user 
        @private_key = private_key
    end

    def exec(cmd)
        o, s = Open3.capture2(cmd)
        puts "[!] CMD: #{cmd}" if not s.success?
        return o, s
    end

    def exec_remote(cmd)
        o, s = exec("ssh -i #{@private_key} #{@user}@#{@host} \"#{cmd}\" ")
        fail "Failed to exec cmd on remote server - #{@host}" if not s.success?
        o
    end

    def exec_local(cmd)
        o, s = exec(cmd)
        fail "Failed to exec cmd on local " if not s.success?
        o
    end

    def copy_to_remote(file)
        o, s = exec("scp -i #{@private_key} #{file} #{@user}@#{@host}:~")
        fail "Failed to copy file to remote sever - #{@host} " if not s.success?
        o
    end

end
