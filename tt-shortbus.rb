#!/usr/bin/env ruby

require 'shortbus'
require 'tt-base'

# Plugin for auto-rotating a |-delimited topic based on a given topic length
class TopicTool < ShortBus

  def initialize
    super
    @tt= TopicToolBase.new()
    @plugin_name = "\x0311TopicTool\x0F"
    @help_text = <<EOT

    #{@plugin_name} -- a topic mangling plugin for XChat
    Available commands:

    length            -- return current length of topic
    append <blurb>    -- appends <blurb> to |-delimited topic
    undo <number>     -- removes N |-delimited blurbs from the end of the topic
    preserve <number> -- preserves the first N |-delimited blurbs for the current channel
    test              -- prints a dry run of the appended topic
    accept            -- commits a tested topic
    quote <nick>      -- appends nick's last statement and tests
EOT
    @ACTION = /^\001ACTION.*\001/
    @pending = ''

    hook_command('TT', XCHAT_PRI_NORM, method( :tt_handler), @help_text)
    hook_server('PRIVMSG', XCHAT_PRI_NORM, method(:buffer_message))
    hook_print('Your Message', XCHAT_PRI_NORM, method(:your_message))

    debug('Loaded.')
  end

  def debug(message)
    puts("TopicTool: #{message}")
  end

  # Handler for TT commands
  # * words is each word in the command 
  #  * words[0] = 'TT'
  #  * words[1] = the command
  #  * words_eol[2] = hopefully, the string to be appended to the topic
  def tt_handler(words, words_eol, data)
    cmd = words[1]
    if(cmd)
      case cmd.downcase
        when 'length' then
          return print_topic_length
        when 'append' then
          return append_blurb(words_eol[2])
	when 'preserve' then
	  begin
	    channel = get_info('channel')
	    debug("Preserving #{@tt.preserve_blurbs(channel, words_eol[2].to_i())} blurbs for #{channel}.")
	  rescue
	    debug('Error setting preservation count')
	  end
	  return XCHAT_EAT_ALL
	when 'undo' then
	  begin
	    set_topic(@tt.undo_blurbs(words_eol[2].to_i(), get_topic()))
	  rescue
	    debug('Error undoing blurbs')
	  end
	  return XCHAT_EAT_ALL
    when 'test' then
      print_test(words_eol[2])
      return XCHAT_EAT_ALL
    when 'accept' then
      if(@pending) then set_topic(@pending); end
      return XCHAT_EAT_ALL
    when 'quote' then
      quote(words_eol[2].gsub(/[|\s]/,''))
      return XCHAT_EAT_ALL
      end
    end

    puts(@help_text)

    return XCHAT_EAT_ALL
  end

  def set_topic(topic)
    command("TOPIC #{topic}")
    @pending = nil
  end

  def get_topic
    return get_info('topic')
  end

  def print_topic_length
    debug("Topic length: #{get_topic().length}")

    return XCHAT_EAT_ALL
  end

  # Appends a string to the channel topic
  def append_blurb(blurb)
    # Set new topic
    if((topic = @tt.generate_topic(blurb, get_topic(), get_info('channel'))))
      set_topic(topic)
    end

    return XCHAT_EAT_ALL
  end


  def print_test(blurb)
    @pending = @tt.generate_topic(blurb, get_topic(), get_info('channel'))
    debug(@pending)
  end

  def buffer_message(words, words_eol, data)
    mynick = words[0].sub(/^:([^!]*)!.*/,'\1').gsub(/\|/, '')
    channel = words[2]

    # Strip intermittent trailing @ word
    if(words.last == '@')
      words.pop()
      words_eol.collect!{ |w| w.gsub(/\s+@$/,'') }
    end

    if(3<words_eol.size)
        sometext = words_eol[3].sub(/^:/,'')
    end
    if(!sometext || @ACTION.match(sometext)) then return nil; end

    storekey = "#{mynick}|#{channel}"
    @tt.store(storekey, "<#{mynick}> #{sometext}")
  end

  def your_message(words, data)
    begin
      words_eol = []
      # Build an array of the format process_message expects
      newwords = [words[0], 'PRIVMSG', get_info('channel')] + (words - [words[0]]) 
      
      #puts("Outgoing message: #{words.join(' ')}")
      
      # Populate words_eol
      1.upto(newwords.size){ |i|
        words_eol << (i..newwords.size).inject(''){ |str, j|
          "#{str}#{newwords[j-1]} "
        }.strip()
      }
      
      buffer_message(newwords, words_eol, data)
    rescue
      # puts($!)
    end
  end

  def quote(nick)
    storekey = "#{nick}|#{get_info('channel')}"
    message = @tt.retrieve(storekey)
    if(message) 
      print_test(message)
    else
      debug("No statement stored for #{storekey}")
    end
  end
end # TopicTool

if (__FILE__ == $0)
	blah = TopicTool.new()
	blah.run()
end
