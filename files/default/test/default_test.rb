require "minitest/spec"

describe_recipe "neo4j::default" do
  describe "packages" do
    it "installs neo4j" do
      package("neo4j").must_be_installed
    end

    it "installs nginx" do
      package("nginx").must_be_installed
    end
  end

  describe "files" do
    it "creates /etc/neo4j" do
      directory("/etc/neo4j").must_exist.with(:owner, "root").with(:group, "root")
    end

    ["/etc/neo4j/neo4j-server.properties", "/etc/neo4j/neo4j-wrapper.conf"].each do |config_file|
      it "creates #{config_file}" do
        file(config_file).must_exist.with(:owner, "root").with(:group, "root")
      end
    end

    it "creates node['neo4j']['data']" do
      directory(node['neo4j']['data']).must_exist.with(:owner, "neo4j").with(:group, "neo4j")
      if node['neo4j']['data'] != '/var/lib/neo4j'
        link('/var/lib/neo4j').must_exist.with(:link_type, :symbolic).and(:to, node['neo4j']['data'])
      end
    end

    it "creates node['neo4j']['log']" do
      directory(node['neo4j']['log']).must_exist.with(:owner, "neo4j").with(:group, "neo4j")
      if node['neo4j']['log'] != '/var/log/neo4j'
        link('/var/log/neo4j').must_exist.with(:link_type, :symbolic).and(:to, node['neo4j']['log'])
      end
    end

    if `nproc`.to_i >= 4 && `grep "^MemTotal" /proc/meminfo | awk '{print $2}'`.to_i >= 10 * 1024 * 1024
      it "adds -XX:+UseParallelGC to /etc/neo4j/neo4j-wrapper.conf" do
        file("/etc/neo4j/neo4j-wrapper.conf").must_include 'wrapper.java.additional=-XX:+UseParallelGC'
      end
    end

    it "creates /etc/nginx" do
      directory("/etc/nginx").must_exist.with(:owner, "root").with(:group, "root")
    end

    it "create /etc/nginx/nginx.conf" do
      file("/etc/nginx/nginx.conf").must_exist.with(:owner, "root").with(:group, "root")
    end

    it "creates /etc/nginx/sites-available/default" do
      file("/etc/nginx/sites-available/default").must_exist.with(:owner, "root").with(:group, "root")
      if node['neo4j']['proxy']['username'] && node['neo4j']['proxy']['password']
        file("/etc/nginx/sites-available/default").must_include 'auth_basic "Restricted";'
        file("/etc/nginx/sites-available/default").must_include "auth_basic_user_file #{node['nginx']['dir']}/htpasswd;"
        file("/etc/nginx/sites-available/default").must_include 'proxy_set_header Authorization "";'
      end
    end

    it "links /etc/nginx/sites-enabled/000-default to /etc/nginx/sites-available/default" do
      link('/etc/nginx/sites-enabled/000-default').must_exist.with(:link_type, :symbolic).and(:to, "/etc/nginx/sites-available/default")
    end

    it "creates /var/log/nginx" do
      directory("/var/log/nginx").must_exist.with(:owner, "nginx").with(:group, "root")
    end
  end

  describe "services" do
    it "boots neo4j on startup" do
      service("neo4j").must_be_enabled
    end

    it "runs neo4j as a daemon" do
      service("neo4j").must_be_running
    end

    [7473, 7474, 1337].each do |port|
      it "runs neo4j on port #{port}" do
        assert system "sudo netstat -lp --numeric-ports | grep -q \":#{port}.*LISTEN.*\/java\""
      end
    end

    it "boots nginx on startup" do
     service("nginx").must_be_enabled
    end

    it "runs nginx as a daemon" do
      service("nginx").must_be_running
    end

    it "runs nginx on port node['neo4j']['proxy']['port']" do
      assert system "sudo netstat -lp --numeric-ports | grep -q \":#{node['neo4j']['proxy']['port']}.*LISTEN.*\/nginx\""
    end
  end
end
