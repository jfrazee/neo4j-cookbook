include_attribute 'java'
include_attribute 'nginx'

default["java"]["jdk_version"] = 7
default['nginx']['repo_source'] = 'nginx'

default['neo4j'] ||= {}
default['neo4j']['data'] = '/var/lib/neo4j'
default['neo4j']['log'] = '/var/log/neo4j'

default['neo4j']['proxy'] ||= {}
default['neo4j']['proxy']['port'] = 8080
default['neo4j']['proxy']['username'] = 'neo4j'
default['neo4j']['proxy']['password'] = 'neo4j'
