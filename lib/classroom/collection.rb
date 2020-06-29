class Mongo::Collection
  revamp :insert_many do |_, _, documents, *args, hyper|
    now = Time.now
    documents.map do |it|
      it[:created_at] = now
      it[:updated_at] = now
    end
    hyper.call documents, *args
  end
end
