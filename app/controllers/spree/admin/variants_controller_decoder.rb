Spree::Admin::VariantsController.class_eval do
      belongs_to 'spree/product', :find_by => :slug
      belongs_to 'spree/greetingcard', :find_by => :slug
      
      new_action.before :new_before
      before_action :load_data, only: [:new, :create, :edit, :update]

      # override the destroy method to set deleted_at value
      # instead of actually deleting the product.
      def destroy
        @variant = Variant.find(params[:id])
        if @variant.destroy
          flash[:success] = Spree.t('notice_messages.variant_deleted')
        else
          flash[:success] = Spree.t('notice_messages.variant_not_deleted')
        end

        respond_with(@variant) do |format|
          format.html { redirect_to admin_product_variants_url(params[:product_id]) }
          format.html { redirect_to admin_greetingcard_variants_url(params[:greetingcard_id]) }
          format.js  { render_js_for_destroy }
        end
      end

      protected
        def new_before
          master = @object.product.master
          @object.attributes = master.attributes.except('id', 'created_at', 'deleted_at',
                                                                        'sku', 'is_master')
          if master.default_price.present?
            # Shallow Clone of the default price to populate the price field.
            @object.default_price = master.default_price.clone
          end
          
          master = @object.greetingcard.master
          @object.attributes = master.attributes.except('id', 'created_at', 'deleted_at',
                                                                        'sku', 'is_master')
          if master.default_price.present?
            # Shallow Clone of the default price to populate the price field.
            @object.default_price = master.default_price.clone
          end
        end

        def collection
          @deleted = (params.key?(:deleted) && params[:deleted] == "on") ? "checked" : ""

          if @deleted.blank?
            @collection ||= super.includes(:default_price, option_values: :option_type)
          else
            @collection ||= Variant.only_deleted.where(product_id: parent.id)
            @collection ||= Variant.only_deleted.where(greetingcard_id: parent.id)
          end
          @collection
        end

      private
        def load_data
          @tax_categories = TaxCategory.order(:name)
        end
end
