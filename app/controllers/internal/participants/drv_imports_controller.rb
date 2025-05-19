module Internal
  module Participants
    class DrvImportsController < ApplicationController

      def index
        authorize! :index, Import
        @imports = @regatta.imports.drv.all
      end

      def show
        @import = @regatta.imports.drv.find(params[:id])
        authorize! :show, @import

        address_ids = (@import.results["representatives"].values + @import.results["clubs"].values).map { |d| d["id"] }
        @addresses = address_ids.any? && Address.where(id: address_ids) || []
      end

      def new
        authorize! :new, Import
      end

      def create
        authorize! :create, Import

        importer = Services::DrvImporter.new(@regatta)
        @import = importer.build_import(params[:xml])
        if importer.errors.none? && @import.save
          flash[:info] = helpers.success_message_for(:create, @import)
          redirect_to internal_participants_drv_import_path(@regatta, @import)
        else
          @import.errors.merge!(importer.errors)
          flash[:danger] = helpers.error_message_for(:create, @import)
          render :new
        end
      end

      def execute
        @import = @regatta.imports.drv.find(params[:drv_import_id])
        authorize! :execute, @import

        ActiveRecord::Base.transaction do
          importer = Services::DrvImporter.new(@regatta)
          if importer.execute!(@import) && @import.save
            flash[:info] = "Import erfolgreich."
          else
            @import.errors.merge!(importer.errors)
            flash[:danger] = "Import fehlgeschlagen: #{@import.errors.full_messages.join(", ")}"
            raise(ActiveRecord::Rollback)
          end
        end
        redirect_to internal_participants_drv_imports_path(@regatta)
      end

      def destroy
        @import = Import.drv.find(params[:id])
        authorize! :destroy, @import
        if @import.destroy
          flash[:success] = helpers.success_message_for(:destroy, @import)
        else
          flash[:danger] = helpers.error_message_for(:destroy, @import)
        end
        redirect_to internal_participants_drv_imports_path(@regatta)
      end

    end
  end
end
