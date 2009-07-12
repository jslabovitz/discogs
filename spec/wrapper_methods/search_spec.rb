require File.dirname(__FILE__) + "/../spec_helper"

describe Discogs::Wrapper do

  before do
    @wrapper = Discogs::Wrapper.new("some_key")
    @search_term = "slaughter"
  end

  def mock_search(page)
    @http_request = mock(Net::HTTP)
    @http_response = mock(Net::HTTPResponse, :code => "200", :body => valid_search_xml(page))
    @http_response_as_file = mock(StringIO, :read => valid_search_xml(page))
    Zlib::GzipReader.should_receive(:new).and_return(@http_response_as_file)
    @http_session = mock("HTTP Session")
    @http_session.should_receive(:request).and_return(@http_response)
    @http_request.should_receive(:start).and_yield(@http_session)
    Net::HTTP.should_receive(:new).and_return(@http_request)
  end

  describe "when asking for search result information" do

    before do
      mock_search(1)

      @search = @wrapper.search(@search_term)
    end

    describe "when dealing with page information" do

      it "should have a current_page method" do
        @search.current_page.should == 1
      end

    end

    describe "when handling exact results" do

      it "should have the exact results stored as an array" do
        @search.exactresults.should be_instance_of(Array)
      end

      it "should be stored as result objects" do
        @search.exactresults.each do |result|
          result.should be_instance_of(Discogs::Search::Result)
        end
      end

      it "should have a incrementing num for each exact result" do
        @search.exactresults.each_with_index do |result, index|
          result.num.should == (index + 1).to_s
        end
      end

      it "should have a type for the first result" do
        @search.exactresults[0].type.should == "artist"
      end

      it "should have an anv for the fifth result" do
        @search.exactresults[5].anv.should == "Slaughter"
      end

      it "should be able to filter all non-artists from exact results" do
        @search.exact(:artist).should be_instance_of(Array)
        @search.exact(:artist).length.should == 6
      end

      it "should be able to filter all non-releases from exact results" do
        @search.exact(:release).should be_instance_of(Array)
        @search.exact(:release).length.should == 1
      end

      it "should be able to filter all non-labels from exact results" do
        @search.exact(:label).should be_instance_of(Array)
        @search.exact(:label).length.should == 1
      end

      it "should return an empty array on a junk filter" do
        @search.exact(:cheesecake).should be_instance_of(Array)
        @search.exact(:cheesecake).should be_empty
      end

      it "should simply return all exact results without a filter" do
        @search.exact.should be_instance_of(Array)
        @search.exact.length.should == 8
      end

   end

    describe "when handling search results" do

      it "should have a start attribute" do
        @search.start.should == "1"
      end

      it "should have an end attribute" do
        @search.end.should == "20"
      end

      it "should have number of results attribute" do
        @search.total_results.should == 1846
      end

      it "should have the search results stored as an array" do
        @search.searchresults.should be_instance_of(Array)
      end

      it "should be stored as result objects" do
        @search.searchresults.each do |result|
          result.should be_instance_of(Discogs::Search::Result)
        end
      end

      it "should have a incrementing num for each search result" do
        @search.searchresults.each_with_index do |result, index|
          result.num.should == (index + 1).to_s
        end
      end

      it "should have a type for the third result" do
        @search.searchresults[2].type.should == "label"
      end

      it "should have a title for the fourth result" do
        @search.searchresults[3].title.should == "Satanic Slaughter"
      end

      it "should have a summary for the sixth result" do
        @search.searchresults[5].summary.should == "Gary Slaughter"
      end

      it "should be able to filter all non-artists from extended results" do
        @search.results(:artist).should be_instance_of(Array)
        @search.results(:artist).length.should == 12
      end

      it "should be able to filter all non-releases from extended results" do
        @search.results(:release).should be_instance_of(Array)
        @search.results(:release).length.should == 6
      end

      it "should be able to filter all non-labels from extended results" do
        @search.results(:label).should be_instance_of(Array)
        @search.results(:label).length.should == 2
      end

      it "should return an empty array on a junk filter" do
        @search.results(:cheesecake).should be_instance_of(Array)
        @search.results(:cheesecake).should be_empty
      end

      it "should simply return all extended results without a filter" do
        @search.results.should be_instance_of(Array)
        @search.results.length.should == 20
      end

    end
 
  end

  describe "when getting the next page" do

    before do
      mock_search(2)

      @search = @wrapper.search(@search_term, 2)
    end

    describe "when dealing with page information" do

      it "should have a current_page method" do
        @search.current_page.should == 2
      end

    end

    describe "when handling exact results" do

      it "should not have any exact results" do
        @search.exactresults.should be_nil
      end

      it "should return empty array for exact filtering" do
        @search.exact.should == []
      end

      it "should still allow filtering and return an empty array" do
        @search.exact(:artist).should == []
      end

    end

    describe "when handling search results" do

      it "should have a start attribute" do
        @search.start.should == "21"
      end

      it "should have an end attribute" do
        @search.end.should == "40"
      end

      it "should have number of results attribute" do
        @search.total_results.should == 1846
      end

      it "should have the search results stored as an array" do
        @search.searchresults.should be_instance_of(Array)
      end

      it "should be stored as result objects" do
        @search.searchresults.each do |result|
          result.should be_instance_of(Discogs::Search::Result)
        end
      end

      it "should have a incrementing num for each search result" do
        @search.searchresults.each_with_index do |result, index|
          result.num.should == (index + 21).to_s
        end
      end

    end

  end

end
