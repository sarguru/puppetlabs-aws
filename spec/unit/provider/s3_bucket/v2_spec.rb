require 'spec_helper'

TYPE = Puppet::Type.type(:s3_bucket)

describe TYPE.provider(:v2) do
  let(:params) { { name: 'test-web-sg', region: AWS_REGION } }
  let(:resource) { TYPE.new(params) }
  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances.first }
  let(:s3) { provider.s3_client }

  before(:each) { stub_s3 }
  after(:each) { resource.provider.class.reset_instances! }

  describe '.prefetch' do
    it 'fetches resources' do
      s3.expects(:list_buckets).returns(stub(buckets: [stub(name: stub)]))
      s3.expects(:get_bucket_location).returns(stub(location_constraint: ''))
      s3.expects(:get_bucket_policy).returns(stub policy: StringIO.new("{}"))
      provider.class.instances
      provider.class.prefetch({})
    end
  end

  describe '#exists?' do
    it 'falsy' do
      expect(provider.exists?).to be_falsy
    end

    it 'truthy' do
      s3.expects(:list_buckets).returns(stub(buckets: [stub(name: stub)]))
      s3.expects(:get_bucket_location).returns(stub(location_constraint: ''))
      s3.expects(:get_bucket_policy).returns(stub policy: StringIO.new("{}"))
      expect(instance.exists?).to be_truthy
    end
  end

  describe '#create' do
    it 'sends request to create bucket' do
      s3.expects(:create_bucket).returns(true)
      provider.expects(:instances).returns([])
      expect(provider.create).to be_truthy
    end
  end

  describe '#destroy' do
    it 'sends request to destroy bucket' do
      s3.expects(:delete_bucket).returns(true)
      provider.expects(:instances).returns([])
      expect(provider.destroy).to be_truthy
    end
  end

  describe '#policy=' do
    it 'creates policy' do
      policy_example = [{'a' => 1}, {'b' => 2}]
      s3.expects(:put_bucket_policy).
        with(bucket: params[:name],
             policy: JSON.dump('Statement' => policy_example)).
        returns(true)
      provider.policy = policy_example
    end

    it 'deletes policy if absent' do
      s3.expects(:delete_bucket_policy).returns(true)
      provider.expects(:policy).returns(true).twice
      provider.policy = :absent
    end
  end

  context 'with policy param' do
    let(:params) { super().merge(policy: [{this_value_is_false: true}]) }

    describe '#create' do
      it 'passes policy to setter' do
        s3.expects(:create_bucket).returns(true)
        provider.class.expects(:instances).returns([])
        provider.expects(:policy=).with([{this_value_is_false: true}]).returns(true)
        provider.create
      end
    end
  end
end
