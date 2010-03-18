# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rhosync}
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rhomobile"]
  s.date = %q{2010-03-12}
  s.description = %q{Rhosync Server and related command-line utilities for using Rhosync}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.md",
     "Rakefile",
     "bench/lib/bench.rb",
     "bench/lib/bench/cli.rb",
     "bench/lib/bench/logging.rb",
     "bench/lib/bench/mock_client.rb",
     "bench/lib/bench/result.rb",
     "bench/lib/bench/runner.rb",
     "bench/lib/bench/session.rb",
     "bench/lib/bench/statistics.rb",
     "bench/lib/bench/test_data.rb",
     "bench/lib/bench/timer.rb",
     "bench/lib/bench/utils.rb",
     "bench/scripts/cud_script.rb",
     "bench/scripts/helpers.rb",
     "bench/scripts/query_md_script.rb",
     "bench/scripts/query_script.rb",
     "bench/spec/logging_spec.rb",
     "bench/spec/mock_adapter_spec.rb",
     "bench/spec/mock_client_spec.rb",
     "bench/spec/result_spec.rb",
     "bench/spec/bench_spec_helper.rb",
     "bench/bench",
     "bench/benchapp/Rakefile",
     "bench/benchapp/build.yml",
     "bench/benchapp/rhoconfig.txt",
     "bench/benchapp/rhosync/config.yml",
     "bench/benchapp/rhosync/sources/mock_adapter.rb",
     "bench/benchapp/rhosync/benchapp.rb",
     "config.ru",
     "doc/public/css/print.css",
     "doc/public/css/screen.css",
     "doc/public/css/style.css",
     "lib/rhosync.rb",
     "lib/rhosync/api/create_user.rb",
     "lib/rhosync/api/delete_app.rb",
     "lib/rhosync/api/flushdb.rb",
     "lib/rhosync/api/get_api_token.rb",
     "lib/rhosync/api/get_db_doc.rb",
     "lib/rhosync/api/import_app.rb",
     "lib/rhosync/api/list_apps.rb",
     "lib/rhosync/api/set_db_doc.rb",
     "lib/rhosync/api/set_refresh_time.rb",
     "lib/rhosync/api/update_user.rb",
     "lib/rhosync/api/upload_file.rb",
     "lib/rhosync/api_token.rb",
     "lib/rhosync/app.rb",
     "lib/rhosync/bulk_data.rb",
     "lib/rhosync/bulk_data/bulk_data.rb",
     "lib/rhosync/bulk_data/bulk_data_job.rb",
     "lib/rhosync/bulk_data/syncdb.index.schema",
     "lib/rhosync/bulk_data/syncdb.schema",
     "lib/rhosync/client.rb",
     "lib/rhosync/client_sync.rb",
     "lib/rhosync/credential.rb",
     "lib/rhosync/document.rb",
     "lib/rhosync/indifferent_access.rb",
     "lib/rhosync/lock_ops.rb",
     "lib/rhosync/model.rb",
     "lib/rhosync/read_state.rb",
     "lib/rhosync/server.rb",
     "lib/rhosync/server/views/index.erb",
     "lib/rhosync/source.rb",
     "lib/rhosync/source_adapter.rb",
     "lib/rhosync/source_sync.rb",
     "lib/rhosync/store.rb",
     "lib/rhosync/user.rb",
     "lib/rhosync/version.rb",
     "spec/api/api_helper.rb",
     "spec/api/create_user_spec.rb",
     "spec/api/delete_app_spec.rb",
     "spec/api/flushdb_spec.rb",
     "spec/api/get_api_token_spec.rb",
     "spec/api/get_db_doc_spec.rb",
     "spec/api/import_app_spec.rb",
     "spec/api/list_apps_spec.rb",
     "spec/api/set_db_doc_spec.rb",
     "spec/api/set_refresh_time_spec.rb",
     "spec/api/update_user_spec.rb",
     "spec/api/upload_file_spec.rb",
     "spec/api_token_spec.rb",
     "spec/app_spec.rb",
     "spec/apps/rhotestapp/config.yml",
     "spec/apps/rhotestapp/rhotestapp.rb",
     "spec/apps/rhotestapp/sources/base_adapter.rb",
     "spec/apps/rhotestapp/sources/sample_adapter.rb",
     "spec/apps/rhotestapp/sources/simple_adapter.rb",
     "spec/apps/rhotestapp/sources/sub_adapter.rb",
     "spec/apps/rhotestapp/vendor/mygem-0.1.0/lib/mygem.rb",
     "spec/apps/rhotestapp/vendor/mygem-0.1.0/lib/mygem/mygem.rb",
     "spec/bulk_data/bulk_data_job_spec.rb",
     "spec/bulk_data/bulk_data_spec.rb",
     "spec/client_spec.rb",
     "spec/client_sync_spec.rb",
     "spec/doc/base.html",
     "spec/doc/doc_spec.rb",
     "spec/doc/footer.html",
     "spec/doc/header.html",
     "spec/document_spec.rb",
     "spec/model_spec.rb",
     "spec/perf/bulk_data_perf_spec.rb",
     "spec/perf/perf_spec_helper.rb",
     "spec/perf/store_perf_spec.rb",
     "spec/read_state_spec.rb",
     "spec/server/server_spec.rb",
     "spec/source_adapter_spec.rb",
     "spec/source_spec.rb",
     "spec/source_sync_spec.rb",
     "spec/spec_helper.rb",
     "spec/store_spec.rb",
     "spec/sync_states_spec.rb",
     "spec/testdata/1000-data.txt",
     "spec/testdata/compress-data.txt",
     "spec/testdata/testapptwo/config.yml",
     "spec/testdata/testapptwo/sources/sample_adapter.rb",
     "spec/user_spec.rb"
  ]
  s.homepage = %q{http://rhomobile.com/products/rhosync}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Rhosync Server}
  s.test_files = [
    "spec/api/api_helper.rb",
     "spec/api/create_user_spec.rb",
     "spec/api/delete_app_spec.rb",
     "spec/api/flushdb_spec.rb",
     "spec/api/get_api_token_spec.rb",
     "spec/api/get_db_doc_spec.rb",
     "spec/api/import_app_spec.rb",
     "spec/api/list_apps_spec.rb",
     "spec/api/set_db_doc_spec.rb",
     "spec/api/set_refresh_time_spec.rb",
     "spec/api/update_user_spec.rb",
     "spec/api/upload_file_spec.rb",
     "spec/api_token_spec.rb",
     "spec/app_spec.rb",
     "spec/apps/rhotestapp/rhotestapp.rb",
     "spec/apps/rhotestapp/sources/base_adapter.rb",
     "spec/apps/rhotestapp/sources/sample_adapter.rb",
     "spec/apps/rhotestapp/sources/simple_adapter.rb",
     "spec/apps/rhotestapp/sources/sub_adapter.rb",
     "spec/apps/rhotestapp/vendor/mygem-0.1.0/lib/mygem/mygem.rb",
     "spec/apps/rhotestapp/vendor/mygem-0.1.0/lib/mygem.rb",
     "spec/bulk_data/bulk_data_job_spec.rb",
     "spec/bulk_data/bulk_data_spec.rb",
     "spec/client_spec.rb",
     "spec/client_sync_spec.rb",
     "spec/doc/doc_spec.rb",
     "spec/document_spec.rb",
     "spec/model_spec.rb",
     "spec/perf/bulk_data_perf_spec.rb",
     "spec/perf/perf_spec_helper.rb",
     "spec/perf/store_perf_spec.rb",
     "spec/read_state_spec.rb",
     "spec/server/server_spec.rb",
     "spec/source_adapter_spec.rb",
     "spec/source_spec.rb",
     "spec/source_sync_spec.rb",
     "spec/spec_helper.rb",
     "spec/store_spec.rb",
     "spec/sync_states_spec.rb",
     "spec/testdata/testapptwo/sources/sample_adapter.rb",
     "spec/user_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.2.3"])
      s.add_runtime_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
      s.add_runtime_dependency(%q<rubyzip>, [">= 0.9.4"])
      s.add_runtime_dependency(%q<uuidtools>, [">= 2.1.1"])
      s.add_runtime_dependency(%q<redis>, [">= 0.2.0"])
      s.add_runtime_dependency(%q<resque>, [">= 1.6.0"])
      s.add_runtime_dependency(%q<sinatra>, [">= 0.9.2"])
      s.add_development_dependency(%q<jeweler>, [">= 1.4.0"])
      s.add_development_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_development_dependency(%q<rcov>, [">= 0.9.8"])
      s.add_development_dependency(%q<faker>, [">= 0.3.1"])
      s.add_development_dependency(%q<rack-test>, [">= 0.5.3"])
    else
      s.add_dependency(%q<json>, [">= 1.2.3"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
      s.add_dependency(%q<rubyzip>, [">= 0.9.4"])
      s.add_dependency(%q<uuidtools>, [">= 2.1.1"])
      s.add_dependency(%q<redis>, [">= 0.2.0"])
      s.add_dependency(%q<resque>, [">= 1.6.0"])
      s.add_dependency(%q<sinatra>, [">= 0.9.2"])
      s.add_dependency(%q<jeweler>, [">= 1.4.0"])
      s.add_dependency(%q<rspec>, [">= 1.3.0"])
      s.add_dependency(%q<rcov>, [">= 0.9.8"])
      s.add_dependency(%q<faker>, [">= 0.3.1"])
      s.add_dependency(%q<rack-test>, [">= 0.5.3"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.2.3"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 1.2.5"])
    s.add_dependency(%q<rubyzip>, [">= 0.9.4"])
    s.add_dependency(%q<uuidtools>, [">= 2.1.1"])
    s.add_dependency(%q<redis>, [">= 0.2.0"])
    s.add_dependency(%q<resque>, [">= 1.6.0"])
    s.add_dependency(%q<sinatra>, [">= 0.9.2"])
    s.add_dependency(%q<jeweler>, [">= 1.4.0"])
    s.add_dependency(%q<rspec>, [">= 1.3.0"])
    s.add_dependency(%q<rcov>, [">= 0.9.8"])
    s.add_dependency(%q<faker>, [">= 0.3.1"])
    s.add_dependency(%q<rack-test>, [">= 0.5.3"])
  end
end

