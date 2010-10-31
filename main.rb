require 'rubygems'
require 'mechanize'
require 'pp'
require 'fileutils'
require 'open-uri'

GUEST_PASS = 'http://flickr.com/gp/...' # insert the GuestPass you are
                                        # interested in 

OUTPUT = 'photos' # configure folder, where to store the images



def save_photo(name, url)
  FileUtils.mkdir_p(OUTPUT)

  type = url.split('.').last
  name = name.strip.gsub(/\s+/, '_').upcase

  target = File.join(OUTPUT, name + '.' + type)
  while File.exist? target
    i ||= 0
    i += 1
    target = File.join(OUTPUT, name + ('_%0.3d' % i) + '.' + type)
  end

  File.open(target, 'w') do |output|
    # Download image
    open(url) do |input|
      output << input.read
    end
  end
  print '.'
  $stdout.flush
end


a = Mechanize.new do |agent|
  agent.user_agent_alias = 'Mac Safari'
end

detailpage_urls = []

a.get(GUEST_PASS) do |page|
  detailpage_urls = page.search(".//img[@width='75'][@height='75']/..").map { |node| node['href'] }

end

detailpage_urls.each do |url|
  parts = url.split('/')
  user_id = parts[2]
  photo_id = parts[3]

  name = photo_id

  a.get(url) do |page|
    title = page.search('#meta h1').first.text.strip

    name = title unless title.empty?
  end

  photo_page_url = "/photos/#{user_id}/#{photo_id}/sizes/o/"

  a.get(photo_page_url) do |page|
    photo_url = page.search('#allsizes-photo img').first['src']

    save_photo(name, photo_url)
  end

  puts
end
