require 'speedrunslive'

class Game < ActiveRecord::Base
  include SRLGame

  validates :name, presence: true

  has_many :categories
  has_many :runs, through: :categories

  after_touch :destroy, if: Proc.new { |game| game.categories.count.zero? }

  scope :named, -> { where.not(name: nil) }

  def self.search(term)
    t = self.arel_table
    where(t[:name].matches("%#{term}%").or(t[:shortname].eq(term))).order(:name)
  end

  def self.from_name(name)
    return nil if name.nil?
    where("lower(name) = ?", name.strip.downcase).first_or_create(name: name.strip)
  end

  def to_param
    shortname || name.downcase.gsub(/\..*/, '')
  end

  def sync_with_srl
    return if shortname.present?
    game = ::SpeedRunsLive.game(name)
    return if game.nil?

    update(shortname: game['abbrev'])
  end

  def to_s
    name
  end

  def popular_categories
    categories.joins(:runs).group('categories.id').having('count(runs.id) >= ' + (Run.where(category: categories.pluck(:id)).count / 20).to_s).order('count(runs.id) desc')
  end

  def unpopular_categories
    categories.joins(:runs).group('categories.id').having('count(runs.id) < ' + (Run.where(category: categories.pluck(:id)).count / 20).to_s).order('count(runs.id) desc')
  end
end
