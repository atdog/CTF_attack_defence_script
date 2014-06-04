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
        w.exec_remote("id #{challenger}")

        puts "Remove user from sudoers"
        w.exec_remote("sed -E '/#{challenger}\\sALL/d' -i /etc/sudoers")
        w.exec_remote("sed -E '/Cmnd_Alias XINETD/d' -i /etc/sudoers")

        puts "Remove user: #{challenger}"
        w.exec_remote("rm -rf /home/#{challenger}")
        w.exec_remote("deluser --remove-all-files #{challenger} 2>/dev/null")
        w.exec_local("rm -f ./user_keys/#{user_key}*")

        service_name = "service1"
        puts "Remove user: #{service_name}"
        w.exec_remote("id #{service_name}")
        w.exec_remote("deluser --remove-all-files #{service_name} 2>/dev/null")

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
