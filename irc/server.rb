# -*- coding: utf-8 -*-
require 'net/irc'
require 'shellwords'

class Stig::Server < Net::IRC::Server::Session
  def server_name
    'stig'
  end

  def server_version
    Stig::VERSION
  end

  def on_user(m)
    super

    post @prefix, JOIN, '#timeline'
    begin
      @thread = Thread.new do
        user_id = nil
        lines = []
        IO.popen("t stream -N timeline").each_line{|l|
          l.strip!
          if user_id.nil? && l =~ /^@(.+)/
            user_id = $1
          elsif l.size > 0
            lines << l
          else
            lines.map{|l|
              prefix = "#{user_id}!#{user_id}@twitter"
              post prefix, PRIVMSG, '#timeline', l
            }
            lines = []
            user_id = nil
          end
        }
      end
    end
  end

  def on_disconnected
    @thread.kill rescue nil
  end

  def on_privmsg(m)
    target, msg = *m.params
    system('t', 'update', msg)
  end
end
