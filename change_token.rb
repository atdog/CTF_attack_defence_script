#!/usr/bin/env ruby

require "./Workstation"
require "digest"
require 'securerandom'

if __FILE__ == $0
    host = "10.113.208.209"


    sha256 = Digest::SHA256.new
    msg = SecureRandom.hex(1024)
    digest = sha256.digest msg
    token = digest.unpack("H*")[0]

    service = "user"
    service_flag = "/home/user/flag"

    w = Workstation.new(host, "root", "./id_rsa")
    w.exec_remote("echo #{token} > #{service_flag}")
    w.exec_remote("chown #{service}:#{service} #{service_flag}")
    w.exec_remote("chmod 700 #{service_flag}")

end
