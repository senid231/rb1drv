module Rb1drv
  class OneDriveItem
    attr_reader :id, :name, :eTag, :size, :mtime, :ctime, :muser, :cuser, :parent_path, :remote_id, :remote_drive_id
    protected
    def initialize(od, api_hash)
      @od = od
      %w(id name eTag size).each do |key|
        instance_variable_set("@#{key}", api_hash[key])
      end
      @remote_drive_id = api_hash.fetch('remoteItem', {}).fetch('parentReference', {})['driveId']
      @remote_id = api_hash.fetch('remoteItem', {})['id']
      @mtime = Time.iso8601(api_hash.fetch('lastModifiedDateTime'))
      @ctime = Time.iso8601(api_hash.fetch('createdDateTime'))
      @muser = api_hash.fetch('lastModifiedBy', {}).fetch('user', {})['displayName'] || 'N/A'
      @cuser = api_hash.fetch('createdBy', {}).fetch('user', {})['displayName'] || 'N/A'
      @parent_path = api_hash.fetch('parentReference', {})['path']
      @remote = api_hash.has_key?('remoteItem')
    end

    # Create subclass instance by checking the item type
    #
    # @return [OneDriveFile, OneDriveDir] instanciated drive item
    def self.smart_new(od, item_hash)
      if item_hash['remoteItem']
        item_hash['remoteItem'].each do |key, value|
          item_hash[key] ||= value
        end
      end
      if item_hash['file']
        OneDriveFile.new(od, item_hash)
      elsif item_hash['folder']
        OneDriveDir.new(od, item_hash)
      elsif item_hash.fetch('error', {})['code'] == 'itemNotFound'
        OneDrive404.new
      else
        item_hash
      end
    end

    # @return [String] absolute path of current item
    def absolute_path
      if @parent_path
        File.join(@parent_path, @name)
      else
        @name
      end
    end

    # TODO: API endpoint does not play well with remote files
    #
    # @return [String] api reference path of current object
    def api_path
      if remote?
        "drives/#{@remote_drive_id}/items/#{@remote_id}"
      else
        "drive/items/#{@id}"
      end
    end

    # TODO: API endpoint does not play well with remote files
    #
    # @return [Boolean] whether it's shared by others
    def remote?
      @remote
    end
  end
end
