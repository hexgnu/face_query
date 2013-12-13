require 'json'
class Neighborhood
  K = 4

  def initialize(files)
    @ids = {}
    @files = files
    counter = 0
    kdtree_hash = {}

    @files.each do |f|
      desc = Face.new(f).descriptors
      desc.each do |d|
        @ids[counter] = f
        kdtree_hash[counter] = d
        counter += 1
      end
    end

    @kd_tree = Containers::KDTree.new(kdtree_hash)
  end

  def attributes
    dir_glob = @files.map do |file|
      File.join(File.dirname(file), 'attributes.json')
    end.uniq

    @attributes ||= Hash[Dir.glob(dir_glob).map do |att|
      [att.split("/")[-2], JSON.parse(File.read(att))]
    end]
  end

  def self.face_class(filename, subkeys)
    dir = File.dirname(filename)
    base = File.basename(filename, '.png')
    json = JSON.parse(File.read(File.join(dir, "attributes.json")))
    @h = nil
    if json.is_a?(Array)
      @h = json.find do |hh|
        hh.fetch('ids').include?(base.to_i)
      end or raise "Cannot find #{base.to_i} inside of #{json} for file #{filename}"
    else
      @h = json
    end

    @h.select {|k,v| subkeys.include?(k) }
  end

  def attributes_guess(file, k = K)
    ids = nearest_feature_ids(file, k)

    votes = {
      'glasses' => {false => 0, true => 0},
      'facial_hair' => {false => 0, true => 0}
    }

    ids.each do |id|
      resp = self.class.face_class(@ids[id], %w[glasses facial_hair])

      resp.each do |k,v|
        votes[k][v] += 1
      end
    end

    votes
  end

  def file_from_id(id)
    @ids.fetch(id)
  end

  def nearest_feature_ids(file, k)
    desc = Face.new(file).descriptors

    ids = []

    desc.each do |d|
      ids.concat(@kd_tree.find_nearest(d, k).map(&:last))
    end

    ids.uniq
  end
end