#
# Cookbook Name:: neo4j
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

chef_gem 'chef-rewind'

require 'chef/rewind'

include_recipe 'yum'
include_recipe 'java'

yum_repository 'Neo4j' do
  name 'neo4j'
  baseurl 'http://yum.neo4j.org'
  gpgkey 'http://debian.neo4j.org/neotechnology.gpg.key'
  action :create
end

yum_package 'neo4j' do
  action :upgrade
end

# Use parallel garbage collection with more than 4 cores and 10gb ram
if `nproc`.to_i >= 4 && `grep "^MemTotal" /proc/meminfo | awk '{print $2}'`.to_i >= 10 * 1024 * 1024
  ruby_block "add -XX:+UseParallelGC to /etc/neo4j/neo4j-wrapper.conf" do
    block do
      file = Chef::Util::FileEdit.new("/etc/neo4j/neo4j-wrapper.conf")
      file.insert_line_after_match(/wrapper\.java\.additional=\-XX:\+CMSClassUnloadingEnabled/,
        'wrapper.java.additional=-XX:+UseParallelGC')
      file.write_file
    end
  end
end

service 'neo4j' do
  action [:enable, :start]
end

include_recipe 'nginx'

ruby_block "set nginx worker_processes to auto in /etc/nginx/nginx.conf" do
  block do
    file = Chef::Util::FileEdit.new("/etc/nginx/nginx.conf")
    file.search_file_replace_line(/^worker_processes\s+\d+;/, 'worker_processes  auto;')
    file.write_file
  end
end

rewind :template => "/etc/nginx/sites-available/default" do
  source "default-site.erb"
  cookbook_name "neo4j"
end
