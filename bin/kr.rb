#!/usr/bin/env ruby
$: << File.expand_path('../lib',File.dirname(__FILE__))
ENV.fetch('PL_IP')
require 'tvn_player'
puts "hi"

def fetch_all
  (4..7).each do |s| 
    TvnPlayer::Series.kuchenne_rewolucje(s).download!('/usb1/media/QUEUE/KR/')
  end
end

fetch_all
#t = 3.times.map { Thread.new { fetch_all } }

#t.each(&:join)
