class Mongo::Collection
  revamp :insert_many do |_, _, documents, *args, hyper|
    created_at = Time.now
    documents.map { |it| it[:created_at ] = created_at }
    hyper.call documents, *args
  end
end
