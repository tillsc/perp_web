require 'open-uri'
require 'fileutils'

namespace :export do

  desc "Export finish cam images to tmp/cnn_data to train AI (detection)"
  task cnn_raw_data: :environment do
    base_dir = Rails.root.join("tmp/cnn_data")
    images_dir = base_dir.join("images")
    labels_dir = base_dir.join("labels")

    FileUtils.mkdir_p(images_dir)
    FileUtils.mkdir_p(labels_dir)

    regatta = Regatta.find(Parameter.current_regatta_id)
    mp = regatta.measuring_points.order(:position).last

    regatta.measurement_sets.where(measuring_point: mp).where.not(finish_cam_metadata: nil).inject({}) do |h, ms|
      finish_cam_metadata = JSON.parse(ms.finish_cam_metadata)
      session = finish_cam_metadata["session"]
      session["time_start"] = Time.at(session["time_start"])

      current_height = 0
      # Starting at Lane 0
      lane_tops = [current_height] + finish_cam_metadata["lane_heights"].reverse.map do |perc|
        current_height += perc / 100.0
      end

      start_date = ms.race.started_at
      Array.wrap(ms.measurements).inject(h) do |h2, (tnr, time, _rel_time)|
        next h2 unless time.present?

        time = Time.zone.parse(time).change(year: start_date.year, month: start_date.month, day: start_date.day)
        result = ms.race.results.find { |s| s.participant_id == tnr }
        lane = result&.lane_number
        next h2 unless lane

        idx = ((time - session["time_start"]) / session["time_span"].to_f).floor
        x = ((time - session["time_start"]) % session["time_span"]) / session["time_span"].to_f
        y_center = 1.0 - (lane_tops[lane] + lane_tops[lane - 1]) / 2.0
        height = lane_tops[lane] - lane_tops[lane - 1]

        key = [session["session_name"], idx]

        h2.merge(key => (h2[key] || []) + [[x, y_center, height]])
      end
    end.each do |(session_name, idx), xy_coords|
      img_url = "#{mp.finish_cam_base_url}/data/#{session_name}/img#{idx}.webp"
      img_path = images_dir.join("img#{session_name}_#{idx}.webp")
      label_path = labels_dir.join("img#{session_name}_#{idx}.txt")

      begin
        URI.open(img_url) do |img_file|
          File.binwrite(img_path, img_file.read)
        end
      rescue OpenURI::HTTPError => e
        puts "Fehler beim Herunterladen #{img_url}: #{e.message}"
        next
      end

      # YOLOv8 DETECT format: class_id x_center y_center width height (all normalized)
      box_size = 0.01 # 1% box around the point
      label_lines = xy_coords.map do |x, y_center, height|
        "0 #{x.round(6)} #{y_center.round(6)} #{box_size} #{height.round(6)}"
      end

      File.write(label_path, label_lines.join("\n"))
    end
  end

end
