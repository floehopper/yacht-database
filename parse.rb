require 'bundler/setup'
require 'nokogiri'
require 'sqlite3'

NBSP = Nokogiri::HTML("&nbsp;")

def parse(file)
  attributes = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }
  section_key = 'DEFAULT'
  page = Nokogiri::HTML(file)
  attributes[section_key]['Name'] = page.css('font[size="6"][color="#C00000"]').map(&:text)
  rows = page.css('table[width="728"] > tr')
  rows.each do |row|
    cells = row.css('> td')
    if cells.length == 1
      tables = cells.first.css('> table')
      if tables.empty?
        section_key = cells.first.css('font b').first.text
      else
        inner_rows = tables.first.css('tr')
        if inner_rows.length == 1
          lines = inner_rows.css('td font').first.text.split("\r\n")
          lines.each.with_index do |line, index|
            attributes[section_key]['Lines'] << line.strip
          end
        end
      end
    else
      cells.each_slice(2) do |key, value|
        clean_key = key.text.gsub("\n", '').strip.sub(NBSP, '').sub(%r{\:$}, '')
        clean_value = value.text.gsub("\n", '').strip.sub(NBSP, '')
        attributes[section_key][clean_key] << clean_value
      end
    end
  end
  attributes
end

STRING = %r{^(?<string>.*)$}
FT_AND_M = %r{^(?<ft>\d+\.\d+)'\s*/\s*(?<m>\d+\.\d+)m$}
FT2_AND_M2 = %r{^(?<ft2>\d+)\s*ft2\s*/\s*(?<m2>\d+\.\d+)\s*m2$}
LBS_AND_KGS = %r{^(?<lbs>\d+)\s*lbs\.\s*/\s*(?<kgs>\d+)\s*kgs\.$}
PERCENT = %r{^(?<percent>\d+?(\.\d+))%$}
GALS_AND_LTRS = %r{^(?<gals>\d+)\s*gals\.\s*/\s*(?<ltrs>\d+)\s*ltrs\.$}

class Extractor
  def initialize(attributes)
    @attributes = attributes
  end

  def extract(section_key, key, pattern = STRING, group = 'string')
    if section = @attributes[section_key]
      if values = section[key]
        result = values.map do |value|
          (value.match(pattern) || {})[group]
        end
        (result.length <= 1) ? result.first : result
      end
    end
  end
end

def transform(attributes)
  e = Extractor.new(attributes)
  {
    'name' => e.extract('DEFAULT', 'Name'),
    'hull_type' => e.extract('DEFAULT', 'Hull Type'),
    'rig_type' => e.extract('DEFAULT', 'Rig Type'),
    'length_overall_in_feet' => e.extract('DEFAULT', 'LOA', FT_AND_M, 'ft'),
    'length_overall_in_metres' => e.extract('DEFAULT', 'LOA', FT_AND_M, 'm'),
    'waterline_length_in_feet' => e.extract('DEFAULT', 'LWL', FT_AND_M, 'ft'),
    'waterline_length_in_metres)' => e.extract('DEFAULT', 'LWL', FT_AND_M, 'm'),
    'beam_in_feet' => e.extract('DEFAULT', 'Beam', FT_AND_M, 'ft'),
    'beam_in_metres' => e.extract('DEFAULT', 'Beam', FT_AND_M, 'm'),
    'listed_sail_area_in_ft2' => e.extract('DEFAULT', 'Listed SA', FT2_AND_M2, 'ft2'),
    'listed_sail_area_in_m2' => e.extract('DEFAULT', 'Listed SA', FT2_AND_M2, 'm2'),
    'maximum_draft_in_feet' => e.extract('DEFAULT', 'Draft (max.)', FT_AND_M, 'ft'),
    'maximum_draft_in_metres' => e.extract('DEFAULT', 'Draft (max.)', FT_AND_M, 'm'),
    'minimum_draft_in_feet' => e.extract('DEFAULT', 'Draft (min.)', FT_AND_M, 'ft'),
    'minimum_draft_in_metres' => e.extract('DEFAULT', 'Draft (min.)', FT_AND_M, 'm'),
    'displacement_in_lbs' => e.extract('DEFAULT', 'Displacement', LBS_AND_KGS, 'lbs'),
    'displacement_in_kgs' => e.extract('DEFAULT', 'Displacement', LBS_AND_KGS, 'kgs'),
    'ballast_in_lbs' => e.extract('DEFAULT', 'Ballast', LBS_AND_KGS, 'lbs'),
    'ballast_in_kgs' => e.extract('DEFAULT', 'Ballast', LBS_AND_KGS, 'kgs'),
    'sail_area_vs_displacement_ratio_1' => e.extract('DEFAULT', 'Sail Area/Disp.1'),
    'ballast_vs_displacment_ratio' => e.extract('DEFAULT', 'Bal./Disp.', PERCENT, 'percent'),
    'designer' => e.extract('DEFAULT', 'Designer'),
    'builder' => e.extract('DEFAULT', 'Builder'),
    'construction' => e.extract('DEFAULT', 'Construction'),
    'ballast_type' => e.extract('DEFAULT', 'Bal. type'),
    'first_built' => e.extract('DEFAULT', 'First Built'),
    'last_built' => e.extract('DEFAULT', 'Last Built'),
    'number_built' => e.extract('DEFAULT', '# Built'),

    'original_engine_make' => e.extract('AUXILIARY POWER (orig. equip.)', 'Make'),
    'original_engine_model' => e.extract('AUXILIARY POWER (orig. equip.)', 'Model'),
    'original_engine_type' => e.extract('AUXILIARY POWER (orig. equip.)', 'Type'),
    'original_engine_power_in_hp' => e.extract('AUXILIARY POWER (orig. equip.)', 'HP'),

    'water_tank_capacity_in_gallons' => e.extract('TANKS', 'Water', GALS_AND_LTRS, 'gals'),
    'water_tank_capacity_in_litres' => e.extract('TANKS', 'Water', GALS_AND_LTRS, 'ltrs'),
    'fuel_tank_capacity_in_gallons' => e.extract('TANKS', 'Fuel', GALS_AND_LTRS, 'gals'),
    'fuel_tank_capacity_in_litres' => e.extract('TANKS', 'Fuel', GALS_AND_LTRS, 'ltrs'),

    'i_ig_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'I(IG)', FT_AND_M, 'ft'),
    'i_ig_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'I(IG)', FT_AND_M, 'm'),
    'j_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'J', FT_AND_M, 'ft'),
    'j_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'J', FT_AND_M, 'm'),
    'p_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'P', FT_AND_M, 'ft'),
    'p_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'P', FT_AND_M, 'm'),
    'e_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'E', FT_AND_M, 'ft'),
    'e_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'E', FT_AND_M, 'm'),
    'py_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'PY', FT_AND_M, 'ft'),
    'py_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'PY', FT_AND_M, 'm'),
    'ey_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'EY', FT_AND_M, 'ft'),
    'ey_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'EY', FT_AND_M, 'm'),
    'isp_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'ISP', FT_AND_M, 'ft'),
    'isp_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'ISP', FT_AND_M, 'm'),
    'spl_tps_measurement_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'SPL/TPS', FT_AND_M, 'ft'),
    'spl_tps_measurement_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'SPL/TPS', FT_AND_M, 'm'),
    'fore_triangle_sail_area_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'SA(Fore.)', FT_AND_M, 'ft'),
    'fore_triangle_sail_area_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'SA(Fore.)', FT_AND_M, 'm'),
    'main_triangle_sail_area_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'SA(Main)', FT_AND_M, 'ft'),
    'main_triangle_sail_area_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'SA(Main)', FT_AND_M, 'm'),
    'hundred_percent_fore_and_main_triangle_sail_area_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'Sail Area (100% fore+main triangles)', FT_AND_M, 'ft'),
    'hundred_percent_fore_and_main_triangle_sail_area_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'Sail Area (100% fore+main triangles)', FT_AND_M, 'm'),
    'sail_area_vs_displacement_ratio_2' => e.extract('RIG AND SAIL PARTICULARS', 'Sail Area/Disp.2'),
    'estimated_forestay_length_in_feet' => e.extract('RIG AND SAIL PARTICULARS', 'Est. Forestay Length.', FT_AND_M, 'ft'),
    'estimated_forestay_length_in_metres' => e.extract('RIG AND SAIL PARTICULARS', 'Est. Forestay Length.', FT_AND_M, 'm'),

    'builders' => Array(e.extract('BUILDERS (past & present)', 'More about & boats built by')),

    'designers' => Array(e.extract('DESIGNER', 'More about & boats designed by')),

    'notes' => Array(e.extract('NOTES', 'Lines')).join(' '),
  }
end

db = SQLite3::Database.new('yachts.db')

path = Pathname.new('sailboatdata')
path.each_child do |filename|
  puts filename
  file = File.open(filename)
  attributes = parse(file)
  p attributes
  result = transform(attributes)
  p result
  db.execute(%{
    INSERT INTO yachts (
      name,
      hull_type,
      rig_type,
      length_overall_in_feet,
      length_overall_in_metres,
      waterline_length_in_feet,
      waterline_length_in_metres,
      beam_in_feet,
      beam_in_metres,
      listed_sail_area_in_ft2,
      listed_sail_area_in_m2,
      maximum_draft_in_feet,
      maximum_draft_in_metres,
      minimum_draft_in_feet,
      minimum_draft_in_metres,
      displacement_in_lbs,
      displacement_in_kgs,
      ballast_in_lbs,
      ballast_in_kgs,
      sail_area_vs_displacement_ratio_1,
      ballast_vs_displacment_ratio,
      designer,
      builder,
      construction,
      ballast_type,
      first_built,
      last_built,
      number_built,
      original_engine_make,
      original_engine_model,
      original_engine_type,
      original_engine_power_in_hp,
      water_tank_capacity_in_gallons,
      water_tank_capacity_in_litres,
      fuel_tank_capacity_in_gallons,
      fuel_tank_capacity_in_litres,
      i_ig_measurement_in_feet,
      i_ig_measurement_in_metres,
      j_measurement_in_feet,
      j_measurement_in_metres,
      p_measurement_in_feet,
      p_measurement_in_metres,
      e_measurement_in_feet,
      e_measurement_in_metres,
      py_measurement_in_feet,
      py_measurement_in_metres,
      ey_measurement_in_feet,
      ey_measurement_in_metres,
      isp_measurement_in_feet,
      isp_measurement_in_metres,
      spl_tps_measurement_in_feet,
      spl_tps_measurement_in_metres,
      fore_triangle_sail_area_in_feet,
      fore_triangle_sail_area_in_metres,
      main_triangle_sail_area_in_feet,
      main_triangle_sail_area_in_metres,
      hundred_percent_fore_and_main_triangle_sail_area_in_feet,
      hundred_percent_fore_and_main_triangle_sail_area_in_metres,
      sail_area_vs_displacement_ratio_2,
      estimated_forestay_length_in_feet,
      estimated_forestay_length_in_metres
    ) VALUES (
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?
    )
  }, [
    result['name'],
    result['hull_type'],
    result['rig_type'],
    result['length_overall_in_feet'],
    result['length_overall_in_metres'],
    result['waterline_length_in_feet'],
    result['waterline_length_in_metres'],
    result['beam_in_feet'],
    result['beam_in_metres'],
    result['listed_sail_area_in_ft2'],
    result['listed_sail_area_in_m2'],
    result['maximum_draft_in_feet'],
    result['maximum_draft_in_metres'],
    result['minimum_draft_in_feet'],
    result['minimum_draft_in_metres'],
    result['displacement_in_lbs'],
    result['displacement_in_kgs'],
    result['ballast_in_lbs'],
    result['ballast_in_kgs'],
    result['sail_area_vs_displacement_ratio_1'],
    result['ballast_vs_displacment_ratio'],
    result['designer'],
    result['builder'],
    result['construction'],
    result['ballast_type'],
    result['first_built'],
    result['last_built'],
    result['number_built'],
    result['original_engine_make'],
    result['original_engine_model'],
    result['original_engine_type'],
    result['original_engine_power_in_hp'],
    result['water_tank_capacity_in_gallons'],
    result['water_tank_capacity_in_litres'],
    result['fuel_tank_capacity_in_gallons'],
    result['fuel_tank_capacity_in_litres'],
    result['i_ig_measurement_in_feet'],
    result['i_ig_measurement_in_metres'],
    result['j_measurement_in_feet'],
    result['j_measurement_in_metres'],
    result['p_measurement_in_feet'],
    result['p_measurement_in_metres'],
    result['e_measurement_in_feet'],
    result['e_measurement_in_metres'],
    result['py_measurement_in_feet'],
    result['py_measurement_in_metres'],
    result['ey_measurement_in_feet'],
    result['ey_measurement_in_metres'],
    result['isp_measurement_in_feet'],
    result['isp_measurement_in_metres'],
    result['spl_tps_measurement_in_feet'],
    result['spl_tps_measurement_in_metres'],
    result['fore_triangle_sail_area_in_feet'],
    result['fore_triangle_sail_area_in_metres'],
    result['main_triangle_sail_area_in_feet'],
    result['main_triangle_sail_area_in_metres'],
    result['hundred_percent_fore_and_main_triangle_sail_area_in_feet'],
    result['hundred_percent_fore_and_main_triangle_sail_area_in_metres'],
    result['sail_area_vs_displacement_ratio_2'],
    result['estimated_forestay_length_in_feet'],
    result['estimated_forestay_length_in_metres'],
  ])
end
