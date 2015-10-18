require 'thread'
require_relative 'scraper'
require_relative 'state'
require_relative 'tumblr'

Thread.abort_on_exception=true

SLEEP_TIME = 5

puts "creating state"
state = State.new('./data.lmc')
puts "has state"

puts "callback: #{state['callback']}"
puts "domains: #{state['domains']}"


image_client = Tumblr::Image.new

puts "starting thread"
Thread.new do
  loop do
    puts "thread started"
    puts "sleeping"
    sleep SLEEP_TIME

    domains = state['domains']
    callback = state['callback']
    if domains.nil? || domains.empty?
      puts "no domains, halting"
      next
    end
    if callback.nil?
      puts "no callback, halting"
      next
    end

    sm = ScrapeMaster.new state['domains']
    puts "starting image details scraper"
    sm.start do |key, image_details|
      key = image_details[:key]
      if state[key] && state[key]["processed"]
        puts "has already been processed"
        true
      else
        state[key] = image_details.merge({ processed: false })
        ext = state[key]["ext"]
        data = image_client.download(state[key]["href"])
        begin
          puts "posting"
          rsp = HTTParty.post("#{callback}/#{key}.#{ext}", body: data)
          if rsp.code == 200
            puts "setting processed #{key}"
            state[key] = state[key].merge({ processed: true })
          else
            puts "bad response: #{rsp.code}, halting"
            false
          end
        rescue StandardError => ex
          puts "error posting: #{ex}, halting"
          false
        end
        true
      end
    end
    puts "done with scrape"
  end
end

require 'sinatra'

post '/set_callback' do
  callback = params[:callback].chomp
  puts "setting callback: #{callback}"
  state['callback'] = callback
  content_type :text
  "new callback: #{callback}"
end

post '/add_domain' do
  new_domain = params[:new_domain].chomp
  puts "adding domain: #{new_domain}"
  existing_domains = state['domains'] || []
  halt 409 if existing_domains.include? new_domain
  state["domains"] = existing_domains + [new_domain]
  content_type :text
  "success: added #{new_domain}\n\n#{state['domains'].join("\n")}"
end
