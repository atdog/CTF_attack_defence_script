#!/usr/bin/env ruby

require "./mylib/Workstation"
require "./AdminConfig"
require "./cleanup"

# main
if __FILE__ == $0
    # 
    challenger = AdminConfig.challenger
    host = "10.113.208.209"
    user_key = "#{challenger}@#{host}"
    w = Workstation.new(host, "root", AdminConfig.root_privatekey)

    puts "Clean up related data"
    cleanup

    puts "Create user: #{challenger}"
    w.exec_remote("useradd -m #{challenger}")

    puts "Generate SSH RSA key-pair"
    w.exec_local("ssh-keygen -t rsa -b 2048 -f ./user_keys/#{user_key} -N ''")

    puts "Copy public key to server - #{host} "
    w.copy_to_remote("./user_keys/#{user_key}.pub")

    puts "Move pulic key to authorized_keys"
    w.exec_remote("mkdir /home/#{challenger}/.ssh")
    w.exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/.ssh")
    w.exec_remote("chmod 700 /home/#{challenger}/.ssh")
    w.exec_remote("mv '#{user_key}.pub' /home/#{challenger}/.ssh/authorized_keys")
    w.exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/.ssh/authorized_keys")
    w.exec_remote("chmod 644 /home/#{challenger}/.ssh/authorized_keys")

    puts "Setup sudoers"
    w.exec_remote("echo 'Cmnd_Alias XINETD = /usr/sbin/service xinetd restart' >> /etc/sudoers")
    w.exec_remote("echo '#{challenger} ALL=(root) NOPASSWD: XINETD' >> /etc/sudoers")

    puts "Create service user: service1"
    w.exec_remote("useradd service1")
    puts "Done"
end
