require 'spec_helper'

base_facts = {
  :osfamily               => 'RedHat',
  :puppet_ssldir          => '/dev/null/ssl',
  :puppet_config          => '/dev/null/puppet.conf',
  :mco_server_config      => nil,
  :mco_client_config      => nil,
}

MCO_CFG = {:server => '/etc/puppetlabs/mcollective/server.cfg', :client => '/etc/puppetlabs/mcollective/client.cfg'}
MCO_LIBDIR = '/opt/puppetlabs/mcollective/plugins'
MCO_PLUGIN_YAML = '/etc/puppetlabs/mcollective/facts.yaml'
MCO_LOGFILE = '/var/log/puppetlabs/mcollective.log'

describe 'puppet_agent::prepare' do
  context 'on RedHat' do
    let(:facts) { base_facts }

    [
      MCO_CFG,
      {:server => '/etc/mcollective/server.cfg'},
      {:client => '/etc/mcollective/client.cfg'}
    ].each do |mco_config|
      [
        {'libdir' => 'libdir', 'plugin.yaml' => 'plugins'},
        {'libdir' => "libdir:#{MCO_LIBDIR}", 'plugin.yaml' => "plugins:#{MCO_PLUGIN_YAML}"},
        {'libdir' => nil, 'plugin.yaml' => nil},
        nil
      ].each do |mco_settings|
        context "with mco_config = #{mco_config} and mco_settings = #{mco_settings}" do
          let(:facts) {
            base_facts.merge( {
              :mco_server_config => mco_config[:server],
              :mco_client_config => mco_config[:client],
              :mco_server_settings => mco_settings,
              :mco_client_settings => mco_settings,
            })
          }

          it { is_expected.to contain_file('/etc/puppetlabs/mcollective').with_ensure('directory') }

          mco_config.each do |node, cfg|
            if cfg
              it { is_expected.to contain_file(MCO_CFG[node]).with({
                'ensure' => 'file',
                'source' => cfg,
              }) }

              if mco_settings && mco_settings['libdir'] && !mco_settings['libdir'].include?(MCO_LIBDIR)
                it { is_expected.to contain_ini_setting("#{node}/libdir").with({
                  'section' => '',
                  'setting' => 'libdir',
                  'path'    => MCO_CFG[node],
                  'value'   => "#{MCO_LIBDIR}:#{mco_settings['libdir']}",
                }).that_requires("File[#{MCO_CFG[node]}]") }
              else
                it { is_expected.to_not contain_ini_setting("#{node}/libdir") }
              end

              if mco_settings && mco_settings['plugin.yaml'] && !mco_settings['plugin.yaml'].include?(MCO_PLUGIN_YAML)
                it { is_expected.to contain_ini_setting("#{node}/plugin.yaml").with({
                  'section' => '',
                  'setting' => 'plugin.yaml',
                  'path'    => MCO_CFG[node],
                  'value'   => "#{mco_settings['plugin.yaml']}:#{MCO_PLUGIN_YAML}",
                }).that_requires("File[#{MCO_CFG[node]}]") }
              else
                it { is_expected.to_not contain_ini_setting("#{node}/plugin.yaml") }
              end

              it { is_expected.to contain_ini_setting("#{node}/logfile").with({
                'section' => '',
                'setting' => 'logfile',
                'path'    => MCO_CFG[node],
                'value'   => MCO_LOGFILE,
              }).that_requires("File[#{MCO_CFG[node]}]") }
            else
              it { is_expected.to_not contain_file(MCO_CFG[node]) }
            end
          end
        end
      end
    end

    ['/etc/puppetlabs', '/etc/puppetlabs/puppet'].each do |dir|
      it { is_expected.to contain_file(dir).with_ensure('directory') }
    end

    it { is_expected.to contain_file('/etc/puppetlabs/puppet/puppet.conf').with({
      'ensure' => 'file',
      'source' => '/dev/null/puppet.conf',
    }) }

    it { is_expected.to contain_file('/etc/puppetlabs/puppet/ssl').with({
      'ensure'  => 'directory',
      'source'  => '/dev/null/ssl',
      'backup'  => 'false',
      'recurse' => 'true',
    }) }

    ['agent', 'main', 'master'].each do |section|
      ['allow_variables_with_dashes',
       'async_storeconfigs',
       'binder',
       'catalog_format',
       'certdnsnames',
       'certificate_expire_warning',
       'couchdb_url',
       'dbadapter',
       'dbconnections',
       'dblocation',
       'dbmigrate',
       'dbname',
       'dbpassword',
       'dbport',
       'dbserver',
       'dbsocket',
       'dbuser',
       'dynamicfacts',
       'http_compression',
       'httplog',
       'ignoreimport',
       'immutable_node_data',
       'inventory_port',
       'inventory_server',
       'inventory_terminus',
       'legacy_query_parameter_serialization',
       'listen',
       'localconfig',
       'manifestdir',
       'masterlog',
       'parser',
       'preview_outputdir',
       'puppetport',
       'queue_source',
       'queue_type',
       'rails_loglevel',
       'railslog',
       'report_serialization_format',
       'reportfrom',
       'rrddir',
       'rrdinterval',
       'sendmail',
       'smtphelo',
       'smtpport',
       'smtpserver',
       'ssldir',
       'stringify_facts',
       'tagmap',
       'templatedir',
       'thin_storeconfigs',
       'trusted_node_data',
       'zlib',
       'config_version',
       'manifest',
       'modulepath',
       'disable_warnings',
       'vardir',
       'rundir',
       'libdir',
       'confdir'].each do |setting|
         it { is_expected.to contain_ini_setting("#{section}/#{setting}").with_ensure('absent') }
       end
    end

    it { is_expected.to contain_class('puppet_agent::osfamily::redhat') }
  end
end
