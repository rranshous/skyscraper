require_relative 'tumblr'

class ScrapeMaster
  def initialize domains
    @domains = domains
  end
  def start &callback
    puts "starting scrape master: #{@domains}"
    @domains.each do |domain|
      scraper = Scraper.new domain
      scraper.start(&callback)
    end
    puts "done scrape master"
  end
end

def log *args
  puts(*args)
end

class Scraper
  def initialize domain
    @domain = domain
    @callback = nil
    @full_scrape = false
  end

  def start &callback
    puts "starting scraper for: #{@domain}"

    blog_href = @domain
    log "finding posts: #{blog_href}"

    blog_client = Tumblr::Blog.new
    post_client = Tumblr::Post.new

    blog_client.find_posts(blog_href)
    .lazy.map do |post_details|
      log "detailing: POST:#{post_details[:href]}"
      details = post_client.detail(post_details[:href])
      if details
        details.merge({ page_number: post_details[:page_number] })
      else
       nil
      end
    end
    .reject(&:nil?).map do |full_post_details|
      log "finding images: POST:#{full_post_details[:href]}"
      post_client.find_images(full_post_details).reverse_each
    end
    .flatten.reject(&:nil?)
    .map do |image_details|
      href = image_details[:href]
      ext = href.split('.').last
      key = "image_#{Base64.urlsafe_encode64(href)}"
      image_details = image_details.merge({
        ext: ext,
        key: key
      })
      continue = callback.call(key, image_details)
      return unless continue
      image_details
    end
    .to_a
    #.map do |image_details|
    #  key = image_details[:key]
    #  if @state[key]["processed"]
    #    unless @full_scrape
    #      puts "done, found already downloaded image"
    #      break
    #    end
    #    puts "not redownloading"
    #    image_details
    #  else
    #    log "downloading: IMAGE:#{image_details[:href]} " \
    #        ":: #{image_details[:post][:href]}"
    #    image_details.merge({
    #      data: image_client.download(image_details[:href])
    #    })
    #  end
    #end
    #.reject(&:nil?).map do |image_details_with_data|
    #  if image_details_with_data[:data].nil?
    #    puts "Error: download data is nil"
    #    next
    #  end
    #  key = image_details_with_data[:key]
    #  callback.call(key, image_details_with_data)
    #  #href = image_details_with_data[:href]
    #  #ext = href.split('.').last
    #  #file_path = "#{OUTDIR}/#{Base64.urlsafe_encode64(href)}.#{ext}"
    #  #unless File.exists? file_path
    #  #  log "writing [#{image_details_with_data[:data].length}\: #{file_path}"
    #  #  File.write file_path, image_details_with_data[:data]
    #  #end
    #  #meta_path = "#{file_path}.meta"
    #  #unless File.exists? meta_path
    #  #  log "writing meta"
    #  #  meta = image_details_with_data.dup
    #  #  meta.delete(:data)
    #  #  File.write meta_path, meta.to_json
    #  #end
    #  #file_path
    #  image_details_with_data
    #end.each do |data|
    #  puts "callback: #{data[:href]} successfully"
    #end
    puts "done scraping: #{blog_href}"
  end
end


module Enumerable
  def flatten
    Enumerator.new do |yielder|
      each do |element|
        if element.is_a? Hash
          yielder << element
        elsif element.is_a? Enumerable
          element.each do |e|
            yielder.yield(e)
          end
        else
          yielder.yield(element)
        end
      end
    end.lazy
  end
end

