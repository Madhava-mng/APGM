# read a character without pressing enter and without printing to the screen

class Getinput

  attr_accessor :value_

  def initialize
    @value_ = []
  end


  def read_char
    begin
      # save previous state of stty
      old_state = `stty -g`
      # disable echoing and enable raw (not having to press enter)
      system "stty raw -echo"
      c = STDIN.getc.chr
      # gather next two characters of special keys
      if(c=="\e")
        extra_thread = Thread.new{
          c = c + STDIN.getc.chr
          c = c + STDIN.getc.chr
        }
        # wait just long enough for special keys to get swallowed
        extra_thread.join(0.00001)
        # kill thread so not-so-long special keys don't wait on getc
        extra_thread.kill
      end
    rescue => ex
      puts "#{ex.class}: #{ex.message}"
      puts ex.backtrace
    ensure
      # restore previous state of stty
      system "stty #{old_state}"
    end
    return c
  end

  def show_single_key
    while true do
      c = read_char
      case c
      when "\r"
        puts "=> #{@value_.join}"
        return @value_.join
      when "\n"
        puts "=> #{@value_.join}"
        return @value_.join
      when "\t"
        @value_.append "    "
      when /^.$/
        @value_.append c
      when "\177"
        if @value_.length() > 0
            @value_.pop
        end
      end
    end
  end
end

while true do
  a = Getinput::new()
  puts a.show_single_key
end

=begin
    case c
    when " "
      print " "
    when "\t"
      print "   "
    when "\r"
      print "\n"
    when "\n"
      print "\n"
    when "\e"
      print ""
    when "\e[A"
      print ""
    when "\e[B"
      print ""
    when "\e[C"
      print "" # right
    when "\e[D"
      print "" # left
    when "\177"
      print "" # backspace
    when "\004"
      print "" # delet
    when /^.$/
      print "#{c}"
    else
      print "#{c}"
=end
