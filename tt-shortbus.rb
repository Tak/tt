#!/usr/bin/env ruby

require 'shortbus'

# Plugin for auto-rotating a |-delimited topic based on a given topic length
class TopicTool < ShortBus

  def initialize
    super
    @plugin_name = "\x0311TopicTool\x0F"
    @help_text = <<EOT

    #{@plugin_name} -- a topic mangling plugin for XChat
    Available commands:

    length            -- return current length of topic
    append <blurb>    -- appends <blurb> to |-delimited topic
    undo <number>     -- removes N |-delimited blurbs from the end of the topic
    preserve <number> -- preserves the first N |-delimited blurbs for the current channel
EOT
    @preserve = {}

    hook_command('TT', XCHAT_PRI_NORM, method( :tt_handler), @help_text)
    @max_len = 307

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
	    preserve_blurbs(words_eol[2].to_i())
	  rescue
	    debug('Error setting preservation count')
	  end
	  return XCHAT_EAT_ALL
	when 'undo' then
	  begin
	    undo_blurbs(words_eol[2].to_i())
	  rescue
	    debug('Error undoing blurbs')
	  end
	  return XCHAT_EAT_ALL
      end
    end

    puts(@help_text)

    return XCHAT_EAT_ALL
  end

  # Removes num blurbs from the end of the current topic
  def undo_blurbs(num)
    if(!num || (num <= 0)) then return; end

    t = get_topic().split('|').collect{|x| x.strip()}
    t = ((num >= t.length) ? ['.'] : t[0,t.length-num])
    command("TOPIC #{t.join(' | ')}")
  end

  # Preserves num blurbs for the current channel
  def preserve_blurbs(num)
    if(num < 0) then num = 0; end
    channel = get_info('channel')
    @preserve[channel] = num
    debug("Preserving #{@preserve[channel]} blurbs for #{channel}.")

    return XCHAT_EAT_ALL
  end

  # Appends a string to the channel topic
  def append_blurb(blurb)
    if(!blurb || 1 > blurb.length) then return XCHAT_EAT_ALL; end

    # Tokenize the topic and add the new string
    t = get_topic.split('|').collect{|x| x.strip}
    t << blurb

    # Preserve the to-be-preserved blurbs
    count = @preserve[get_info('channel')]
    p = (count ? t.slice!(0, count) : [])

    # Trim tokens from the front until we're under the max length
    while (p + t).join(' | ').length > @max_len
      t.shift
    end

    # Set new topic
    if t.length > 0
      new_topic = (p + t).join(' | ')
      command("TOPIC #{new_topic}")
    end

    return XCHAT_EAT_ALL
  end

  def get_topic
    return get_info('topic')
  end


  def print_topic_length
    debug("Topic length: #{get_topic.length}")

    return XCHAT_EAT_ALL
  end
end # TopicTool

if (__FILE__ == $0)
	blah = TopicTool.new()
	blah.run()
end
