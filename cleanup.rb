#!/usr/bin/env ruby

require "./mylib/Workstation"

def cleanup
    # 
    host = "10.113.208.209"
    user_key = "user@#{host}"
    w = Workstation.new(host, "root", "./id_rsa")

    begin
        puts "Remove user: user"
        w.exec_remote("id user")
        w.exec_remote("rm -rf /home/user")
        w.exec_remote("deluser --remove-all-files user")
        w.exec_local("rm -f ./user_keys/#{user_key}*")

        puts "Remove user: service1"
        w.exec_remote("id service1")
        w.exec_remote("deluser --remove-all-files service1")
    rescue
    end
end

# main
if __FILE__ == $0
    puts "Clean up related data"
    cleanup
    puts "Done"
end
