#!/usr/bin/env ruby

require "./mylib/Workstation"
require "./AdminConfig"

def cleanup
    # 
    challenger = AdminConfig.challenger
    host = "10.113.208.209"
    user_key = "#{challenger}@#{host}"
    w = Workstation.new(host, "root", AdminConfig.root_privatekey)

    begin
        puts "Remove user: #{challenger}"
        w.exec_remote("id #{challenger}")
        w.exec_remote("rm -rf /home/#{challenger}")
        w.exec_remote("deluser --remove-all-files #{challenger}")
        w.exec_local("rm -f ./user_keys/#{user_key}*")

        puts "Remove user: service1"
        w.exec_remote("id service1")
        w.exec_remote("deluser --remove-all-files service1")

        puts "Remove service"
        w.exec_remote("rm -f /etc/xinetd.d/*")
        puts w.exec_remote("service xinetd restart")
    rescue
    end
end

# main
if __FILE__ == $0
    puts "Clean up related data"
    cleanup
    puts "Done"
end
