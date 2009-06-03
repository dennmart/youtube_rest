require 'rubygems'
require 'test/unit'
require 'youtube'
require 'pp'
require 'yaml'
require 'set'

# This test class assumes an active internet connection
class TestAPI < Test::Unit::TestCase
  @@DEVELOPER_API_KEY = 'RCofu-vAmeY'
  YOUTUBE_LIB_USERID = 'ytlibtest'

  def setup
    @client = YouTube::Client.new @@DEVELOPER_API_KEY
  end

  # test to ensure escaping strange characters like ampersands works
  # properly as we've been bitten by finding that they don't
  def test_videos_by_tag_escape
    videos = @client.videos_by_tag('cindy & margolis')
    _test_video_list(videos)
  end

  def test_profile
    profile = @client.profile('nutria42')

    assert_kind_of YouTube::Profile, profile
    assert_not_nil profile
    assert (profile.age >= 33)
    assert (profile.gender == 'm')
    assert (profile.country == 'US')
  end

  def test_favorite_videos
    favorites = @client.favorite_videos('br0wnpunk')

    # make sure we got some favorites
    assert_not_nil favorites
    assert (favorites.length > 0)

    # pull out one to scrutinize
    sample = favorites.first
    _test_video(sample)
    
    # user doesn't exist / test exception handling
    assert_raise RuntimeError do
      favorites = @client.favorite_videos('dsfa98sd7fa9s8d7fd8')
    end
  end

  def test_friends
    friends = @client.friends('paolodona')

    # make sure we got some friends
    assert_not_nil friends
    assert (friends.length > 0)

    # pull one out to scrutinize
    sample = friends.first
    assert_kind_of YouTube::Friend, sample

    # sanity-check some attributes to make sure we parsed properly
    assert (sample.favorite_count > 0)
    assert (sample.friend_count > 0)
    assert (sample.user && sample.user.length > 0)
  end

  def test_videos_by_tag
    # test case where videos exist
    videos = @client.videos_by_tag('iron maiden')
    _test_video_list(videos)
    videos = @client.videos_by_tag('caffe trieste')
    _test_video_list(videos)

    # test case where no videos exist
    videos = @client.videos_by_tag('u423oi4j23oi4j234io')
    assert_nil videos
  end

  def test_videos_by_user
    # test case where videos exist
    videos = @client.videos_by_user('whytheluckystiff')
    _test_video_list(videos)    
  end
  
  def test_should_return_10_videos_for_user
    videos = @client.videos_by_user(YOUTUBE_LIB_USERID)
    _test_video_list(videos)

    assert_equal 10, videos.length
    videos_seen = Set.new
    videos.each do |video|
      _validate_test_video(video, videos_seen)
    end
  end
  
  def test_should_paginate_videos_by_user
    total_videos = 10
    expected_page_size = 3
    videos_seen = Set.new
    1.upto(4) do |index|
     videos = @client.videos_by_user(YOUTUBE_LIB_USERID, index, expected_page_size)
     _test_video_list(videos)
     expected_video_count = total_videos > expected_page_size ? expected_page_size : total_videos
     assert_equal expected_video_count, videos.length
     videos.each do |video|
       _validate_test_video(video, videos_seen)
     end
     total_videos -= expected_page_size
    end    
  end

  def test_videos_by_related
    videos = @client.videos_by_related('squats')
    _test_video_list(videos)
  end
  
  def test_videos_by_playlist
    videos = @client.videos_by_playlist('4009D81B1E0277A1')
    _test_video_list(videos)
  end
  
  def test_videos_by_category_id_and_tag
    videos = @client.videos_by_category_id_and_tag(17, 'bench')
    _test_video_list(videos)
  end
  
  def test_videos_by_category_and_tag
    videos = @client.videos_by_category_and_tag(YouTube::Category::SPORTS, 'bench')
    _test_video_list(videos)
  end
  
  def test_should_not_return_any_videos_for_videos_by_category_and_tag
    videos = @client.videos_by_category_and_tag(YouTube::Category::SPORTS, 'somerandomtagthatihopedoesntexist')
    assert_nil videos
  end
  
  def test_should_get_comment_count_for_video
    videos = @client.videos_by_tag('imogen heap hide and seek')
    video = videos.sort{ |a,b| b.view_count <=> a.view_count }.first
    assert video.comment_count > 0
  end

  def test_featured_videos
    videos = @client.featured_videos
    _test_video_list(videos)
  end

  def test_video_details
    videos = @client.featured_videos
    _test_video_list(videos)

    videos.each do |video|
      details = @client.video_details(video.id)

      assert_not_nil details
      assert_kind_of YouTube::VideoDetails, details
      assert (details.author && details.author.length > 0)
      assert (details.length_seconds > 0)
      assert (details.title && details.title.length > 0)
      assert_instance_of String, details.description
      assert details.embed_allowed if details.embed_status == "ok"
      assert !details.embed_allowed if details.embed_status == "not allowed"
    end

    # make sure parameter validation is operating correctly
    assert_raise ArgumentError do
      @client.video_details(5)
    end
  end

  def test_embed_html
    videos = @client.videos_by_tag('iron maiden')
    sample_video = videos.first

    embed_html = sample_video.embed_html
    embed_url = sample_video.embed_url

    # make sure embed url is present twice in the html
    assert (_match_count(embed_url, embed_html) == 2)

    # make sure the default width and height are present
    dimension_text = "width=\"425\" height=\"350\""
    assert (_match_count(dimension_text, embed_html) == 2)

    # try changing the width and height in the embed html
    custom_embed_html = sample_video.embed_html(200, 100)
    dimension_text = "width=\"200\" height=\"100\""

    # make sure the customized width and height are present
    entries = custom_embed_html.find_all { |t| t == dimension_text }
    assert (_match_count(dimension_text, custom_embed_html) == 2)
  end

  private
    # Returns the number of times +substr+ exists within +text+.
    def _match_count (substr, text)
      return 0 if (!text || !substr)

      count = 0
      offset = 0
      while (result = text.index(substr, offset))
        count += 1
        offset = result + 1
      end
      count
    end

    def _assert_youtube_url (url)
      (url =~ /^http:\/\/www.youtube.com\//)
    end

    def _test_video_list (videos)
      # make sure we got some videos
      assert_not_nil videos
      assert (videos.length > 0)

      # make sure all video records look good
      videos.each { |video| _test_video(video) }
    end

    def _test_video (video)
      assert_kind_of YouTube::Video, video

      # sanity-check embed url to make sure it looks ok
      assert_not_nil video.embed_url
      _assert_youtube_url video.embed_url

      # check other attributes
      assert (video.thumbnail_url =~ /\.jpg$/)
      assert (video.title && video.title.length > 0)
      assert (video.length_seconds > 0)
      # make sure description came through as a string, as a single check
      # that we feel good about covering other fields since the xml parsing
      # of empty elements defaults to providing an empty hash but we want
      # a proper type everywhere.
      assert_instance_of String, video.description
      assert (video.upload_time && video.upload_time.is_a?(Time))
      _assert_youtube_url video.url
      assert (video.view_count >= 0)
      assert (video.tags && video.tags.length > 0)
      assert (video.author && video.author.length > 0)
    end
  
    def _validate_test_video(video, videos_seen = nil)
      values = YAML.load(video.description)
      index = values["index"]
    
      # make sure we only see a particular video once
      # if the particular test cares about that
      if videos_seen
        assert !videos_seen.include?(index)
        videos_seen.add(index)
      end
    
      title = sprintf("Test Video %02d", index)
      assert_equal title, video.title
      assert_equal values["length"], video.length_seconds
    
      tags = Set.new(video.tags.split)
      if index.modulo(2) == 1
        assert tags.include?("ytlodd")
      else
        assert tags.include?("ytleven")
      end
    
      if [2,3,5,7].to_set.include?(index)
        assert tags.include?("ytlprime")
      end
    end
end
