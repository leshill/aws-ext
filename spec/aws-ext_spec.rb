require File.expand_path(File.join(File.dirname(__FILE__), '/spec_helper'))

describe 'aws_ext' do
  context "AWS::S3::Bucket" do
    let(:key) { 'key' }
    let(:name) { 'bucket' }
    let(:bucket) { AWS::S3::Bucket.new(:name => name) }

    it "#exists? delegates to S3Object.exists?" do
      AWS::S3::S3Object.should_receive(:exists?).with(key, name)
      bucket.exists?(key)
    end

    it "#find delegates to S3Object.find" do
      AWS::S3::S3Object.should_receive(:find).with(key, name)
      bucket.find(key)
    end

    describe "#each_object" do
      let(:objects_options_1) { {:max_keys => 1} }
      let(:objects_returned_1) { [stub('object', :key => key)] }
      let(:objects_options_2) { objects_options_1[:marker] = key; objects_options_1 }
      let(:objects_returned_2) { [] }

      it "iterates objects with max_keys and marker set" do
        bucket.should_receive(:objects).with(objects_options_1).and_return(objects_returned_1)
        bucket.should_receive(:objects).with(objects_options_2).and_return(objects_returned_2)
        bucket.each_object(objects_options_1) {}
      end
    end
  end

  context "AWS::S3::S3Object" do
    it "#copy_to_bucket delegates to S3Object.copy_across_buckets with defaults" do
      key = 'key'
      src_bucket_name = 'src_bucket'
      src_bucket = AWS::S3::Bucket.new(:name => src_bucket_name)
      dest_bucket_name = 'dest_bucket'
      dest_bucket = AWS::S3::Bucket.new(:name => dest_bucket_name)
      AWS::S3::S3Object.should_receive(:copy_across_buckets).with(src_bucket_name, key, dest_bucket_name, key, :copy)
      AWS::S3::S3Object.new(:bucket => src_bucket, 'key' => key).copy_to_bucket(dest_bucket)
    end

    it "#copy_to_bucket delegates to S3Object.copy_across_buckets without defaults" do
      acl = :public_read
      src_key = 'src_key'
      dest_key = 'dest_key'
      src_bucket_name = 'src_bucket'
      src_bucket = AWS::S3::Bucket.new(:name => src_bucket_name)
      dest_bucket_name = 'dest_bucket'
      dest_bucket = AWS::S3::Bucket.new(:name => dest_bucket_name)
      AWS::S3::S3Object.should_receive(:copy_across_buckets).with(src_bucket_name, src_key, dest_bucket_name, dest_key, acl)
      AWS::S3::S3Object.new(:bucket => src_bucket, 'key' => src_key).copy_to_bucket(dest_bucket, dest_key, acl)
    end

    it ".copy_across_buckets when passed an acl_policy that is not :copy just puts the copy" do
      acl = :public_read
      src_key = 'src_key'
      dest_key = 'dest_key'
      src_bucket = 'src_bucket'
      dest_bucket = 'dest_bucket'
      headers = {}
      headers['x-amz-copy-source'] = AWS::S3::S3Object.path!(src_bucket, src_key)
      headers['x-amz-acl'] = acl
      AWS::S3::S3Object.should_receive(:put).with(AWS::S3::S3Object.path!(dest_bucket, dest_key), headers)
      AWS::S3::S3Object.copy_across_buckets(src_bucket, src_key, dest_bucket, dest_key, :public_read)
    end

    it ".copy_across_buckets when passed a :copy acl_policy puts the copy and copies the acl" do
      acl = :copy
      src_key = 'src_key'
      dest_key = 'dest_key'
      src_bucket = 'src_bucket'
      dest_bucket = 'dest_bucket'
      headers = {}
      headers['x-amz-copy-source'] = AWS::S3::S3Object.path!(src_bucket, src_key)
      returned_acl = 'returned_acl'
      AWS::S3::S3Object.should_receive(:acl).with(src_key, src_bucket).and_return(returned_acl)
      AWS::S3::S3Object.should_receive(:acl).with(dest_key, dest_bucket, returned_acl)
      AWS::S3::S3Object.should_receive(:put).with(AWS::S3::S3Object.path!(dest_bucket, dest_key), headers)
      AWS::S3::S3Object.copy_across_buckets(src_bucket, src_key, dest_bucket, dest_key, acl)
    end

  end
end
