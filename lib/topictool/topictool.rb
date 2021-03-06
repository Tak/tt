#!/usr/bin/env ruby

module TopicTool
  class TopicTool
    def initialize
      @preserve = {}
      @statements = {}
      @max_len = 307
    end # initialize

    # Removes num blurbs from the end of the current topic
    # and returns the resultant topic
    def undo_blurbs(num, current_topic)
      if(!num || (num <= 0)) then return; end

      t = current_topic.split('|').collect{|x| x.strip()}
      t = ((num >= t.length) ? ['.'] : t[0,t.length-num])
      return t.join(' | ')
    end

    # Generates a new topic with a blurb appended
    def generate_topic(blurb, current_topic, channel)
      if(!blurb || 1 > blurb.length) then return nil; end

      # Tokenize the topic and add the new string
      t = current_topic.split('|').collect{|x| x.strip}
      t << blurb

      # Preserve the to-be-preserved blurbs
      count = @preserve[channel]
      p = (count ? t.slice!(0, count) : [])

      # Trim tokens from the front until we're under the max length
      while (p + t).join(' | ').length > @max_len
        t.shift
      end

      if t.length > 0
        return (p + t).join(' | ')
      end

      return nil
    end

    # Preserves num blurbs for the current channel
    def preserve_blurbs(channel, num)
      if(num < 0) then num = 0; end
      @preserve[channel] = num
    end

    # Store a message in the buffer
    def store(key, message)
      @statements[key] = message
    end # store

    # Retrieve a message from the buffer
    def retrieve(key)
      return @statements[key]
    end # retrieve
  end # TopicTool
end # TopicTool
