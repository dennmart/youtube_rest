#!/usr/bin/env ruby

require 'rubygems'
require 'youtube'

youtube = YouTube::Client.new 'DEVELOPER_ID' # Get one here: <http://youtube.com/my_profile_dev>. 

profile = youtube.profile('br0wnpunk')
puts "age: " + profile.age.to_s

favorites = youtube.favorite_videos('br0wnpunk')
puts "number of favorite videos: " + favorites.size.to_s

friends = youtube.friends('paolodona')
puts "number of friends: " + friends.size.to_s
puts "friend name: " + friends.first.user

videos = youtube.videos_by_tag('iron maiden')
puts "number of videos by tag iron maiden: " + videos.size.to_s

videos = youtube.videos_by_user('whytheluckystiff')
puts "number of videos by why: " + videos.size.to_s
puts "title: " + videos.first.title

videos = youtube.featured_videos
puts "number of featured videos: " + videos.size.to_s
puts "title: " + videos.first.title
puts "url: " + videos.first.url
puts "embed url: " + videos.first.embed_url
puts "embed html: \n" + videos.first.embed_html

details = youtube.video_details(videos.first.id)
puts "detailed description: " + details.description
puts "thumbnail url: " + details.thumbnail_url
