require File.expand_path(File.join(File.dirname(__FILE__), '/spec_helper'))

describe 'aws_ext' do
  context "AWS::S3::Bucket" do
    it "#exists? delegates to S3Object.exists?" do
      key = 'key'
      name = 'bucket'
      AWS::S3::S3Object.should_receive(:exists?).with(key, name)
      AWS::S3::Bucket.new(:name => name).exists?(key)
    end

    it "#find delegates to S3Object.find" do
      key = 'key'
      name = 'bucket'
      AWS::S3::S3Object.should_receive(:find).with(key, name)
      AWS::S3::Bucket.new(:name => name).find(key)
    end

    it "#each_object calls objects with max_keys and marker set" do
      key = 'key'
      initial_opts = {:max_keys => 1}
      initial_return = [stub('object', :key => key)]
      second_opts = {:max_keys => 1}
      second_opts[:marker] = key
      bucket = AWS::S3::Bucket.new(:name => 'bucket')
      bucket.should_receive(:objects).with(initial_opts).and_return(initial_return)
      bucket.should_receive(:objects).with(second_opts).and_return([])
      bucket.each_object(initial_opts) {}
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
