require 'rubygems'
require 'mechanize'
require 'pp'
require 'fileutils'
require 'open-uri'

class Downloader
  def initialize(options)
    @output = options[:folder]
    @url = options[:url]
    @logger = $stdout
  end

  def on_photo_saved(&block)
    @on_photo_saved = block
  end

  def download
    prepare_output

    a = Agent.new(@logger)

    photos = []
    a.get(@url) do |page|
      photos = page.search(".//img[@width='75'][@height='75']/..").map do |node|
        Photo.new(:details_url => node['href'], :agent => a)
      end
    end

    photos.each do |photo|
      save(photo)
      if @on_photo_saved
        @on_photo_saved.call(photo)
      end
    end
  end

  def prepare_output
    FileUtils.mkdir_p @output
  end

  def save(photo)
    @files_created_by_me ||= []

    target = File.join(@output, photo.name + '.' + photo.type)
    while @files_created_by_me.include? target
      i ||= 0
      i += 1
      target = File.join(@output, 
                         photo.name + ('_%0.3d' % i) + '.' + photo.type)
    end

    File.open(target, 'w') do |file|
      open(photo.url) do |image|
        file << image.read
      end
    end

    @files_created_by_me << target
  end
end


class Photo
  attr_accessor :id, :user_id,
                :title, 
                :details_url, :all_sizes_url, :url

  def initialize(options)
    if options[:details_url]
      self.details_url = options[:details_url]

      parts = details_url.split('/')
      self.user_id = parts[2]
      self.id = parts[3]
    end
    @agent = options[:agent]
  end

  def title
    @title ||= begin
      name = id

      @agent.get(details_url) do |page|
        title = page.search('#meta h1').first.text.strip

        name = title unless title.empty?
      end

      name
    end
  end

  def all_sizes_url
    @all_sizes_url ||= "/photos/#{user_id}/#{id}/sizes/sq/"
    @all_sizes_url ||= "/photos/#{user_id}/#{id}/sizes/o/"
  end

  def url
    @url || begin
      @agent.get(all_sizes_url) do |page|
        @url = page.search('#allsizes-photo img').first['src']
      end
      @url
    end
  end

  def name
    @name || begin
      @type = url.split('.').last
      @name = title.strip.gsub(/\s+/, '_').upcase
    end
  end

  def type
    @type || begin
      self.name
      @type
    end
  end
end

class Agent
  def initialize(logger)
    @mechanize = Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
    end
    @logger = logger
  end

  def get(*args, &block)
    # used to add logging at a later point
    @logger.puts 'Getting: ' + args.first
    @mechanize.get(*args, &block)
  end
end
