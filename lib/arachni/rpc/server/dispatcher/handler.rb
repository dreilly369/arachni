=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni::RPC

#
# Base class and namespace for all RPCD/Dispatcher handlers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Server::Dispatcher::Handler

    attr_reader :opts
    attr_reader :dispatcher

    def initialize( opts, dispatcher )
        @opts       = opts
        @dispatcher = dispatcher
    end

    # @return   [Server::Dispatcher::Node]  local node
    def node
        dispatcher.node
    end

    #
    # Performs an asynchronous map operation over all running instances.
    #
    # @param [Proc]  each    block to be passed {Client::Instance} and {::EM::Iterator}
    # @param [Proc]  after   block to be passed the Array of results
    #
    def map_instances( each, after )
        wrap_each = proc do |instance, iterator|
            each.call( connect_to_instance( instance ), iterator )
        end
        iterator_for( instances ).map( wrap_each, after )
    end

    #
    # Performs an asynchronous iteration over all running instances.
    #
    # @param [Proc]  block    block to be passed {Client::Instance} and {::EM::Iterator}
    #
    def each_instance( &block )
        wrap = proc do |instance, iterator|
            block.call( connect_to_instance( instance ), iterator )
        end
        iterator_for( instances ).each( &wrap )
    end

    #
    # @param    [Array]    arr
    #
    # @return   [::EM::Iterator]  iterator for the provided array
    #
    def iterator_for( arr, max_concurrency = 10 )
        ::EM::Iterator.new( arr, max_concurrency )
    end

    # @return   [Array<Hash>]   all running instances
    def instances
        jobs.select { |j| !j['proc'].empty? }
    end

    #
    # Connects to a Dispatcher by +url+.
    #
    # @param    [String]    url
    #
    # @return   [Client::Dispatcher]
    #
    def connect_to_dispatcher( url )
        Client::Dispatcher.new( @opts, url )
    end

    #
    # Connects to an Instance by +url+.
    #
    # @example
    #   connect_to_instance( url, token )
    #   connect_to_instance( url: url, token: token )
    #   connect_to_instance( 'url' => url, 'token' => token )
    #
    # @param    [Vararg]    args
    #
    # @return   [Client::Instance]
    #
    def connect_to_instance( *args )
        url = token = nil

        if args.size == 2
            url, token = *args
        elsif args.first.is_a? Hash
            opts    = args.first
            url     = opts['url'] || opts[:url]
            token   = opts['token'] || opts[:token]
        end

        Client::Instance.new( @opts, url, token )
    end

end
end
