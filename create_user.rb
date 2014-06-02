#!/usr/bin/env ruby

require "./mylib/Workstation"
require "./cleanup.rb"

# main
if __FILE__ == $0
    # 
    host = "10.113.208.209"
    user_key = "user@#{host}"
    w = Workstation.new(host, "root", "./id_rsa")

    puts "Clean up related data"
    cleanup

    puts "Create user: user"
    w.exec_remote("useradd -m user")

    puts "Generate SSH RSA key-pair"
    w.exec_local("ssh-keygen -t rsa -b 2048 -f ./user_keys/#{user_key} -N ''")

    puts "Copy public key to server - #{host} "
    w.copy_to_remote("./user_keys/#{user_key}.pub")

    puts "Move pulic key to authorized_keys"
    w.exec_remote("mkdir /home/user/.ssh")
    w.exec_remote("chown user:user /home/user/.ssh")
    w.exec_remote("chmod 700 /home/user/.ssh")
    w.exec_remote("mv '#{user_key}.pub' /home/user/.ssh/authorized_keys")
    w.exec_remote("chown user:user /home/user/.ssh/authorized_keys")
    w.exec_remote("chmod 644 /home/user/.ssh/authorized_keys")

    puts "Create service user: service1"
    w.exec_remote("useradd service1")
    puts "Done"
end
