require 'kramdown'

module Grape
  class API
    class << self
      attr_reader :combined_routes

      def add_swagger_documentation(options={})
        documentation_class = create_documentation_class

        documentation_class.setup({:target_class => self}.merge(options))
        mount(documentation_class)

        @combined_routes = {}

        routes.each do |route|
          route_match = route.route_path.split(route.route_prefix).last.match('\/([\w|-]*?)[\.\/\(]')
          next if route_match.nil?
          resource = route_match.captures.first
          next if resource.empty?
          resource.downcase!

          @combined_routes[resource] ||= []

          unless @@hide_documentation_path and route.route_path.include?(@@mount_path)
            @combined_routes[resource] << route
          end
        end

      end

      private

      def create_documentation_class

        Class.new(Grape::API) do
          class << self
            def name
              @@class_name
            end
          end

          def self.setup(options)
            defaults = {
              :target_class             => nil,
              :mount_path               => '/swagger_doc',
              :base_path                => nil,
              :api_version              => '0.1',
              :markdown                 => false,
              :hide_documentation_path  => false,
              :hide_format              => false,
              :format                   => nil,
              :models                   => [],
              :info                     => {},
              :authorizations           => nil,
              :root_base_path           => true,
              :include_base_url         => true
            }

            options = defaults.merge(options)

            target_class     = options[:target_class]
            @@mount_path     = options[:mount_path]
            @@class_name     = options[:class_name] || options[:mount_path].gsub('/', '')
            @@markdown       = options[:markdown]
            @@hide_format    = options[:hide_format]
            api_version      = options[:api_version]
            base_path        = options[:base_path]
            authorizations   = options[:authorizations]
            include_base_url = options[:include_base_url]
            root_base_path   = options[:root_base_path]
            extra_info       = options[:info]

            @@hide_documentation_path = options[:hide_documentation_path]

            if options[:format]
              [:format, :default_format, :default_error_formatter].each do |method|
                send(method, options[:format])
              end
            end

            desc 'Swagger compatible API description'
            get @@mount_path do
              header['Access-Control-Allow-Origin']   = '*'
              header['Access-Control-Request-Method'] = '*'

              routes = target_class::combined_routes

              if @@hide_documentation_path
                routes.reject!{ |route, value| "/#{route}/".index(parse_path(@@mount_path, nil) << '/') == 0 }
              end

              routes_array = routes.keys.map do |local_route|
                next if routes[local_route].all?(&:route_hidden)

                url_base    = parse_path(route.route_path.gsub('(.:format)', ''), route.route_version) if include_base_url
                url_format  = '.{format}' unless @@hide_format
                {
                  :path => "#{url_base}/#{local_route}#{url_format}",
                  #:description => "..."
                }
              end.compact

              output = {
                apiVersion:     api_version,
                swaggerVersion: "1.2",
                produces:       content_types_for(target_class),
                operations:     [],
                apis:           routes_array,
                info:           parse_info(extra_info)
              }

              basePath                = parse_base_path(base_path, request)
              output[:basePath]       = basePath        if basePath && basePath.size > 0 && root_base_path != false
              output[:authorizations] = authorizations  if authorizations

              output
            end

            desc 'Swagger compatible API description for specific API', :params => {
              "name" => {
                :desc     => "Resource name of mounted API",
                :type     => "string",
                :required => true
              }
            }
            get "#{@@mount_path}/:name" do
              header['Access-Control-Allow-Origin']   = '*'
              header['Access-Control-Request-Method'] = '*'

              models = []
              routes = target_class::combined_routes[params[:name]]

              ops = routes.reject(&:route_hidden).group_by do |route|
                parse_path(route.route_path, api_version)
              end

              apis = []

              ops.each do |path, routes|
                operations = routes.map do |route|
                  notes       = as_markdown(route.route_notes)
                  http_codes  = parse_http_codes(route.route_http_codes)

                  models += route.route_entity if route.route_entity
                  models << route.route_respond_with if route.route_respond_with

                  operation = {
                    :produces   => content_types_for(target_class),
                    :notes      => notes.to_s,
                    :summary    => route.route_description || '',
                    :nickname   => route.route_nickname || (route.route_method + route.route_path.gsub(/[\/:\(\)\.]/,'-')),
                    :method => route.route_method,
                    :parameters => parse_header_params(route.route_headers) +
                      parse_params(route.route_params, route.route_path, route.route_method, route.route_body_param_type)+
                      parse_body_param(route.route_body_param_type)
                  }

                  if route.route_type
                    operation.merge!(:type => route.route_type)
                    operation.merge!(:items => parse_items(route.route_items))
                    models |= [route.route_items]
                  else
                    operation.merge!(:type => 'Response') if route.route_respond_with
                    operation.merge!(:type => parse_entity_name(route.route_entity[-1])) if route.route_entity
                  end
                  operation.merge!(:responseMessages => http_codes) unless http_codes.empty?
                  operation
                end.compact
                apis << {
                  path: path,
                  operations: operations
                }
              end

              api_description = {
                apiVersion:     api_version,
                swaggerVersion: "1.2",
                resourcePath:   "",
                apis:           apis
              }

              basePath                   = parse_base_path(base_path, request)
              api_description[:basePath] = basePath if basePath && basePath.size > 0
              api_description[:models]   = parse_entity_models(models.uniq) unless models.empty?

              api_description
            end
          end

          helpers do

            def as_markdown(description)
              description && @@markdown ? Kramdown::Document.new(strip_heredoc(description), :input => 'GFM', :enable_coderay => false).to_html : description
            end

            def parse_body_param(body_param_type)
              if body_param_type
                [{
                  paramType:    'body',
                  name:         'body',
                  description:  'Body',
                  type:         parse_entity_name(body_param_type),
                  dataType:     parse_entity_name(body_param_type),
                  required:     false
                }]
              else
                []
              end
            end

            def parse_params(params, path, method, body_param_type)
              params ||= []
              params.map do |param, value|
                value[:type] = 'file' if value.is_a?(Hash) && value[:type] == 'Rack::Multipart::UploadedFile'
                value[:type] = 'boolean' if value[:type] == 'Virtus::Attribute::Boolean'
                dataType    = value.is_a?(Hash) ? (value[:type] || 'String').to_s : 'String'
                description = value.is_a?(Hash) ? value[:desc] || value[:description] : ''
                required    = value.is_a?(Hash) ? !!value[:required] : false
                defaultValue = value.is_a?(Hash) ? value[:defaultValue] : nil
                paramType = if path.include?(":#{param}")
                   'path'
                else
                  %w[ POST PUT PATCH ].include?(method) ? 'form' : 'query'
                end

                next if body_param_type && paramType != 'path'

                name        = (value.is_a?(Hash) && value[:full_name]) || param
                items = nil
                if description.kind_of?(Hash)
                  dataType = description[:type] || dataType
                  paramType = description[:paramType] || paramType
                  items = description[:items] ? description[:items] : nil
                  description = description[:notes]
                end

                parsed_params = {
                  paramType:    paramType,
                  name:         name,
                  description:  as_markdown(description),
                  type:         dataType,
                  dataType:     dataType,
                  required:     required,
                  items:  items
                }

                parsed_params.merge!({defaultValue: defaultValue}) if defaultValue

                parsed_params
              end.compact
            end

            def content_types_for(target_class)
              content_types = (target_class.settings[:content_types] || {}).values

              if content_types.empty?
                formats       = [target_class.settings[:format], target_class.settings[:default_format]].compact.uniq
                formats       = Grape::Formatter::Base.formatters({}).keys if formats.empty?
                content_types = Grape::ContentTypes::CONTENT_TYPES.select{|content_type, mime_type| formats.include? content_type}.values
              end

              content_types.uniq
            end

            def parse_info(info)
              {
                contact:            info[:contact],
                description:        info[:description],
                license:            info[:license],
                licenseUrl:         info[:license_url],
                termsOfServiceUrl:  info[:terms_of_service_url],
                title:              info[:title]
              }.delete_if{|_, value| value.blank?}
            end

            def parse_header_params(params)
              params ||= []

              params.map do |param, value|
                dataType    = 'String'
                description = value.is_a?(Hash) ? value[:description] : ''
                required    = value.is_a?(Hash) ? !!value[:required] : false
                defaultValue = value.is_a?(Hash) ? value[:defaultValue] : nil
                paramType   = "header"

                parsed_params = {
                  paramType:    paramType,
                  name:         param,
                  description:  as_markdown(description),
                  type:         dataType,
                  dataType:     dataType,
                  required:     required
                }

                parsed_params.merge!({defaultValue: defaultValue}) if defaultValue

                parsed_params
              end
            end

            def parse_path(path, version)
              # adapt format to swagger format
              parsed_path = path.gsub('(.:format)', @@hide_format ? '' : '.{format}')
              # This is attempting to emulate the behavior of
              # Rack::Mount::Strexp. We cannot use Strexp directly because
              # all it does is generate regular expressions for parsing URLs.
              # TODO: Implement a Racc tokenizer to properly generate the
              # parsed path.
              parsed_path = parsed_path.gsub(/:([a-zA-Z_]\w*)/, '{\1}')
              # add the version
              version ? parsed_path.gsub('{version}', version) : parsed_path
            end

            def parse_entity_name(name)
              entity_parts = name.to_s.split('Entities::')
              # entity_parts.reject! {|p| p == "Entity" || p == "Entities"}
              # entity_parts.join("::")
              entity_parts[-1]
            end

            def parse_items(items)
              {
                "$ref" => parse_entity_name(items)
              }
            end

            def parse_entity_models(models)
              result = {}
              models_copy = models.dup
              processed = []

              while models_copy.any?
                model = models_copy.shift
                next if processed.include?(model)
                if model.kind_of? Hash
                  props = model.map do |key, value|
                    value = value.clone
                    if value.kind_of? Hash
                      if value[:type].kind_of?(Class) && value[:type] <= Grape::Entity
                        models_copy += [value[:type]]
                        value[:type] = parse_entity_name(value[:type])
                      end

                      if value[:items].kind_of?(Class) and value[:items] <= Grape::Entity
                        models_copy += [value[:items]]
                        value[:items] = parse_entity_name(value[:items])
                      end
                      value[:items] = {:$ref => value[:items]} unless value[:items].kind_of?(Hash) or value[:items].nil?
                      next [key, value]
                    end
                    if value <= Grape::Entity
                      models_copy += [value]
                      next [key, {type: parse_entity_name(value)}]
                    end
                    case value.name
                      when 'Virtus::Attribute::Boolean'
                        [key,{type: 'boolean'}]
                      when 'Float', 'String', 'Integer'
                        [key,{type: value.downcase}]
                      else
                        [key,{type:value}]
                    end
                  end

                  result['Response'] = {
                    id: 'Response',
                    name: 'Response',
                    properties: Hash[props]
                  }
                  next
                end
                name        = parse_entity_name(model)
                properties  = {}
                property_types = {}

                model.exposures.each do |prop, data|
                  if prop_model = data[:with] || data[:using]
                    models_copy.unshift(prop_model)
                    property_types[data[:as] || prop] = parse_entity_name(prop_model)
                  end
                end

                model.documentation.each do |property_name, property_info|
                  properties[property_name] = property_info
                  if property_types[property_name]
                    properties[property_name][:type] = property_types[property_name] if property_info[:type].nil?
                    if property_info[:type] == 'array' && property_info[:items].nil?
                      properties[property_name][:items] = {:$ref => property_types[property_name]}
                    end
                  end
                  # rename Grape Entity's "desc" to "description"
                  if property_description = property_info.delete(:desc)
                    property_info[:description] = property_description
                  end
                end

                result[name] = {
                    id:         model.instance_variable_get(:@root) || name,
                    name:       model.instance_variable_get(:@root) || name,
                    properties: properties
                }
                processed << model
              end
              result
            end

            def parse_http_codes codes
              codes ||= {}
              codes.map do |k, v|
                {
                  code: k,
                  message: v,
                  #responseModel: ...
                }
              end
            end

            def try(*args, &block)
              if args.empty? && block_given?
                yield self
              elsif respond_to?(args.first)
                public_send(*args, &block)
              end
            end

            def strip_heredoc(string)
              indent = string.scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
              string.gsub(/^[ \t]{#{indent}}/, '')
            end

            def parse_base_path(base_path, request)
              if base_path.is_a?(Proc)
                base_path.call(request)
              elsif base_path.is_a?(String)
                URI(base_path).relative? ? URI.join(request.base_url, base_path).to_s : base_path
              else
                request.base_url
              end
            end
          end
        end
      end
    end
  end
end
