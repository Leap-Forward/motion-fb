# encoding: utf-8
unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

module Motion::Project
  class Config
    def facebook(opts = {})
      set_up_cf_bundle_url_types(opts[:app_id])

      self.info_plist["FacebookAppID"] = opts[:app_id]
      self.info_plist["FacebookDisplayName"] = opts[:display_name]

      set_up_whitelist
      set_up_application_query_schemes

      add_fb_pods(opts[:pods])
    end

    private

    def set_up_whitelist
      # Whitelist for iOS 9
      self.info_plist["NSAppTransportSecurity"] ||= {}
      self.info_plist["NSAppTransportSecurity"]["NSExceptionDomains"] ||= {}
      self.info_plist["NSAppTransportSecurity"]["NSExceptionDomains"].merge!({
        "facebook.com" => { "NSIncludesSubdomains" => true, "NSExceptionRequiresForwardSecrecy" => false },
        "fbcdn.net" => { "NSIncludesSubdomains" => true, "NSExceptionRequiresForwardSecrecy" => false },
        "akamaihd.net" => { "NSIncludesSubdomains" => true, "NSExceptionRequiresForwardSecrecy" => false },
      })
    end

    def set_up_application_query_schemes
      self.info_plist["LSApplicationQueriesSchemes"] ||= []
      self.info_plist["LSApplicationQueriesSchemes"] = self.info_plist["LSApplicationQueriesSchemes"] | ["fbapi", "fb-messenger-api", "fbauth2", "fbshareextension" ]
    end

    def set_up_cf_bundle_url_types(app_id)
      self.info_plist["CFBundleURLTypes"] ||= []

      found = false
      self.info_plist["CFBundleURLTypes"].each do |hash|
        puts hash
        if hash["CFBundleURLSchemes"] && hash["CFBundleURLSchemes"].is_a?(Array)
          hash["CFBundleURLSchemes"] << "fb#{app_id}"
          # hash["CFBundleURLSchemes"] << "fbauth2" 
          hash["CFBundleURLName"] ||= self.identifier
          found = true
        end
      end

      unless found
        puts 'not found, adding'
        self.info_plist["CFBundleURLTypes"] << {
          "CFBundleURLName" => self.identifier,
          "CFBundleURLSchemes" => [ "fb#{app_id}", "fbauth2" ]
        }
      end

      puts "Result: #{self.info_plist["CFBundleURLTypes"].inspect}"
    end

    def add_fb_pods(fb_pods)
      possible_pods = {
        core: {
          pod: 'FBSDKCoreKit',
          version: '~> 4.10.1'
        },
        login: {
          pod: 'FBSDKLoginKit',
          version: '~> 4.10.1'
        },
        messenger: {
          pod: 'FBSDKMessengerShareKit',
          version: '~> 1.3.2'
        },
        share: {
          pod: 'FBSDKShareKit',
          version: '~> 4.10.1'
        }
      }

      self.pods do
        possible_pods.each do |key, data|
          if fb_pods.include?(key)
            pod data[:pod], data[:version]
          end
        end
      end
    end
  end
end
