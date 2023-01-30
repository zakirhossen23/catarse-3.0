# frozen_string_literal: true

# run with .pgpass file and command:
# DB_USER=dbuser DB_NAME=dnmame DB_HOST=localhost

set :job_template, nil
set :output, { standard: '~/cron.log', error: '~/cron.log' }

def generate_psql_c(view) # rubocop:disable Metrics/MethodLength
  only_view = view.split('.')[1]
  parsed_name = view.start_with?('"') ? view.inspect : view
  %{ echo "DO language plpgsql \\$\\$BEGIN
  RAISE NOTICE 'begin updating #{parsed_name} %1',now();
  IF NOT EXISTS (
    SELECT true FROM pg_stat_activity WHERE pg_backend_pid() <> pid AND query ~* 'refresh materialized .*#{only_view}'
  ) THEN
     RAISE NOTICE 'refreshing view #{parsed_name} %1',now();
     REFRESH MATERIALIZED VIEW CONCURRENTLY #{parsed_name};
    RAISE NOTICE 'view refreshed #{parsed_name} %1',now();
  END IF;
 END\\$\\$;" | psql -U #{ENV['DB_USER']} -h #{ENV['DB_HOST']} -d #{ENV['DB_NAME']}
}
end

def generate_psql_function(function)
  %{ echo "DO language plpgsql \\$\\$BEGIN
      RAISE NOTICE 'begin updating #{function}() %1',now();
      IF NOT EXISTS (SELECT true FROM pg_stat_activity WHERE pg_backend_pid() <> pid AND query ~* '#{function}') THEN
        RAISE NOTICE 'running function #{function}() %1',now();
          PERFORM #{function}();
        RAISE NOTICE 'function runned #{function}() %1',now();
      END IF;
      END\\$\\$;" | psql -U #{ENV['DB_USER']} -h #{ENV['DB_HOST']} -d #{ENV['DB_NAME']}
  }
end

%w[
  "1".finished_projects
  "1".statistics
  "1".statistics_music
  "1".category_totals
  "1".statistics_publicacoes
  "1".statistics_jornalismo
].each do |v|
  every 1.hour do
    command generate_psql_c(v)
  end
end

%w[
  "1".user_totals
].each do |v|
  every 10.minutes do
    command generate_psql_c(v)
  end
end

%w[
  public.moments_project_pageviews
  public.moments_project_pageviews_inferuser
].each do |v|
  every 1.day, at: '00:30 am' do
    command generate_psql_c(v)
  end
end

%w[
  public.moments_project_start
  public.moments_project_start_inferuser
].each do |v|
  every 1.day, at: '00:30 am' do
    command generate_psql_c(v)
  end
end

%w[
  public.project_visitors_per_day_tbl_refresh
  public.project_fiscal_data_tbl_refresh
].each do |v|
  every 1.hour do
    command generate_psql_function(v)
  end
end

%w[
  stats.daily_function
].each do |v|
  every 1.day, at: '00:30 am' do
    command generate_psql_function(v)
  end
end
