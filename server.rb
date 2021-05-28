
require 'socket'
require 'digest'
include Socket::Constants


class Service
  attr_accessor :port

  def initialize(host='localhost',port=3000, max_con=5)
    @port = port
    @host = host
    @max_con = max_con
    @s_name = "tests"
    @key = "P93"
    @active_user = {}
  end

  def chech_protocol(data)
    if data.include? "@#{@s_name}?#{@key}:" and data.slice(0,5) == 'msg::'
      meta = data.split("::")
      name = meta[2]
      key = meta[3]
      if name != nil and key != nil
        return true,name,key
      end
    end
    return [false]
  end

  def threading_clint(inp, meta)
    inp.sendmsg "[success] You are now disconnected.\n"

    id = Digest::SHA1.hexdigest(rand.to_s)

    user_info = {
      "status":true,
      "socket":inp,
      "id": id,
      "name": meta[1],
      "key": meta[2]
    }

    @active_user[id] = user_info

    while true do
      begin
        data = inp.recv 1024
        #user_info[:socket].sendmsg data
        @active_user.keys.each do |u|
          if !@active_user[u]['status']
            begin
              @active_user[u][:socket].sendmsg(user_info[:name] +"=> "+ data)
            rescue Errno::EPIPE
              @active_user[u][:status] = false
            end
          end
        end
        if !@active_user[id][:status]
          break
        end
        inp.close
      rescue IOError
        break
      end
    end
  end


  def start

    s0cket_server = Socket::new(AF_INET, SOCK_STREAM)
    packed_addr = Socket::pack_sockaddr_in(@port, @host)
    s0cket_server.bind(packed_addr)
    s0cket_server.listen(@max_con)
    puts "[started]:: [#{@host}:#{@port}]-[msg::@#{@s_name}?#{@key}]"
    while true do
      clint, sock = s0cket_server.accept
      clint.sendmsg("[Connected] You are connected to #{@s_name}\n=> ")
      data = clint.recv(500).chomp
      check_result = chech_protocol(data)
      puts check_result

      if check_result[0]
        puts "[Connected]:: #{check_result[1]}@s_name"
        Thread.new{ threading_clint clint,check_result }
      else
        puts "[Fail]:: Authentication"
        clint.sendmsg("[Deny] Un authorized user\n")
        clint.close
      end
    end
  end
end


server = Service::new()
server.start
