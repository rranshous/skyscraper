require_relative 'state'
require_relative 'background'

require 'thread'
Thread.abort_on_exception = true

# create persistant state
state_path = File.join((ENV['DATA_DIR'] || './data'), 'skyscraper.lmc')
state = State.new(state_path)

background_thread = nil
begin

  # startup the background work
  puts "starting background work"
  background_thread = Thread.new do
    background_loop state
  end

  # setup http front end
  require_relative 'http'
  puts "starting http front end"
  http_interface state

ensure
  puts "stopping background thread"
  background_thread.kill
end

puts "done in main"
