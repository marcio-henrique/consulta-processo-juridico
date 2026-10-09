module Sources
  # Batches movement counts per lawsuit into a single GROUP BY query.
  class MovementsCount < GraphQL::Dataloader::Source
    def fetch(lawsuit_ids)
      counts = Movement.where(lawsuit_id: lawsuit_ids).group(:lawsuit_id).count
      lawsuit_ids.map { |id| counts.fetch(id, 0) }
    end
  end
end
