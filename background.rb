require_relative 'scraper'
require_relative 'tumblr'

SLEEP_TIME = (ENV['SLEEP_TIME'] || 60 * 5).to_i

def background_loop state

  puts "callback: #{state['callback']}"
  puts "domains: #{state['domains']}"
  puts "starting thread"

  image_client = Tumblr::Image.new
  initial = true

  loop do

    unless initial #ugh
      puts "sleeping for #{SLEEP_TIME}s"
      sleep SLEEP_TIME
    end
    initial = false

    state['last_error'] = nil
    puts "thread started"

    domains = state['domains']
    callback = state['callback']
    if domains.nil? || domains.empty?
      puts "no domains, halting"
      state['last_error'] = "no domains set"
      next
    end
    if callback.nil?
      puts "no callback, halting"
      state['last_error'] = "no callback set"
      next
    end

    sm = ScrapeMaster.new state['domains']
    puts "starting image details scraper"
    sm.start do |key, image_details|
      if state[key] && state[key]["processed"]
        puts "has already been processed"
        true
      else
        state[key] = image_details.merge({ processed: false })
        ext = state[key]["ext"]
        data = image_client.download(state[key]["href"])
        begin
          puts "posting"
          post_domain = URI(image_details[:post_href]).host
          rsp = HTTParty.post("#{callback}/#{post_domain}-#{key}.#{ext}", body: data)
          if rsp.code == 200
            puts "setting processed #{key}"
            state[key] = state[key].merge({ processed: true })
          else
            puts "bad response: #{rsp.code}, halting"
            state['last_error'] = "Bad HTTP Response: #{rsp.code}"
            false
          end
        rescue StandardError => ex
          puts "error posting: #{ex}, halting"
          state['last_error'] = "Runtime Error: #{ex}"
          false
        end
        true
      end
    end
    puts "done with scrape"
  end
end
