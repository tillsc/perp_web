module Services
  class NumberDraw

    def initialize(sector_size:)
      @sector_size = sector_size
    end

    # Returns [{ participant:, number: }, ...] only for participants without an existing number.
    # New numbers start after the highest existing number in the passed participants.
    # Caller is responsible for loading participants with :team preloaded.
    def call(participants)
      @participants = participants.to_a
      start_from = @participants.filter_map(&:number).select(&:positive?).max.to_i + 1
      @participants = @participants.reject { |p| p.number&.positive? }

      return [] if @participants.empty?

      count = @participants.size
      effective_size = [[@sector_size, 1].max, count].min
      num_sectors = (count.to_f / effective_size).ceil
      sectors = Array.new(num_sectors) { [] }

      pos = 0.0
      current_club = nil

      sorted_participants.each do |p, club_count|
        club_name = p.team&.name

        pos = 0.0 if club_count > 1 && club_name != current_club
        current_club = club_name

        step = count.to_f / ((club_count - 0.9) * effective_size)
        insert_into_sector(sectors, pos.floor, effective_size, p, rand(256))
        pos = (pos + step) % num_sectors
      end

      sectors.flatten.each_with_index.map { |e, i| { number: start_from + i, participant: e[:participant] } }
    end

    private

    def sorted_participants
      club_counts = @participants.each_with_object(Hash.new(0)) { |p, h| h[p.team&.name] += 1 }

      # Clubs with multiple boats come first (and are grouped by name) so the
      # spread algorithm can reset pos at the start of each multi-boat club block.
      @participants
        .map     { |p| [p, club_counts[p.team&.name].to_i, rand] }
        .sort_by { |p, cc, r| [-cc, cc > 1 ? p.team&.name.to_s : '', r] }
        .map     { |p, cc, _| [p, cc] }
    end

    def insert_into_sector(sectors, target, sector_size, participant, sort_val)
      offs = 0
      loop do
        idx = target + offs
        if idx >= 0 && idx < sectors.size && sectors[idx].size < sector_size
          ins = sectors[idx].bsearch_index { |e| e[:sort] >= sort_val } || sectors[idx].size
          sectors[idx].insert(ins, { participant: participant, sort: sort_val })
          return
        end
        offs = offs <= 0 ? -offs + 1 : -offs
        break if offs > sectors.size
      end
    end

  end
end
