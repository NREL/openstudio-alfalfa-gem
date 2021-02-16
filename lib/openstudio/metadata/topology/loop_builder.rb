require_relative 'loop'
module OpenStudio
  module Metadata
    module Topology
      class LoopBuilder
        REFS_FOR_CLIMBING = ['equipRef', 'airRef']
        def initialize(equips)
          @equips = equips
          @loops = []
        end

        def build_loops
          leaves = find_leaves(@equips)
          paths = climb_to_roots(leaves)
          paths.each do |path|
            loop = equipment_in_any_loop(*path)
            loop = Loop.new if loop.nil?
            loop.add_equip_to_loop(*path)
            @loops |= [loop]
          end
          return @loops
        end

        def find_leaves(equips)
          reffed_ids = []
          equips.each do |equip|
            equip.refs.values.each do |ref|
              reffed_ids.push(ref) unless reffed_ids.include? ref
            end
          end
          return equips - equips.select { |equip| reffed_ids.include? equip.id }
        end

        def climb_to_roots(leaves)
          paths = []
          leaves.each do |leaf|
            paths.push climb(leaf)
          end
          return paths
        end

        def climb(leaf)
          touched_equip = [leaf]
          leaf.refs.each do |ref_type, ref_id|
            if REFS_FOR_CLIMBING.include? ref_type
              equip = equip_by_id(ref_id)
              touched_equip |= climb(equip)
            end
          end
          return touched_equip
        end

        def equipment_in_any_loop(*equips)
          # puts equips
          equips.each do |equip|
            # puts "looking for #{equip}"
            @loops.each do |loop|
              # puts "loop contents #{loop}"
              if loop.equip_with_id?(equip.id)
                loop_with_stuff = loop
                return loop_with_stuff
              end
            end
          end
          return nil
        end

        def equip_by_id(equip_id)
          return @equips.find { |equip| equip.id == equip_id }
        end
      end
    end
  end
end
