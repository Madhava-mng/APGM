require 'io/console'


class Gen
  attr_accessor :name,:passwd,:info,:host,:port,:pub_key

  def get_passprase

    print "password-for-cert: ⚷"
    tmp_pass = STDIN.noecho(&:gets).chomp
    print "retype-password: ⚷"

    if tmp_pass == STDIN.noecho(&:gets).chomp
      puts "[Success] Don't forgot It. clint can't connect without password.\n"

      if tmp_pass.length == 0:
          tmp_pass = "secret_apgm"
      end

      return tmp_pass
    else
      puts "[Error]  Password not match. please try again.\n"
      return get_pass
    end

  end

  def initialize

    # inputs

    print "Group-Name: "
    name = gets.chomp.strip

    print "Group-Info: "
    info = gets.chomp.strip

    print "port [3050]: "
    port = gets.chomp.strip

    @passwd = get_passprase

    if info == ""
      @info = "APGM hosted @#{name.strip}"
    else
      @info = info
    end
    
    @name = name

    if port.to_i != 0 and port.to_i < 1200
      @port = port
    else
      @port = 3050
    end

    puts "Group-Name: #{@name}"
    puts "Group-Info: #{@info}"
    puts "Group-Port: #{@port}"
    puts "Group-Host: #{@host}"
    puts "Group-Password: #{'*' * @passwd.length}"


    # confirm user
    
    if ['y', 'yes'].include? gets.chomp.strip

    else
      exit
    end

    


  end

  def creat

    # skeleton

    buffer = ""

    buffer += "SERVER_NAME=#{@name}\n"
    buffer += "SERVER_KEY=#{@pub_key}\n"
    buffer += "SERVER_INFO=#{@info}\n"
    buffer += "SERVER_HOST=#{@host}\n"
    buffer += "SERVER_PORT=#{@port}\n"


    if Process::uid == 0

      if File.exist?("/etc/tor")
        # write fifo

        Thread::new {
          File.open("crypto/cert", "w") do |f|
            f.write(buffer)
          end
        }

        # rewrite /etc/tor/torrc
        # backup too

        system "cp /etc/tor/torrc /etc/tor/torrc.backup 2>/dev/null"
        system "cp /etc/tor/torrc.sample /etc/tor/torrc.sample.backup 2>/dev/null"

        if File.file? ("/etc/tor/torrc")
          File.open("/etc/tor/torrc","a") do |f|
            f.write("%include /etc/tor/#{@name}}\n")
          end

        elsif File.file? ("/etc/tor/torrc.sample")
          File.open("/etc/tor/torrc.sample", "a") do |f|
            f.write("%include /etc/tor/#{@name}}\n")
          end
        
        else
          print "[help] Unable to locate torrc file.\nIt inside /etc/tor/<file>\n"
          print "please enter full path for the configaration file: "
          path = gets.chomp

          if File.file? (path)
            File.open(path, "a") do |f|
              f.write("%include /etc/tor/#{@name}}\n")
            end
          else
            print "[Error] Given path '#{@path}' is not exist.\n"
            print "do some enumeration on '/etc/tor/' and try again.\n"
            exit
          end
        end

        # write configaration file

        File.open("/etc/tor/#{@name}", "w") do |f|
          data = "HiddenServiceDir /var/lib/tor/apgm/#{@name}/\n"
          data += "HiddenServicePort #{@port} 127.0.0.1:#{@port}\n"
          f.write(data)
        end




        # read fifo on shell

        system "cat crypto/cert | openssl aes-192-cbc -k #{@passwd} -iter 519 |base64 > certs/server/#{@name}.apgm"

        if File.file?("certs/server/#{@name}.apgm")
          puts "[Saved] to certs/server/#{@name}.apgm"

          File.open("certs/server/plain/#{@name}.apgm", "w") do |f|
            f.write(buffer)
          end
        else
          puts "[Error] certificate not created."
        end
        
      else
        puts "[Error] unable to locate file /etc/tor/torrc"
      end

    else
      puts "[Error] please run as 'root'"
      puts "Previlage need to access:"
      puts "\t+ /var/lib/tor/\n\t+ /etc/tor/torrc"
    end





  end

end
