module Document
  
  # Store wrapper methods for document
  def get_data(doctype,type=Hash)
    Store.get_data(docname(doctype),type)
  end
  
  def get_value(doctype)
    Store.get_value(docname(doctype))
  end
  
  def put_data(doctype,data,append=false)
    Store.put_data(docname(doctype),data,append)
  end
  
  def put_value(doctype,data)
    Store.put_value(docname(doctype),data)
  end
  
  def delete_data(doctype,data)
    Store.delete_data(docname(doctype),data)
  end
  
  def update_objects(doctype,updates)
    Store.update_objects(docname(doctype),updates)
  end
  
  def remove_objects(doctype,deletes)
    Store.delete_objects(docname(doctype),deletes)
  end
  
  def flash_data(doctype)
    Store.flash_data(docname(doctype))
  end
  
  def flash_source_data(doctype, from_source)
    self.source_name=from_source
    docnamestr = docname('') + doctype
    Store.flash_data(docnamestr)
  end
  
  def rename(srcdoctype,dstdoctype)
    Store.rename(docname(srcdoctype),docname(dstdoctype))
  end
  
  # Generate the fully-qualified docname
  def docname(doctype)
    "#{self.class.class_prefix(self.class)}:#{self.app_id}:#{self.doc_suffix(doctype)}"
  end
  
  # Update count for a given document
  def update_count(doctype,count)
    name = docname(doctype)
    value = Store.db.get(name).to_i + count
    Store.db.set(name,value < 0 ? 0 : value) 
  end
end