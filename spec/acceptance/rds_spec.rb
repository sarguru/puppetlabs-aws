require 'spec_helper_acceptance'
require 'securerandom'

describe "rds_instance" do

  before(:all) do
    @default_region = AWS_REGION
    @aws = AwsHelper.new(@default_region)
    @template = 'rds.pp.tmpl'
  end

  def get_rds_instance(name)
    rds_instances = @aws.get_rds_instance(name)
    expect(rds_instances.count).to eq(1)
    rds_instances.first
  end

  describe 'should create a new database' do

    before(:all) do
      @config = {
        :name => "v#{PuppetManifest.rds_id}-#{SecureRandom.hex}",
        :ensure => 'present',
        :region => @default_region,
        :db_name =>  'puppet',
        :engine => 'mysql',
        :allocated_storage => 5,
        :engine_version => '5.6.19a',
        :license_model => 'general-public-license',
        :storage_type => 'gp2',
        :db_instance_class => 'db.m3.medium',
        :master_username => 'puppet',
        :master_user_password => 'pullth3stringz',
        :multi_az => false,
        :skip_final_snapshot => true,
      }

      manifest = PuppetManifest.new(@template, @config)
      manifest.apply
      @rds_instance = get_rds_instance(@config[:name])
    end

    after(:all) do
      new_config = @config.update({:ensure => 'absent'})
      PuppetManifest.new(@template, new_config).apply
    end

    it 'with the specified name' do
      expect(@rds_instance.db_instance_identifier).to eq(@config[:name])
    end

    it 'with the specified db_name' do
      expect(@rds_instance.db_name).to eq(@config[:db_name])
    end

    it 'with the specified engine' do
      expect(@rds_instance.engine).to eq(@config[:engine])
    end

    it 'with the specified license' do
      expect(@rds_instance.license_model).to eq(@config[:license_model])
    end

    it 'with the specified engine version' do
      expect(@rds_instance.engine_version).to eq(@config[:engine_version])
    end

    it 'with the specified db name' do
      expect(@rds_instance.db_name).to eq(@config[:db_name])
    end

    it 'with the specified username' do
      expect(@rds_instance.master_username).to eq(@config[:master_username])
    end

    it 'with the specified storage' do
      expect(@rds_instance.allocated_storage).to eq(@config[:allocated_storage])
    end

    it 'with the specified instance class' do
      expect(@rds_instance.db_instance_class).to eq(@config[:db_instance_class])
    end

    it 'with the specified storage type' do
      expect(@rds_instance.storage_type).to eq(@config[:storage_type])
    end

    it 'not associated with a VPC (EC2-Classic accounts only)' do
      unless @aws.vpc_only?
        expect(@rds_instance.vpc_security_groups).to be_empty
        expect(@rds_instance.db_subnet_group).to be_nil
      end
    end

    context 'when viewing the database via puppet resource' do

      before(:all) do
        @result = TestExecutor.puppet_resource('rds_instance', {:name => @config[:name]}, '--modulepath ../')
      end

      it 'ensure is correct' do
        regex = /(ensure)(\s*)(=>)(\s*)('present')/
        expect(@result.stdout).to match(regex)
      end

      it 'allocated storage is correct' do
        regex = /(allocated_storage)(\s*)(=>)(\s*)('#{@config[:allocated_storage]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'db instance class is correct' do
        regex = /(db_instance_class)(\s*)(=>)(\s*)('#{@config[:db_instance_class]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'engine is correct' do
        regex = /(engine)(\s*)(=>)(\s*)('#{@config[:engine]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'license model is correct' do
        regex = /(license_model)(\s*)(=>)(\s*)('#{@config[:license_model]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'master username is correct' do
        regex = /(master_username)(\s*)(=>)(\s*)('#{@config[:master_username]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'region is correct' do
        regex = /(region)(\s*)(=>)(\s*)('#{@config[:region]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'storage type is correct' do
        regex = /(storage_type)(\s*)(=>)(\s*)('#{@config[:storage_type]}')/
        expect(@result.stdout).to match(regex)
      end
    end

  end
end
