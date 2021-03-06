# This file is managed centrally by modulesync
#   https://github.com/theforeman/foreman-installer-modulesync

RSpec.configure do |c|
  c.mock_with :rspec
end

require 'puppetlabs_spec_helper/module_spec_helper'

require 'rspec-puppet-facts'
include RspecPuppetFacts

                                                                             # Original fact sources:
add_custom_fact :puppet_environmentpath, '/etc/puppetlabs/code/environments' # puppetlabs-stdlib
add_custom_fact :root_home, '/root'                                          # puppetlabs-stdlib
# Rough conversion of grepping in the puppet source:
# grep defaultfor lib/puppet/provider/service/*.rb
add_custom_fact :service_provider, ->(os, facts) do
  case facts[:osfamily].downcase
  when 'archlinux'
    'systemd'
  when 'darwin'
    'launchd'
  when 'debian'
    'systemd'
  when 'freebsd'
    'freebsd'
  when 'gentoo'
    'openrc'
  when 'openbsd'
    'openbsd'
  when 'redhat'
    facts[:operatingsystemrelease].to_i >= 7 ? 'systemd' : 'redhat'
  when 'suse'
    facts[:operatingsystemmajrelease].to_i >= 12 ? 'systemd' : 'redhat'
  when 'windows'
    'windows'
  else
    'init'
  end
end

# Workaround for no method in rspec-puppet to pass undef through :params
class Undef
  def inspect; 'undef'; end
end

# Running tests with the ONLY_OS environment variable set
# limits the tested platforms to the specified values.
# Example: ONLY_OS=centos-7-x86_64,ubuntu-14-x86_64
def only_test_os
  if ENV.key?('ONLY_OS')
    ENV['ONLY_OS'].split(',')
  end
end

# Running tests with the EXCLUDE_OS environment variable set
# limits the tested platforms to all but the specified values.
# Example: EXCLUDE_OS=centos-7-x86_64,ubuntu-14-x86_64
def exclude_test_os
  if ENV.key?('EXCLUDE_OS')
    ENV['EXCLUDE_OS'].split(',')
  end
end

# Use the above environment variables to limit the platforms under test
def on_os_under_test
  on_supported_os.reject do |os, facts|
    (only_test_os() && !only_test_os.include?(os)) ||
      (exclude_test_os() && exclude_test_os.include?(os))
  end
end

def get_content(subject, title)
  is_expected.to contain_file(title)
  content = subject.resource('file', title).send(:parameters)[:content]
  content.split(/\n/).reject { |line| line =~ /(^#|^$|^\s+#)/ }
end

def verify_exact_contents(subject, title, expected_lines)
  expect(get_content(subject, title)).to match_array(expected_lines)
end

def verify_concat_fragment_contents(subject, title, expected_lines)
  is_expected.to contain_concat__fragment(title)
  content = subject.resource('concat::fragment', title).send(:parameters)[:content]
  expect(content.split("\n") & expected_lines).to match_array(expected_lines)
end

def verify_concat_fragment_exact_contents(subject, title, expected_lines)
  is_expected.to contain_concat__fragment(title)
  content = subject.resource('concat::fragment', title).send(:parameters)[:content]
  expect(content.split(/\n/).reject { |line| line =~ /(^#|^$|^\s+#)/ }).to match_array(expected_lines)
end

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
