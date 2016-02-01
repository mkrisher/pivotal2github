#encoding:UTF-8
#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'httparty'
require 'pry'

class Importer
  include HTTParty
  base_uri 'https://api.github.com'

  FILENAME = "issues.csv"

  attr_accessor :username, :password, :owner, :repo, :two_factor_code

  def initialize
    @username        = ""
    @password        = ""
    @owner           = ""
    @repo            = ""
    @two_factor_code = ""
  end

  def execute
    user_creds
    repo_path
    load_file
    parse_file
  end

  private

  def user_creds
    puts "==> enter your github username"
    username = gets.chomp
    puts "==> enter your github password"
    password = gets.chomp
    puts "==> enter a two factor authentication code"
    two_factor_code = gets.chomp

    self.class.basic_auth username, password
  end

  def headers
    {'X-GitHub-OTP' => two_factor_code, 'User-Agent' => 'Ruby'}
  end

  def repo_path
    puts "==> enter the github organization or user the repo belongs to"
    owner = gets.chomp
    puts "==> enter the name of the github repo"
    repo = gets.chomp
  end

  def load_file
    raise "File named issues.csv could not be found" unless File.open(FILENAME)
  end

  def parse_file
    visited_labels = []

    CSV.open(FILENAME, :headers => true) do |csv|
      csv.each do |row|
        body = {
          :title => row['Title'],
          :body  => row['Description'],
        }

        #labels = []
        #if r['Labels'] != ''
        #  r['Labels'].split(',').each do |label|
        #    label = label.strip
        #    color =''
        #    3.times {
        #      color << "%02x" % rand(255)
        #    }
        #    unless visited_labels.include? label
        #      labels << {:name => label, :color =>color}
        #    end
        #  end
        #  labels.each do |label|
        #    p label
        #    # this hack doesn't care if you have an existing label - it just errors and moves on like a zen master
        #    # the server however is expected to be equally zen :D
        #    visited_labels << label[:name]
        #    label = GitHub.post "/repos/#{repository_path}/labels", :body => JSON.generate(label)
        #    p label
        #  end
        #end
        #body[:labels] = r['Labels'].split(',').map {|l|l.strip} if r['Labels'] != ''

        json_body = JSON.generate(body)
        issue     = create_issue(json_body)

        #r.each do |f|
        #  if f[0] == 'Note'
        #    next unless f[1]
        #    body = { :body => f[1] }
        #    json_body = JSON.generate(body)
        #    create_comment(JSON.generate(body), issue)
        #  end
        #end
      end
    end
  end

  def create_issue(json_body)
    result = self.class.post "/repos/#{owner}/#{repo}/issues", :body => json_body, :headers => headers
  end

  def create_comment(json_body, issue)
    self.class.post "/repos/#{owner}/#{repo}/#{issue.parsed_response['number']}/comments", :body => json_body, :headers => headers
  end
end

Importer.new.execute

