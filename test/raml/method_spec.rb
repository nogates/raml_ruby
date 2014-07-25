require_relative 'spec_helper'

describe Raml::Method do
  let(:name) { 'get' }
  let (:data) {
    YAML.load(%q(
      description: Get a list of users
      queryParameters:
        page:
          description: Specify the page that you want to retrieve
          type: integer
          required: true
          example: 1
        per_page:
          description: Specify the amount of items that will be retrieved per page
          type: integer
          minimum: 10
          maximum: 200
          default: 30
          example: 50
      protocols: [ HTTP, HTTPS ]
      responses:
        200:
          description: |
            The list of popular media.
    ))
  }

  subject { Raml::Method.new(name, data) }

  describe '#new' do
    it "should instanciate Method" do
      subject
    end
    
    context 'when the method is a method defined in RFC2616 or RFC5789' do
      %w(options get head post put delete trace connect patch).each do |method|
        context "when the method is #{method}" do
          let(:name) { method }
          it { expect { subject }.to_not raise_error }
        end
      end
    end
    context 'when the method is an unsupported method' do
      %w(propfind proppatch mkcol copy move lock unlock).each do |method|
        context "when the method is #{method}" do
          let(:name) { method }
          it { expect { subject }.to raise_error Raml::InvalidMethod }
        end
      end
    end
    
    context 'when description property is not given' do
      let(:data) { {} }
      it { expect { subject }.to_not raise_error }
    end
    context 'when description property is given' do
      context 'when the description property is not a string' do
        let(:data) { { 'description' => 1 } }
        it { expect { subject }.to raise_error Raml::InvalidProperty, /description/ }
      end
      context 'when the description property is a string' do
        let(:data) { { 'description' => 'My Description' } }
        it { expect { subject }.to_not raise_error }
        it 'should store the value' do
          subject.description.should eq data['description']
        end
        it 'uses the description in the documentation' do
          subject.document.should include data['description']
        end
      end
    end
    
    context 'when the headers parameter is given' do
      context 'when the headers property is well formed' do
        let (:data) {
          YAML.load(%q(
            headers:
              Zencoder-Api-Key:
                displayName: ZEncoder API Key
              x-Zencoder-job-metadata-{*}:
                displayName: Job Metadata
          ))
        }
        it { expect { subject }.to_not raise_error }
        it 'stores all as Raml::Header instances' do
          expect( subject.headers ).to all( be_a Raml::Header )
          expect( subject.headers.map(&:name) ).to contain_exactly('Zencoder-Api-Key','x-Zencoder-job-metadata-{*}')
        end
      end
      context 'when the headers property is not a map' do
        let(:data) { { 'headers' => 1 } }
        it { expect { subject }.to raise_error Raml::InvalidProperty, /headers/ }
      end
      context 'when the headers property is not a map with non-string keys' do
        let(:data) { { 'headers' => { 1 => {}} } }
        it { expect { subject }.to raise_error Raml::InvalidProperty, /headers/ }
      end
      context 'when the headers property is not a map with non-string keys' do
        let(:data) { { 'headers' => { '1' => 'x'} } }
        it { expect { subject }.to raise_error Raml::InvalidProperty, /headers/ }
      end
    end
    
  end

  describe "#document" do
    it "prints out documentation" do
      subject.document
    end
  end
end
