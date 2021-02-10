# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

module Jekyll
  module FrontendBuilder
    class Processor
      BABEL_EXE_PATH = "node_modules/.bin/babel"
      BABEL_POLYFILL_PATH = "node_modules/@babel/polyfill/dist/polyfill.min.js"

      attr_reader :site

      def initialize(site)
        @site = site
      end

      def process_site
        Jekyll.logger.info("Frontend Builder:", "Post-processing site")

        install_packages
        add_polyfills_to_site
        transpile_site
      end

      # Installs required NPM packages.
      def install_packages
        Jekyll.logger.debug("Frontend Builder:", "Installing NPM packages")
        prepare_npm_dir

        Dir.chdir npm_dir do
          system "npm", "install"
        end
      end

      # Copies Babel polyfills to site.
      def add_polyfills_to_site
        Jekyll.logger.debug("Frontend Builder:", "Copying polyfills")
        poly_src = File.expand_path(BABEL_POLYFILL_PATH, npm_dir)
        poly_dest = File.expand_path("babel-polyfill.js", site_js_dir)
        FileUtils.cp(poly_src, poly_dest)
      end

      # Runs Babel and transpiles site's JavaScript
      def transpile_site
        Jekyll.logger.debug("Frontend Builder:", "Transpiling JavaScript")
        Dir.chdir npm_dir do
          system BABEL_EXE_PATH, site_js_dir, "--out-dir", site_js_dir
        end
      end

      # Path where NPM packages are supposed to be installed
      # (typically +.jekyll-cache/FrontendBuilder+).
      def npm_dir
        site.in_cache_dir("FrontendBuilder")
      end

      # Path to site's JavaScript assets
      # (typically +_site/assets/js+).
      def site_js_dir
        File.expand_path("./assets/js", site.dest)
      end

      private

      def prepare_npm_dir
        FileUtils.mkdir_p npm_dir

        Dir.chdir(File.expand_path("lib/npm", gem_root_dir)) do
          FileUtils.cp "package.json", npm_dir
          FileUtils.cp "package-lock.json", npm_dir
        end
      end

      def gem_root_dir
        File.expand_path("../../..", __dir__)
      end
    end
  end
end