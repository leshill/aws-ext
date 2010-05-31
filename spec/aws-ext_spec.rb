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

      describe "#copy_to_bucket" do
        let(:copy_bucket) { AWS::S3::Bucket.new(:name => 'copy_bucket') }
        let(:s3object) { stub }

        it "iterates over each object" do
          bucket.should_receive(:each_object)
          bucket.copy_to_bucket(copy_bucket)
        end

        it "copies each object to the destination bucket" do
          s3object.should_receive(:copy_to_bucket).with(copy_bucket)
          bucket.stub(:each_object).and_yield(s3object)
          bucket.copy_to_bucket(copy_bucket)
        end
      end
    end
  end

  context "AWS::S3::S3Object" do
    let(:src_key) { 'src_key' }
    let(:dest_key) { 'dest_key' }
    let(:src_bucket) { 'src_bucket' }
    let(:dest_bucket) { 'dest_bucket' }

    describe "#copy_to_bucket" do
      let(:s3bucket_src) { AWS::S3::Bucket.new(:name => src_bucket) }
      let(:s3bucket_dest) { AWS::S3::Bucket.new(:name => dest_bucket) }
      let(:s3object) { AWS::S3::S3Object.new(:bucket => s3bucket_src, 'key' => src_key) }

      it "#copy_to_bucket delegates to S3Object.copy_across_buckets with defaults" do
        AWS::S3::S3Object.should_receive(:copy_across_buckets).with(src_bucket, src_key, dest_bucket, src_key, :copy)
        s3object.copy_to_bucket(s3bucket_dest)
      end

      it "#copy_to_bucket delegates to S3Object.copy_across_buckets without defaults" do
        acl = :public_read
        AWS::S3::S3Object.should_receive(:copy_across_buckets).with(src_bucket, src_key, dest_bucket, dest_key, acl)
        s3object.copy_to_bucket(s3bucket_dest, dest_key, acl)
      end
    end

    describe ".copy_across_buckets" do
      let(:dest_path) { AWS::S3::S3Object.path!(dest_bucket, dest_key) }
      let(:copy_header) { {'x-amz-copy-source' => AWS::S3::S3Object.path!(src_bucket, src_key)} }

      it "delegates to put with the destination path" do
        AWS::S3::S3Object.should_receive(:put).with(dest_path, anything)
        AWS::S3::S3Object.copy_across_buckets(src_bucket, src_key, dest_bucket, dest_key)
      end

      it "delegates to put with copy source set" do
        AWS::S3::S3Object.should_receive(:put).with(anything, hash_including(copy_header))
        AWS::S3::S3Object.copy_across_buckets(src_bucket, src_key, dest_bucket, dest_key)
      end

      it "delegates to put with the requested canned acl policy" do
        acl = :private
        acl_header = {'x-amz-acl' => acl }
        AWS::S3::S3Object.should_receive(:put).with(anything, hash_including(acl_header))
        AWS::S3::S3Object.copy_across_buckets(src_bucket, src_key, dest_bucket, dest_key, acl)
      end

      it "when acl is :copy, copies the existing acl policy" do
        returned_acl = 'returned_acl'
        AWS::S3::S3Object.should_receive(:acl).with(src_key, src_bucket).and_return(returned_acl)
        AWS::S3::S3Object.should_receive(:acl).with(dest_key, dest_bucket, returned_acl)
        AWS::S3::S3Object.stub(:put)
        AWS::S3::S3Object.copy_across_buckets(src_bucket, src_key, dest_bucket, dest_key, :copy)
      end
    end

  end
end
