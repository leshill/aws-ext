require 'aws/s3'

module AWS
  module S3
    class S3Object
      def self.copy_across_buckets(src_bucket, src_key, dest_bucket, dest_key, acl_policy)
        headers = {'x-amz-copy-source' => path!(src_bucket, src_key)}
        if acl_policy == :copy
          returning put(path!(dest_bucket, dest_key), headers) do
            acl(dest_key, dest_bucket, acl(src_key, src_bucket))
          end
        else
          headers['x-amz-acl'] = acl_policy
          put(path!(dest_bucket, dest_key), headers)
        end
      end

      def copy_to_bucket(dest_bucket, dest_key = nil, acl_policy = :copy)
        self.class.copy_across_buckets(bucket.name, key, dest_bucket.name, dest_key ? dest_key : key, acl_policy)
      end
    end

    class Bucket
      def copy_to_bucket(copy_bucket)
        each_object do |obj|
          obj.copy_to_bucket(copy_bucket)
        end
      end

      def each_object(opts = {}, &block)
        opts = { :max_keys => 100 }.merge(opts)
        while (response = objects(opts).each {|obj| yield obj }).any? do
          opts[:marker] = response.last.key
        end
      end

      def exists?(key)
        S3Object.exists?(key, name)
      end

      def find(key)
        S3Object.find(key, name)
      end
    end
  end
end

