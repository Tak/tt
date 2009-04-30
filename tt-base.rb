#!/usr/bin/env ruby

class TopicToolBase
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
end # TopicToolBase

if (__FILE__ == $0)
  require 'test/unit'

  class TopicToolBaseTest < Test::Unit::TestCase
    def setup()
      @tt = TopicToolBase.new()
    end # setup

    def test_append()
      blurbs = [ ['foo','foo'],
                ['bar','foo | bar'],
                ['baz','foo | bar | baz'],
                ['meh','foo | bar | baz | meh'],
                ['xyzzy','foo | bar | baz | meh | xyzzy'],
                ['AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','xyzzy | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA']
               ]
                
      blurbs.inject(''){ |accum,pair|
        new_topic = @tt.generate_topic(pair[0], accum, '#test')
        assert_equal(pair[1], new_topic)
        new_topic
      }
    end # test_append

    def test_undo()
      topic = 'foo | bar | baz | meh | xyzzy'
      blurbs = [ [1, 'foo | bar | baz | meh'],
                 [2, 'foo | bar' ],
                 [5, '.'],
                 [0, nil ],
                 [-1, nil ]
               ]

      blurbs.inject(topic){ |accum,pair|
        newtopic = @tt.undo_blurbs(pair[0], accum)
        assert_equal(pair[1], newtopic)
        newtopic
      }
    end # test_undo
  end # TopicToolBaseTest
end
