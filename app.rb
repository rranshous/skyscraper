require 'sinatra'
require_relative 'scraper'
require_relative 'state'
require_relative 'tumblr'

require_relative 'background'

puts "creating state"
state_path = File.join((ENV['DATA_DIR'] || './data'), 'skyscraper.lmc')
state = State.new(state_path)
puts "has state"

post '/set_callback' do
  callback = params[:callback].chomp
  puts "setting callback: #{callback}"
  state['callback'] = callback
  content_type :text
  redirect '/'
end

post '/add_domain' do
  new_domain = params[:new_domain].chomp
  puts "adding domain: #{new_domain}"
  existing_domains = state['domains'] || []
  halt 409 if existing_domains.include? new_domain
  state["domains"] = existing_domains + [new_domain]
  redirect '/'
end

post '/remove_domain' do
  to_remove = params[:domain].chomp
  puts "removing: #{to_remove}"
  existing_domains = state['domains'] || []
  halt 409 unless existing_domains.delete to_remove
  state['domains'] = existing_domains
  redirect '/'
end

get '/' do
  erb :index, locals: { state: state }
end

puts "starting background work"
background_loop state

