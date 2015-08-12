# Copyright:: 2011, Mathieu Sauve-Frankel <msf@kisoku.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems'
require 'chef'
require 'chef/handler'
require 'erubis'
require 'pony'

class MailHandler < Chef::Handler
  attr_reader :options
  def initialize(opts = {})
    @options = {
      :to_address => "root",
      :template_path => File.join(File.dirname(__FILE__), "mail.erb")
    }
    @options.merge! opts
  end

  def report
    status = success? ? "Successful" : "Failed"
    subject = "#{status} Chef run on node #{node.fqdn}"

    Chef::Log.debug("mail handler template path: #{options[:template_path]}")
    if File.exists? options[:template_path]
      template = IO.read(options[:template_path]).chomp
    else
      Chef::Log.error("mail handler template not found: #{options[:template_path]}")
      raise Errno::ENOENT
    end

    context = {
      :status => status,
      :run_status => run_status
    }

    body = Erubis::Eruby.new(template).evaluate(context)
    Pony.mail(
      :to => options[:to_address],
      :via => options[:mail_proto],
      :from => options[:from_address],
      :subject => subject,
      :body => body,
      :via_options => {
        :address              => options[:mail_server]
        :port                 => options[:mail_server_port],
        :enable_starttls_auto => true,
        :user_name            => options[:mail_user_name],
        :password             => options[:mail_password],
        :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
        :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
      }
    )
  end
end
