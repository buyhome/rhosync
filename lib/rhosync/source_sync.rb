module Rhosync
  class SourceSync
    attr_reader :adapter
    
    def initialize(source)
      @source = source
      raise InvalidArgumentError.new('Invalid source') if @source.nil?
      raise InvalidArgumentError.new('Invalid app for source') unless @source.app
      @adapter = SourceAdapter.create(@source)
    end
    
    # CUD Operations
    def create(client_id)
      _measure_and_process_cud('create',client_id)
    end
    
    def update(client_id)
      _measure_and_process_cud('update',client_id)
    end
    
    def delete(client_id)
      _measure_and_process_cud('delete',client_id)
    end
    
    # Read Operation; params are query arguments
    def read(client_id=nil,params=nil)
      _read('query',client_id,params)
    end
    
    def search(client_id=nil,params=nil)
      return if _auth_op('login',client_id) == false
      res = _read('search',client_id,params)
      _auth_op('logoff',client_id)
      res
    end

    def process_cud(client_id)
      if @source.cud_queue or @source.queue
        async(:cud,@source.cud_queue || @source.queue,client_id)
      else
        do_cud(client_id)
      end   
    end
    
    def do_cud(client_id)
      return if _auth_op('login') == false
      self.create(client_id)
      self.update(client_id)
      self.delete(client_id)
      _auth_op('logoff')
    end
    
    def process_query(params=nil)
      if @source.query_queue or @source.queue
        async(:query,@source.query_queue || @source.queue,nil,params)
      else
        do_query(params)
      end   
    end
    
    def do_query(params=nil)
      result = nil
      @source.if_need_refresh do
        Stats::Record.update("source:query:#{@source.name}") do
          if _auth_op('login')
            result = self.read(nil,params)
            _auth_op('logoff')
          end
          # re-wind refresh time in case of error
          query_failure = Store.exists?(@source.docname(:errors))
          @source.rewind_refresh_time(query_failure)
        end
      end
      result
    end
    
    # Enqueue a job for the source based on job type
    def async(job_type,queue_name,client_id=nil,params=nil)
      SourceJob.queue = queue_name
      Resque.enqueue(SourceJob,job_type,@source.id,
        @source.app_id,@source.user_id,client_id,params)
    end
    
    def fast_insert(new_objs, timeout=10,raise_on_expire=false)
      @source.lock(:md,timeout,raise_on_expire) do |s|
        diff_count = new_objs.size
        @source.put_data(:md, new_objs, true)
        @source.update_count(:md_size,diff_count)
      end
    end
    
    def fast_update(orig_hash, new_hash, timeout=10,raise_on_expire=false)
      @source.lock(:md,timeout,raise_on_expire) do |s|
        @source.delete_data(:md, orig_hash)
        @source.put_data(:md, new_hash, true)
      end
    end 
    
    def fast_delete(delete_objs, timeout=10,raise_on_expire=false)
      @source.lock(:md,timeout,raise_on_expire) do |s|
        diff_count = -delete_objs.size
        @source.delete_data(:md, delete_objs)
        @source.update_count(:md_size,diff_count)
      end
    end
    
    def push_objects(objects,timeout=10,raise_on_expire=false,rebuild_md=true)
      @source.lock(:md,timeout,raise_on_expire) do |s|
        diff_count = 0
        # in case of rebuild_md
        # we clean-up and rebuild the whole :md doc
        # on every request
        if(rebuild_md)
          doc = @source.get_data(:md)
          orig_doc_size = doc.size
          objects.each do |id,obj|
            doc[id] ||= {}
            doc[id].merge!(obj)
          end  
          diff_count = doc.size - orig_doc_size
          @source.put_data(:md,doc)
        else
          # if rebuild_md == false
          # we only operate on specific set values
          # which brings a big optimization
          # in case of small transactions
          diff_count = @source.update_objects(:md, objects)
        end
        
        @source.update_count(:md_size,diff_count)
      end      
    end    

    def push_deletes(objects,timeout=10,raise_on_expire=false,rebuild_md=true)
      @source.lock(:md,timeout,raise_on_expire) do |s|
        diff_count = 0
        if(rebuild_md)
          # in case of rebuild_md
          # we clean-up and rebuild the whole :md doc
          # on every request
          doc = @source.get_data(:md)
          orig_doc_size = doc.size
          objects.each do |id|
            doc.delete(id)
          end  
          diff_count = doc.size - orig_doc_size
          @source.put_data(:md,doc)
        else
          # if rebuild_md == false
          # we only operate on specific set values
          # which brings a big optimization
          # in case of small transactions
          diff_count = -@source.remove_objects(:md, objects)
        end
        
        @source.update_count(:md_size,diff_count)
      end    
    end
    
    private
    def _auth_op(operation,client_id=-1)
      edockey = client_id == -1 ? @source.docname(:errors) :
        Client.load(client_id,{:source_name => @source.name}).docname(:search_errors)
      begin
        Store.flash_data(edockey) if operation == 'login'
        @adapter.send operation
      rescue Exception => e
        log "SourceAdapter raised #{operation} exception: #{e}"
        Store.put_data(edockey,{"#{operation}-error"=>{'message'=>e.message}},true)
        return false
      end
      true
    end
    
    def _process_create(client,key,value,links,creates,deletes)
      # Perform operation
      link = @adapter.create value
      # Store object-id link for the client
      # If we have a link, store object in client document
      # Otherwise, store object for delete on client
      if link
        links ||= {}
        links[key] = { 'l' => link.to_s }
        creates ||= {}
        creates[link.to_s] = value
      else
        deletes ||= {}
        deletes[key] = value
      end
    end
    
    def _process_update(client,key,value)
      begin
        # Add id to object hash to forward to backend call
        value['id'] = key
        # Perform operation
        @adapter.update value
      rescue Exception => e
        # TODO: This will be slow!
        cd = client.get_data(:cd)
        client.put_data(:update_rollback,{key => cd[key]},true) if cd[key]
        raise e
      end
    end
    
    def _process_delete(client,key,value,dels)
      value['id'] = key
      # Perform operation
      @adapter.delete value
      dels ||= {}
      dels[key] = value
    end
    
    def _measure_and_process_cud(operation,client_id)
      Stats::Record.update("source:#{operation}:#{@source.name}") do
        _process_cud(operation,client_id)
      end
    end
    
    def _process_cud(operation,client_id)
      errors,links,deletes,creates,dels = {},{},{},{},{}
      client = Client.load(client_id,{:source_name => @source.name})
      modified = client.get_data(operation)
      # Process operation queue, one object at a time
      modified.each do |key,value|
        begin
          # Remove object from queue
          modified.delete(key)
          # Call on source adapter to process individual object
          case operation
          when 'create'
            _process_create(client,key,value,links,creates,deletes)
          when 'update'
            _process_update(client,key,value)
          when 'delete'
            _process_delete(client,key,value,dels)
          end
        rescue Exception => e
          log "SourceAdapter raised #{operation} exception: #{e}"
          log e.backtrace.join("\n")
          errors ||= {}
          errors[key] = value
          errors["#{key}-error"] = {'message'=>e.message}
          break
        end
      end
      # Record operation results
      { "delete_page" => deletes,
        "#{operation}_links" => links,
        "#{operation}_errors" => errors }.each do |doctype,value|
        client.put_data(doctype,value,true) unless value.empty?
      end
      unless operation != 'create' and creates.empty?
        client.put_data(:cd,creates,true)
        client.update_count(:cd_size,creates.size)
        @source.lock(:md) do |s| 
          s.put_data(:md,creates,true)
          s.update_count(:md_size,creates.size)
        end
      end
      if operation == 'delete'
        # Clean up deleted objects from master document and corresponding client document
        client.delete_data(:cd,dels)
        client.update_count(:cd_size,-dels.size)
        @source.lock(:md) do |s| 
          s.delete_data(:md,dels)
          s.update_count(:md_size,-dels.size)
        end
      end
      # Record rest of queue (if something in the middle failed)
      if modified.empty?
        client.flash_data(operation)
      else
        client.put_data(operation,modified)
      end
      modified.size
    end
    
    # Metadata Operation; source adapter returns json
    def _get_data(method)
      if @adapter.respond_to?(method)
        data = @adapter.send(method) 
        if data
          @source.put_value(method,data)
          if method == :schema
            parsed = JSON.parse(data)
            schema_version = parsed['version']
            raise "Mandatory version key is not defined in source adapter schema method" if schema_version.nil? 
            @source.put_value("#{method}_sha1",Digest::SHA1.hexdigest(schema_version))
          else
            @source.put_value("#{method}_sha1",Digest::SHA1.hexdigest(data))
          end
        end
      end
    end
    
    # Read Operation; params are query arguments
    def _read(operation,client_id,params=nil)
      errordoc = nil
      begin
        if operation == 'search'
          client = Client.load(client_id,{:source_name => @source.name})
          errordoc = client.docname(:search_errors)
          compute_token(client.docname(:search_token))
          @adapter.search(params)
          @adapter.save(client.docname(:search))
        else
          errordoc = @source.docname(:errors)
          [:metadata,:schema].each do |method|
            _get_data(method)
          end  
          @adapter.do_query(params)
        end
        # operation,sync succeeded, remove errors
        Store.lock(errordoc) do
          Store.flash_data(errordoc)
        end
      rescue Exception => e
        # store sync,operation exceptions to be sent to all clients for this source/user
        log "SourceAdapter raised #{operation} exception: #{e}"
        Store.lock(errordoc) do
          Store.put_data(errordoc,{"#{operation}-error"=>{'message'=>e.message}},true)
        end
      end
      true
    end
  end
end
