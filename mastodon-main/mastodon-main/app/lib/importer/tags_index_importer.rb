# frozen_string_literal: true

class Importer::TagsIndexImporter < Importer::BaseImporter
  def import!
    index.adapter.default_scope.find_in_batches(batch_size: @batch_size) do |tmp|
      in_work_unit(tmp) do |tags|
        bulk = Chewy::Index::Import::BulkBuilder.new(index, to_index: tags).bulk_body

        indexed = bulk.count { |entry| entry[:index] }
        deleted = bulk.count { |entry| entry[:delete] }

        Chewy::Index::Import::BulkRequest.new(index).perform(bulk)

        [indexed, deleted]
      end
    end

    wait!
  end

  private

  def index
    TagsIndex
  end
end
