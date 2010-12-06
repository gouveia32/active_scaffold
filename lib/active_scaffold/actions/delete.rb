module ActiveScaffold::Actions
  module Delete
    def self.included(base)
      base.before_filter :delete_authorized_filter, :only => [:destroy]
    end

    def destroy
      if request.get?
        # someone has disabled javascript, we have to show confirmation form first
        @record = find_if_allowed(params[:id], :read) if params[:id] && params[:id] && params[:id].to_i > 0
        respond_to_action(:action_confirmation)
      else
        do_destroy
        respond_to_action(:destroy)
      end
    end

    protected
    def destroy_respond_to_html
      flash[:info] = as_(:deleted_model, :model => @record.to_label) if self.successful?
      return_to_main
    end

    def destroy_respond_to_js
      render(:action => 'destroy')
    end

    def destroy_respond_to_xml
      render :xml => successful? ? "" : response_object.to_xml(:only => active_scaffold_config.list.columns.names), :content_type => Mime::XML, :status => response_status
    end

    def destroy_respond_to_json
      render :text => successful? ? "" : response_object.to_json(:only => active_scaffold_config.list.columns.names), :content_type => Mime::JSON, :status => response_status
    end

    def destroy_respond_to_yaml
      render :text => successful? ? "" : Hash.from_xml(response_object.to_xml(:only => active_scaffold_config.list.columns.names)).to_yaml, :content_type => Mime::YAML, :status => response_status
    end

    def destroy_find_record
      @record = find_if_allowed(params[:id], :delete)
    end

    # A simple method to handle the actual destroying of a record
    # May be overridden to customize the behavior
    def do_destroy
      @record ||= destroy_find_record
      begin
        self.successful = @record.destroy
      rescue
        flash[:warning] = as_(:cant_destroy_record, :record => @record.to_label)
        self.successful = false
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def delete_authorized?(record = nil)
      (!nested? || !nested.readonly?) && authorized_for?(:crud_type => :delete)
    end
    private
    def delete_authorized_filter
      link = active_scaffold_config.delete.link || active_scaffold_config.delete.class.link
      raise ActiveScaffold::ActionNotAllowed unless self.send(link.security_method)
    end
    def destroy_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.delete.formats).uniq
    end
  end
end
