
require "sinatra/base"

class MyApp < Sinatra::Base
  post '/set_callback' do
    callback = params[:callback].chomp
    puts "setting callback: #{callback}"
    settings.state['callback'] = callback
    content_type :text
    redirect '/'
  end

  post '/add_domain' do
    new_domain = params[:new_domain].chomp
    puts "adding domain: #{new_domain}"
    existing_domains = settings.state['domains'] || []
    halt 409 if existing_domains.include? new_domain
    settings.state["domains"] = existing_domains + [new_domain]
    redirect '/'
  end

  post '/remove_domain' do
    to_remove = params[:domain].chomp
    puts "removing: #{to_remove}"
    existing_domains = settings.state['domains'] || []
    halt 409 unless existing_domains.delete to_remove
    settings.state['domains'] = existing_domains
    redirect '/'
  end

  get '/' do
    erb :index, locals: { state: settings.state }
  end
end

def http_interface state
  MyApp.set :state, state
  puts "running sinatra app"
  MyApp.run!
  puts "done running app"
end
