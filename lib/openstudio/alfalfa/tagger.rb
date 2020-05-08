require 'json'

module OpenStudio
  module Alfalfa
    class Tagger
      attr_reader :building, :wf, :haystack_json
      def initialize(model)
        """
        Must pass in a 'gotten' model
        """
        @model = model
        @building = @model.getBuilding
        # puts @model.weatherFile.get
        if @model.weatherFile.is_initialized
          @wf = @model.weatherFile.get
        else
          @wf = nil
        end
        if @wf.nil?
          puts "Weather file must be initialized for model"
          exit(1)
        end
        @storys = @model.getBuildingStorys
        @tz = @model.getThermalZones
        @air_loops = @model.getAirLoopHVACs
        @haystack_json = []
        @base_ahus_tagged = false
        @ahu_components_tagged =false
      end

      def create_uuid(dummyinput)
        return "r:#{OpenStudio.removeBraces(OpenStudio.createUUID)}"
      end

      def create_ref(id)
        #return string formatted for Ref (ie, "r:xxxxx") with uuid of object
        #return "r:#{id.gsub(/[\s-]/,'_')}"
        return "r:#{OpenStudio.removeBraces(id)}"
      end

      def create_ref_name(id)
        #return string formatted for Ref (ie, "r:xxxxx") with uuid of object
        return "r:#{id.gsub(/[\s-]/, '_')}"
      end

      def create_str(str)
        #return string formatted for strings (ie, "s:xxxxx")
        return "s:#{str}"
      end

      def create_num(str)
        #return string formatted for numbers (ie, "n:xxxxx")
        return "n:#{str}"
      end

      def create_ems_str(id)
        #return string formatted with no spaces or '-' (can be used as EMS var name)
        return "#{id.gsub(/[\s-]/, '_')}"
      end

      def create_point_timevars(outvar_time, siteRef)
        #this function will add haystack tag to the time-variables created by user.
        #the time-variables are also written to variables.cfg file to coupling energyplus
        #the uuid is unique to be used for mapping purpose
        #the point_json generated here caontains the tags for the tim-variables
        point_json = Hash.new
        #id = outvar_time.keyValue.to_s + outvar_time.name.to_s
        uuid = create_uuid("")
        point_json[:id] = uuid
        #point_json[:source] = create_str("EnergyPlus")
        #point_json[:type] = "Output:Variable"
        #point_json[:name] = create_str(outvar_time.name.to_s)
        #point_json[:variable] = create_str(outvar_time.name)
        point_json[:dis] = create_str(outvar_time.nameString)
        point_json[:siteRef] = create_ref(siteRef)
        point_json[:point] = "m:"
        point_json[:cur] = "m:"
        point_json[:curStatus] = "s:disabled"

        return point_json, uuid
      end

      # end of create_point_timevar

      def create_mapping_timevars(outvar_time, uuid)
        #this function will use the uuid generated from create_point_timevars(), to make a mapping.
        #the uuid is unique to be used for mapping purpose; uuid is the belt to connect point_json and mapping_json
        #the mapping_json below contains all the necessary tags
        mapping_json = Hash.new
        mapping_json[:id] = uuid
        mapping_json[:source] = "EnergyPlus"
        mapping_json[:name] = "EMS"
        mapping_json[:type] = outvar_time.nameString
        mapping_json[:variable] = ""

        return mapping_json
      end


      def create_point_uuid(type, id, siteRef, equipRef, floorRef, where, what, measurement, kind, unit)
        point_json = Hash.new
        uuid = create_uuid(id)
        point_json[:id] = uuid
        point_json[:dis] = create_str(id)
        point_json[:siteRef] = create_ref(siteRef)
        point_json[:equipRef] = create_ref(equipRef)
        point_json[:floorRef] = create_ref(floorRef)
        point_json[:point] = "m:"
        point_json["#{type}"] = "m:"
        point_json["#{measurement}"] = "m:"
        point_json["#{where}"] = "m:"
        point_json["#{what}"] = "m:"
        point_json[:kind] = create_str(kind)
        point_json[:unit] = create_str(unit)
        point_json[:cur] = "m:"
        point_json[:curStatus] = "s:disabled"
        return point_json, uuid
      end

      def create_point2_uuid(type, type2, id, siteRef, equipRef, floorRef, where, what, measurement, kind, unit)
        point_json = Hash.new
        uuid = create_uuid(id)
        point_json[:id] = uuid
        point_json[:dis] = create_str(id)
        point_json[:siteRef] = create_ref(siteRef)
        point_json[:equipRef] = create_ref(equipRef)
        point_json[:floorRef] = create_ref(floorRef)
        point_json[:point] = "m:"
        point_json["#{type}"] = "m:"
        point_json["#{type2}"] = "m:"
        point_json["#{measurement}"] = "m:"
        point_json["#{where}"] = "m:"
        point_json["#{what}"] = "m:"
        point_json[:kind] = create_str(kind)
        point_json[:unit] = create_str(unit)
        point_json[:cur] = "m:"
        point_json[:curStatus] = "s:disabled"
        return point_json, uuid
      end

      def create_controlpoint2(type, type2, id, uuid, siteRef, equipRef, floorRef, where, what, measurement, kind, unit)
        point_json = Hash.new
        point_json[:id] = create_ref(uuid)
        point_json[:dis] = create_str(id)
        point_json[:siteRef] = create_ref(siteRef)
        point_json[:equipRef] = create_ref(equipRef)
        point_json[:floorRef] = create_ref(floorRef)
        point_json[:point] = "m:"
        point_json["#{type}"] = "m:"
        point_json["#{type2}"] = "m:"
        point_json["#{measurement}"] = "m:"
        point_json["#{where}"] = "m:"
        point_json["#{what}"] = "m:"
        point_json[:kind] = create_str(kind)
        point_json[:unit] = create_str(unit)
        if type2 == "writable"
          point_json[:writeStatus] = "s:ok"
        end
        return point_json
      end

      ##
      # Create a Haystack 4.0 compliant fan
      def create_fan(fan, equipRef)
        point_json = Hash.new
        point_json[:id] = create_ref(fan.handle)
        point_json[:dis] = create_str(fan.name.get)
        point_json[:siteRef] = create_ref(@building.handle)
        point_json[:equipRef] = create_ref(equipRef.handle)
        point_json[:equip] = "m:"
        point_json[:fan] = "m:"
        point_json[:motor] = "m:"
        if fan.to_FanVariableVolume.is_initialized
          point_json[:variableAirVolume] = "m:"
        elsif fan.to_FanConstantVolume.is_initialized
          point_json[:steppedAirVolume] = "m:"
        elsif fan.to_FanOnOff.is_initialized
          point_json[:constantAirVolume] = "m:"
        end
        return point_json
      end

      ##
      # Wrapper around create_fan, adds 'discharge' tag and adds into @haystack_json
      def create_supply_fan(fan, equipRef)
        j = self.create_fan(fan, equipRef)
        j[:discharge] = "m:"
        @haystack_json << j
      end

      def create_dx_heating_coil(heating_coil, airloop)
        heating_coil_hash = Hash.new
        heating_coil_hash[:id] = create_ref(heating_coil.handle)
        heating_coil_hash[:dis] = create_str(heating_coil.name.get)
        heating_coil_hash[:equipRef] = create_ref(airloop.handle)
        heating_coil_hash[:equip] = "m:"
        heating_coil_hash[:coil] = "m:"
        heating_coil_hash[:heating] = "m:"
        heating_coil_hash[:dx] = "m:"
        # TODO: Add the rest of the heating coil tagset
        @haystack_json.push(heating_coil_hash)
      end

      def create_dx_cooling_coil(cooling_coil, air_loop)
        cooling_coil_hash = Hash.new
        cooling_coil_hash[:id] = create_ref(cooling_coil.handle)
        cooling_coil_hash[:dis] = create_str(cooling_coil.name.get)
        cooling_coil_hash[:equipRef] = create_ref(air_loop.handle)
        cooling_coil_hash[:equip] = "m:"
        cooling_coil_hash[:coil] = "m:"
        cooling_coil_hash[:cooling] = "m:"
        cooling_coil_hash[:dx] = "m:"
        # TODO: Add the rest of the cooling coil tagset
        @haystack_json.push(cooling_coil_hash)
      end

      # TODO: deprecate
      def create_ahu(id, name, siteRef, floorRef)
        ahu_json = Hash.new
        ahu_json[:id] = create_ref(id)
        ahu_json[:dis] = create_str(name)
        ahu_json[:ahu] = "m:"
        ahu_json[:hvac] = "m:"
        ahu_json[:equip] = "m:"
        ahu_json[:siteRef] = create_ref(siteRef)
        ahu_json[:floorRef] = create_ref(floorRef)
        return ahu_json
      end

      def create_vav(id, name, siteRef, equipRef, floorRef)
        vav_json = Hash.new
        vav_json[:id] = create_ref(id)
        vav_json[:dis] = create_str(name)
        vav_json[:hvac] = "m:"
        vav_json[:vav] = "m:"
        vav_json[:equip] = "m:"
        vav_json[:equipRef] = create_ref(equipRef)
        vav_json[:ahuRef] = create_ref(equipRef)
        vav_json[:siteRef] = create_ref(siteRef)
        vav_json[:floorRef] = create_ref(floorRef)
        return vav_json
      end

      def create_mapping_output_uuid(emsName, uuid)
        json = Hash.new
        json[:id] = create_ref(uuid)
        json[:source] = "Ptolemy"
        json[:name] = ""
        json[:type] = ""
        json[:variable] = emsName
        return json
      end

      def create_EMS_sensor_bcvtb(outVarName, key, emsName, uuid, report_freq, model)
        outputVariable = OpenStudio::Model::OutputVariable.new(outVarName, model)
        outputVariable.setKeyValue("#{key.name.to_s}")
        outputVariable.setReportingFrequency(report_freq)
        outputVariable.setName(outVarName)
        outputVariable.setExportToBCVTB(true)

        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, outputVariable)
        sensor.setKeyName(key.handle.to_s)
        sensor.setName(create_ems_str(emsName))

        json = Hash.new
        json[:id] = uuid
        json[:source] = "EnergyPlus"
        json[:type] = outVarName
        json[:name] = key.name.to_s
        json[:variable] = ""
        return sensor, json
      end

      #will get deprecated by 'create_EMS_sensor_bcvtb' once Master Algo debugged (dont clutter up the json's with unused points right now)
      def create_EMS_sensor(outVarName, key, emsName, report_freq, model)
        outputVariable = OpenStudio::Model::OutputVariable.new(outVarName, model)
        outputVariable.setKeyValue("#{key.name.to_s}")
        outputVariable.setReportingFrequency(report_freq)
        outputVariable.setName(outVarName)
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, outputVariable)
        sensor.setKeyName(key.handle.to_s)
        sensor.setName(create_ems_str(emsName))
        return sensor
      end

      ##
      # Create a Haystack compliant site definition and add to @haystack_json
      def tag_site
        site = Hash.new
        site[:id] = create_ref(@building.handle)
        site[:dis] = create_str(@building.name.to_s)
        site[:site] = "m:"
        site[:area] = create_num(@building.floorArea)
        site[:weatherRef] = create_ref(@wf.handle)
        site[:tz] = create_num(@wf.timeZone)
        site[:geoCity] = create_str(@wf.city)
        site[:geoState] = create_str(@wf.stateProvinceRegion)
        site[:geoCountry] = create_str(@wf.country)
        site[:geoCoord] = "c:#{@wf.latitude},#{@wf.longitude}"
        site[:simStatus] = "s:Stopped"
        site[:simType] = "s:osm"
        @haystack_json.push(site)
      end

      ##
      # Create a Haystack compliant weather definition and add to @haystack_json
      def tag_weather
        weather = Hash.new
        weather[:id] = create_ref(@wf.handle)
        weather[:dis] = create_str(@wf.city)
        weather[:weather] = "m:"
        weather[:tz] = create_num(@wf.timeZone)
        weather[:geoCoord] = "c:#{@wf.latitude},#{@wf.longitude}"
        @haystack_json << weather
      end

      ##
      # Create a Haystack 4.0 compliant floor and adds to @haystack_json
      def tag_stories
        @storys.each do |story|
          if story.name.is_initialized
            story_hash = Hash.new
            story_hash[:id] = create_ref(story.handle)
            story_hash[:dis] = create_str(story.name.get)
            story_hash[:siteRef] = create_ref(@building.handle)
            story_hash[:floor] = "m:"
            @haystack_json << story_hash
          end
        end
      end

      def tag_sensor(o_handle, name, b_handle)
        """
        create a haystack compliant user defined sensor point from output variables
        :params: an OS models output variables hand, name, and building handle
        :return: json representation of a haystack sensor
        """
        sensor = Hash.new
        uuid = create_ref(o_handle)
        sensor[:id] = uuid
        sensor[:dis] = create_str(name)
        sensor[:siteRef] = create_ref(b_handle)
        sensor[:point]="m:"
        sensor[:cur]="m:"
        sensor[:curStatus] = "s:disabled"
        return sensor
      end

      def tag_writable_point(global, b_handle, uuid)
        """
        create a haystack compliant user defined writable points from output variables
        :params: an OS models output variables hand, name, and building handle
        :return: json representation of a haystack sensor
        """
        writable_point = Hash.new
        writable_point[:id] = uuid
        writable_point[:dis] = create_str(global)
        writable_point[:siteRef] = create_ref(b_handle)
        writable_point[:point]="m:"
        writable_point[:writable]="m:"
        writable_point[:writeStatus] = "s:ok"
        return writable_point
      end

      ##
      # Create a Haystack compliant list of thermal zones and add
      # each of them as a separate entry into @haystack_json.
      #
      # ThermalZones are not added if they are:
      # - not connected to an airloop
      # - a plenum
      # - unconditioned
      def tag_thermal_zones
        @tz.each do |tz|
          if tz.name.is_initialized
            air_loops = tz.airLoopHVACs
            next if air_loops.size == 0
            next if tz.isPlenum
            next if !tz.isConditioned
            thermal_zone_haystack = Hash.new
            thermal_zone_haystack[:id] = create_ref(tz.handle)
            thermal_zone_haystack[:dis] = create_str(tz.name.get)
            thermal_zone_haystack[:siteRef] = create_ref(@building.handle)
            thermal_zone_haystack[:hvac] = "m:"
            thermal_zone_haystack[:zone] = "m:"
            thermal_zone_haystack[:space] = "m:"
            @haystack_json << thermal_zone_haystack
          end
        end
      end

      ##
      # Tag air loops as ahu based on Haystack 4.0
      # https://project-haystack.dev/doc/lib-phIoT/ahu
      # Does not add any additional parameters, that is done by separate functions
      def tag_base_ahus
        @air_loops.each do |air_loop|
          if air_loop.name.is_initialized
            ahu_hash = Hash.new
            ahu_hash[:id] = create_ref(air_loop.handle)
            ahu_hash[:dis] = create_str(air_loop.name)
            ahu_hash[:siteRef] = create_ref(@building.handle)
            ahu_hash[:equip] = "m:"
            ahu_hash[:ahu] = "m:"
            @haystack_json << ahu_hash
          end
        end
        @base_ahus_tagged = true
      end

      ##
      # Create Haystack compliant fans and ref them back to the parent AHU
      # TODO:
      #  1. Need to tag other types of fans - exhaust, return, outside
      #  2. Check that create_fan is up to date with Haystack 4.0
      #  3. Add some logic that is of the effect: If I have a dx
      def tag_air_loop_components
        # Step 1 - tag things inside the airloop
        if !@base_ahus_tagged
          self.tag_base_ahus
        end
        @air_loops.each do |air_loop|
          air_loop.supplyComponents.each do |sc|
            self.tag_fans(air_loop, sc)
            self.tag_heating_and_cooling_components(air_loop, sc)
          end
        end
        @ahu_components_tagged = true
      end

      # Step 2 - add 'typing' tags to the airloop based on what's inside.
      def tag_air_loops
        if !@base_ahus_tagged
          self.tag_base_ahus
        end
        if !@ahu_components_tagged
          self.tag_air_loop_components
        end
        @air_loops.each do |air_loop|
          self.air_loop_typing(air_loop)
        end
      end

      def air_loop_typing(air_loop)
        @haystack_json.each do |entity|
          if entity[:id] == create_ref(air_loop.handle)
            self.infer_heating_type(entity)
            self.infer_cooling_type(entity)
          end
        end
      end

      # Find a {equip coil heating}
      def infer_heating_type(entity_to_type)
        @haystack_json.each do |entity|
          if entity[:equipRef] == entity_to_type[:id] and Set[:equip, :coil, :heating].subset? entity.keys.to_set
            if entity.key?(:dx)
              entity_to_type[:dxHeating] = "m:"
            elsif entity.key?(:elec)
              entity_to_type[:elecHeating] = "m:"
            elsif entity.key?(:steam)
              entity_to_type[:steamHeating] = "m:"
            elsif entity.key?(:gas)
              entity_to_type[:gasHeating] = "m:"
            elsif Set[:hot, :water].subset? entity.keys.to_set
              entity_to_type[:hotWaterHeating] = "m:"
            end
          end
        end
      end

      # Find a {equip coil cooling}
      def infer_cooling_type(entity_to_type)
        @haystack_json.each do |entity|
          if entity[:equipRef] == entity_to_type[:id] and Set[:equip, :coil, :cooling].subset? entity.keys.to_set
            if entity.key?(:dx)
              entity_to_type[:dxCooling] = "m:"
            elsif Set[:chilled, :water].subset? entity.keys.to_set
              entity_to_type[:chilledWaterCooling] = "m:"
            end
          end
        end
      end

      def tag_fans(air_loop, sc)
        if sc.to_AirLoopHVACOutdoorAirSystem.is_initialized
          # A UnitarySystem will only have a supply fan
        elsif sc.to_AirLoopHVACUnitarySystem.is_initialized
          unitary_system = sc.to_AirLoopHVACUnitarySystem.get
          supply_fan = unitary_system.supplyFan
          if supply_fan.is_initialized
            self.create_supply_fan(supply_fan, air_loop)
          end
          # A heat pump will only have a supplyAirFan
        elsif sc.to_AirLoopHVACUnitaryHeatPumpAirToAir.is_initialized
          heat_pump = sc.to_AirLoopHVACUnitaryHeatPumpAirToAir.get
          supply_fan = heat_pump.supplyAirFan
          if supply_fan.initialized
            self.create_supply_fan(supply_fan, air_loop)
          end
        elsif sc.to_FanConstantVolume.is_initialized
          self.create_supply_fan(sc, air_loop)
        elsif sc.to_FanVariableVolume.is_initialized
          self.create_supply_fan(sc, air_loop)
        elsif sc.to_FanOnOff.is_initialized
          self.create_supply_fan(sc, air_loop)
        end
      end

      def tag_heating_and_cooling_components(air_loop, sc)
        if sc.to_AirLoopHVACUnitaryHeatPumpAirToAir.is_initialized
          heat_pump = sc.to_AirLoopHVACUnitaryHeatPumpAirToAir.get
          heating_coil = heat_pump.heatingCoil
          cooling_coil = heat_pump.coolingCoil
          if heating_coil.initialized
            self.create_dx_heating_coil(heating_coil, air_loop)
          end
          if cooling_coil.initialized
            self.create_dx_cooling_coil(cooling_coil, air_loop)
          end
        end
      end

      def add_heating_process_to_ahu
      # def tag_system_node(node, node_type)
      #   """
      #
      #   """
      #   temp_sensor, temp_uuid
      #
      end
    end
  end
end
