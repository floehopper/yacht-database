require 'bundler/setup'
require 'sqlite3'

db = SQLite3::Database.new('yachts.db')

rows = db.execute(%{
  CREATE TABLE yachts (
    name TEXT,
    hull_type TEXT,
    rig_type TEXT,
    length_overall_in_feet REAL,
    length_overall_in_metres REAL,
    waterline_length_in_feet REAL,
    waterline_length_in_metres REAL,
    beam_in_feet REAL,
    beam_in_metres REAL,
    listed_sail_area_in_ft2 REAL,
    listed_sail_area_in_m2 REAL,
    maximum_draft_in_feet REAL,
    maximum_draft_in_metres REAL,
    minimum_draft_in_feet REAL,
    minimum_draft_in_metres REAL,
    displacement_in_lbs INTEGER,
    displacement_in_kgs INTEGER,
    ballast_in_lbs INTEGER,
    ballast_in_kgs INTEGER,
    sail_area_vs_displacement_ratio_1 REAL,
    ballast_vs_displacment_ratio REAL,
    designer TEXT,
    builder TEXT,
    construction TEXT,
    ballast_type TEXT,
    first_built INTEGER,
    last_built INTEGER,
    number_built INTEGER,
    original_engine_make TEXT,
    original_engine_model TEXT,
    original_engine_type TEXT,
    original_engine_power_in_hp INTEGER,
    water_tank_capacity_in_gallons INTEGER,
    water_tank_capacity_in_litres INTEGER,
    fuel_tank_capacity_in_gallons INTEGER,
    fuel_tank_capacity_in_litres INTEGER,
    i_ig_measurement_in_feet REAL,
    i_ig_measurement_in_metres REAL,
    j_measurement_in_feet REAL,
    j_measurement_in_metres REAL,
    p_measurement_in_feet REAL,
    p_measurement_in_metres REAL,
    e_measurement_in_feet REAL,
    e_measurement_in_metres REAL,
    py_measurement_in_feet REAL,
    py_measurement_in_metres REAL,
    ey_measurement_in_feet REAL,
    ey_measurement_in_metres REAL,
    isp_measurement_in_feet REAL,
    isp_measurement_in_metres REAL,
    spl_tps_measurement_in_feet REAL,
    spl_tps_measurement_in_metres REAL,
    fore_triangle_sail_area_in_feet REAL,
    fore_triangle_sail_area_in_metres REAL,
    main_triangle_sail_area_in_feet REAL,
    main_triangle_sail_area_in_metres REAL,
    hundred_percent_fore_and_main_triangle_sail_area_in_feet REAL,
    hundred_percent_fore_and_main_triangle_sail_area_in_metres REAL,
    sail_area_vs_displacement_ratio_2 REAL,
    estimated_forestay_length_in_feet REAL,
    estimated_forestay_length_in_metres REAL
  );
})

# builders
# designers
# notes
