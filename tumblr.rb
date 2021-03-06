require 'uri'
require 'feedjira'
require 'httparty'

module Tumblr
  class Blog
    include HTTParty

    def find_posts blog_href
      Enumerator.new do |yielder|
        page_urls(blog_href).each do |page_number, page_url|
          puts "page: #{page_url}"
          page_data = self.class.get(page_url).body
          begin
            feed = Feedjira::Feed.parse(page_data)
          rescue Feedjira::NoParserAvailable
            break
          end
          if feed.is_a?(Fixnum)
          else
            if feed.entries.length == 0
              next
            end
            feed.entries.each do |entry|
              post_data = {
                :href => entry.url,
                :page_number => page_number,
                :blog => { :href => feed.url },
              }
              yielder << post_data
            end
          end
        end
      end
    end
    private
    def url_join *args
      args.map { |arg| arg.gsub(%r{^/*(.*?)/*$}, '\1') }.join("/")
    end
    def page_urls blog_href
      Enumerator.new do |yielder|
        puts "page_urls: #{blog_href}"
        10.downto(2).each do |page_number|
          yielder << [page_number,
                      url_join(blog_href,'/page/',"/#{page_number}/",'rss').to_s]
        end
        yielder << [1, "#{blog_href}/rss"]
      end
    end
  end
  class Post
    include HTTParty

    def detail post_href
      begin
        response = self.class.get("#{post_href}/xml",
                                  headers: {'Accept'=>'application/xml'})
      rescue SocketError, Net::ReadTimeout
        retry
      end
      post_data = response.parsed_response
      unless post_data.is_a? Hash
        return nil
      end
      return { href: post_href }.merge post_data
    end
    def find_images post_data
      post_href = post_data[:href]
      Enumerator.new do |yielder|
        post_type = post_data["tumblr"]["posts"]["post"]["type"]
        if post_type == "photo"
          if photoset_data = post_data['tumblr']['posts']['post']['photoset']
            puts "MANY PHOTOS"
            photoset_data['photo'].each do |photo_data|
              photo_data = main_photo_data post_href, photo_data['photo_url']
              yielder << photo_data
            end
          else
            photo_data = main_photo_data post_href,
                                 post_data['tumblr']['posts']['post']['photo_url']
            yielder << photo_data
          end
        end
      end
    end
    private
    def main_photo_data post_href, photos_data
      image_versions = Hash[
        #post_data["tumblr"]["posts"]["post"]["photo_url"]
        photos_data
        .map{|d| [d["max_width"].to_i, d["__content__"]] }
      ]
      width, url = image_versions.first
      return {
        post_href: post_href,
        href: url,
        width: width,
        post: { href: post_href }
      }
    end
  end
  class Image
    include HTTParty

    def download image_href
      begin
        response = self.class.get(image_href)
      rescue SocketError, Net::ReadTimeout
        retry
      end
      response.parsed_response
    end
  end
end
