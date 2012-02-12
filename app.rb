#
# metaflop - web interface
# © 2012 by alexis reigel
# www.metaflop.com
#
# licensed under gpl v3
#

# encoding: UTF-8
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/config_file'
require 'sass'
require 'mustache/sinatra'
require 'fileutils'
require 'time'
require 'data_mapper' # metagem, requires common plugins too.
require './lib/metaflop'
require './lib/url'

class App < Sinatra::Application

    configure do
        register Sinatra::ConfigFile
        config_file ['./config.yml', './db.yml']

        # setup the tmp dir where the generated fonts go
        tmp_dir = "/tmp/metaflop"
        FileUtils.rm_rf(tmp_dir)
        Dir.mkdir(tmp_dir)

        require './views/layout'
        register Mustache::Sinatra

        set :mustache, {
            :views => './views',
            :templates => './views'
        }

        mime_type :otf, 'font/opentype'

        enable :sessions

        # db
        DataMapper.setup(:default, {
            :adapter  => settings.db[:adapter],
            :host     => settings.db[:host],
            :username => settings.db[:username],
            :password => settings.db[:password],
            :database => settings.db[:database]
        })

        DataMapper.finalize
        Url.auto_upgrade!
    end

    configure :development do
        register Sinatra::Reloader
        also_reload '**/*.rb'
    end

    configure :production do
        # logging
        log_dir = "log/rack/"
        Dir.mkdir(log_dir) unless Dir.exist? log_dir
        logger = File.new("#{log_dir}#{Time.new.iso8601}.log", 'w+')
        $stderr.reopen(logger)
        $stdout.reopen(logger)
    end


    get '/' do
        mf = mf_instance_from_request
        mf_args = mf.mf_args
        @ranges = mf_args[:ranges]
        @defaults = mf_args[:defaults]
        @values = mf_args[:values]
        @active_fontface = mf.fontface

        mustache :index
    end

    # creates a shortened url for the current params (i.e. font setting)
    get '/font/create' do
        Url.create(:params => params)[:short]
    end

    get '/font/:url' do |url|
        url = Url.first(:short => url)

        if url.nil?
            redirect '/'
        end

        mf = mf_instance_from_request(url[:params])
        mf_args = mf.mf_args
        @ranges = mf_args[:ranges]
        @defaults = mf_args[:defaults]
        @values = mf_args[:values]
        @active_fontface = mf.fontface

        mustache :index
    end

    get '/assets/css/:name.scss' do |name|
        content_type :css
        scss name.to_sym, :layout => false
    end

    get '/preview/:type' do |type|
        mf = mf_instance_from_request
        method = "preview_#{type}"
        if mf.respond_to? method
            image = mf.method(method).call
            [image ? 200 : 404, { 'Content-Type' => 'image/gif' }, image]
        else
            [404, { 'Content-Type' => 'text/html' }, "The preview type could not be found"]
        end
    end

    get '/export/font/:type/:face/:hash' do |type, face, hash|
        mf = Metaflop.new({ :out_dir => out_dir, :font_hash => hash, :active_fontface => face })
        mf.settings = settings.metaflop
        mf.logger = logger
        method = "font_#{type}"
        if mf.respond_to? method
            attachment "#{face}-#{hash}.otf"
            file = mf.method(method).call
        else
            [404, { 'Content-Type' => 'text/html' }, "The font type is not supported"]
        end
    end

    get '/:page' do |page|
        if (page == 'parameter_panel')
            mf = mf_instance_from_request
            mf_args = mf.mf_args
            @ranges = mf_args[:ranges]
            @defaults = mf_args[:defaults]
            @values = mf_args[:values]
            @active_fontface = mf.fontface
        end

        mustache page.to_sym, :layout => false
    end

    def out_dir
        session[:id] ||= SecureRandom.urlsafe_base64
        "/tmp/metaflop/#{session[:id]}"
    end

    def mf_instance_from_request(params = params)
        # map all query params
        args = { :out_dir => out_dir }
        Metaflop::VALID_OPTIONS_KEYS.each do |key|
            # query params come in with dashes -> replace by underscores to match properties
            value = params[key.to_s.gsub("_", "-")]

            # whitelist allowed characters
            args[key] = value.delete "^a-zA-Z0-9., " if value && !value.empty?
        end

        mf = Metaflop.new(args)
        mf.settings = settings.metaflop
        mf.logger = logger

        mf
    end

end
