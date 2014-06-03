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

    it "creates /var/log/neo4j" do
      directory("/var/log/neo4j").must_exist.with(:owner, "neo4j").with(:group, "neo4j")
    end

    if `nproc`.to_i >= 4 && `grep "^MemTotal" /proc/meminfo | awk '{print $2}'`.to_i >= 10 * 1024 * 1024
      file("/etc/neo4j/neo4j-wrapper.conf").must_include 'wrapper.java.additional=-XX:+UseParallelGC'
    end

    it "creates /etc/nginx" do
      directory("/etc/nginx").must_exist.with(:owner, "root").with(:group, "root")
    end

    it "create /etc/nginx/nginx.conf" do
      file("/etc/nginx/nginx.conf").must_exist.with(:owner, "root").with(:group, "root")
    end

    it "creates /var/log/nginx" do
      directory("/var/log/nginx").must_exist.with(:owner, "nginx").with(:group, "nginx")
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

    it "runs nginx on port 8080" do
      assert system "sudo netstat -lp --numeric-ports | grep -q \":8080.*LISTEN.*\/nginx\""
    end
  end
end
