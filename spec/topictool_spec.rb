require 'topictool'

RSpec.describe Topictool do
  before(:all) do
    @tt = TopicTool::TopicTool.new()
  end

  it 'has a version number' do
    expect(Topictool::VERSION).not_to be nil
  end

  it 'appends to the topic following the correct format' do
    blurbs = [ ['foo','foo'],
               ['bar','foo | bar'],
               ['baz','foo | bar | baz'],
               ['meh','foo | bar | baz | meh'],
               ['xyzzy','foo | bar | baz | meh | xyzzy'],
               ['AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA','xyzzy | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA']
    ]

    blurbs.inject(''){ |accum,pair|
      new_topic = @tt.generate_topic(pair[0], accum, '#test')
      expect(new_topic).to eq(pair[1])
      new_topic
    }
  end

  it 'correctly undoes append operations' do
    topic = 'foo | bar | baz | meh | xyzzy'
    blurbs = [ [1, 'foo | bar | baz | meh'],
               [2, 'foo | bar' ],
               [5, '.'],
               [0, nil ],
               [-1, nil ]
    ]

    blurbs.inject(topic){ |accum,pair|
      newtopic = @tt.undo_blurbs(pair[0], accum)
      expect(newtopic).to eq(pair[1])
      newtopic
    }
  end
end
