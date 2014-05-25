require 'spec_helper'

describe Discogs::Wrapper do

  def mock_http_with_response(code="200", response=nil)
    @http_request = mock(Net::HTTP)
    @http_response = mock(Net::HTTPResponse, :code => code, :body => "")

    unless response.nil?
      @http_response_as_file = mock(StringIO, :read => response)
      Zlib::GzipReader.should_receive(:new).and_return(@http_response_as_file)
    end

    # As of 04/09/2010 - The and_yield method is not working for me. I've removed
    # this from the specs for now, but it's a little troubling because it used to
    # work correctly... (replacement on line #21)
    #@http_session = mock("HTTP Session")
    #@http_session.should_receive(:request).and_return(@http_response)
    #@http_request.should_receive(:start).and_yield(@http_session)

    @http_request.should_receive(:start).and_return(@http_response)
    Net::HTTP.should_receive(:new).and_return(@http_request)
  end

  before do
    @app_name = "some_app"
    @wrapper = Discogs::Wrapper.new(@app_name)
    @release_id = "1"
    @artist_id = 313929
    @master_id = 5331
    @label_id = 1000
    @search_term = "barry"
    @username = "abuntine"
  end

  it "should have an user agent" do
    @wrapper.app_name.should == @app_name
  end

  describe "requested URIs" do
    before do
      @uri = mock("uri", :host => "", :query => "", :path => "")
    end

    it "should generate the correct release URL to parse" do
      mock_http_with_response "200", read_sample("release")
      URI.should_receive(:parse).with("http://api.discogs.com/releases/1?f=json").and_return(@uri)

      @wrapper.get_release(@release_id)
    end

    it "should generate the correct artist URL to parse" do
      mock_http_with_response "200", read_sample("artist")
      URI.should_receive(:parse).with("http://api.discogs.com/artists/313929?f=json").and_return(@uri)

      @wrapper.get_artist(@artist_id)
    end

    it "should generate the correct paginated artist releases URL to parse" do
      mock_http_with_response "200", read_sample("artist_releases")
      URI.should_receive(:parse).with("http://api.discogs.com/artists/313929/releases?f=json&page=2&per_page=100").and_return(@uri)

      @wrapper.get_artist_releases(@artist_id, :page => 2, :per_page => 100)
    end
 
    it "should generate the correct label URL to parse" do
      mock_http_with_response "200", read_sample("label")
      URI.should_receive(:parse).with("http://api.discogs.com/labels/1000?f=json").and_return(@uri)

      @wrapper.get_label(@label_id)
    end

    it "should generate the correct paginated label releases URL to parse" do
      mock_http_with_response "200", read_sample("label_releases")
      URI.should_receive(:parse).with("http://api.discogs.com/labels/1000/releases?f=json&page=2&per_page=100").and_return(@uri)

      @wrapper.get_label_releases(@label_id, :page => 2, :per_page => 100)
    end

    it "should generate the correct default search URL to parse" do
      mock_http_with_response "200", read_sample("search_results")
      URI.should_receive(:parse).with("http://api.discogs.com/database/search?f=json&q=barry").and_return(@uri)

      @wrapper.search(@search_term)
    end

    it "should generate the correct paginated search URL to parse" do
      mock_http_with_response "200", read_sample("search_results")
      URI.should_receive(:parse).with("http://api.discogs.com/database/search?f=json&page=2&per_page=100&q=barry").and_return(@uri)

      @wrapper.search(@search_term, :page => 2, :per_page => 100)
    end

    it "should generate another correct paginated search URL to parse" do
      mock_http_with_response "200", read_sample("search_results")
      URI.should_receive(:parse).with("http://api.discogs.com/database/search?f=json&page=2&q=barry").and_return(@uri)

      @wrapper.search(@search_term, :page => 2)
    end

    it "should sanitize the path correctly" do
      mock_http_with_response "200", read_sample("search_results")
      URI.should_receive(:parse).with("http://api.discogs.com/database/search?f=json&q=Two+Words").and_return(@uri)

      @wrapper.search("Two Words")
    end

    it "should generate the correct default user inventory URL to parse" do
      mock_http_with_response "200", read_sample("user_inventory")
      URI.should_receive(:parse).with("http://api.discogs.com/users/abuntine/inventory?f=json").and_return(@uri)

      @wrapper.get_user_inventory(@username)
    end

    it "should generate the correct paginated user inventory URL to parse" do
      mock_http_with_response "200", read_sample("user_inventory")
      URI.should_receive(:parse).with("http://api.discogs.com/users/abuntine/inventory?f=json&page=2&status=For+Sale").and_return(@uri)

      @wrapper.get_user_inventory(@username, :page => 2, :status => "For Sale")
    end

    it "should generate the correct sorted and paginated user inventory URL to parse" do
      mock_http_with_response "200", read_sample("user_inventory")
      URI.should_receive(:parse).with("http://api.discogs.com/users/abuntine/inventory?f=json&page=2&sort=price&sort_order=asc&status=For+Sale").and_return(@uri)

      @wrapper.get_user_inventory(@username, :page => 2, :status => "For Sale", :sort => :price, :sort_order => :asc)
    end

  end

  ## NOTE: See ./spec/wrapper_methods/*.rb for indepth tests on valid API requests.

  describe "when requesting authentication identity" do

    it "should raise an exception if the session is not authenticated" do
      lambda { @wrapper.get_identity }.should raise_error(Discogs::AuthenticationError)
    end

  end

  describe "when editing a user" do

    it "should raise an exception if the session is not authenticated" do
      lambda { @wrapper.edit_user("abuntine") }.should raise_error(Discogs::AuthenticationError)
    end

  end

  describe "when removing a release from a wantlist" do

    it "should raise an exception if the session is not authenticated" do
      lambda { @wrapper.delete_release_from_user_wantlist("abuntine", 12341234) }.should raise_error(Discogs::AuthenticationError)
    end

  end

  describe "when requesting a release" do

    it "should raise an exception if the release does not exist" do
      mock_http_with_response "404"

      lambda { @wrapper.get_release(@release_id) }.should raise_error(Discogs::UnknownResource)
    end

    it "should raise an exception if the server dies a horrible death" do
      mock_http_with_response "500"

      lambda { @wrapper.get_release(@release_id) }.should raise_error(Discogs::InternalServerError)
    end

  end

  describe "when requesting an artist" do

    it "should raise an exception if the artist does not exist" do
      mock_http_with_response "404"

      lambda { @wrapper.get_artist(@artist_id) }.should raise_error(Discogs::UnknownResource)
    end

    it "should raise an exception if the server dies a horrible death" do
      mock_http_with_response "500"

      lambda { @wrapper.get_artist(@artist_id) }.should raise_error(Discogs::InternalServerError)
    end

  end

  describe "when requesting a label" do

    it "should raise an exception if the label does not exist" do
      mock_http_with_response "404"

      lambda { @wrapper.get_label(@label_id) }.should raise_error(Discogs::UnknownResource)
    end

    it "should raise an exception if the server dies a horrible death" do
      mock_http_with_response "500"

      lambda { @wrapper.get_label(@label_id) }.should raise_error(Discogs::InternalServerError)
    end

  end

  describe "when requesting a master" do

    it "should raise an exception if the master does not exist" do
      mock_http_with_response "404"

      lambda { @wrapper.get_master(@master_id) }.should raise_error(Discogs::UnknownResource)
    end

    it "should raise an exception if the server dies a horrible death" do
      mock_http_with_response "500"

      lambda { @wrapper.get_master(@master_id) }.should raise_error(Discogs::InternalServerError)
    end

  end

end
