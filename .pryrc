# add the suplib to the load path
Pry.config.history_file = "./.pry_history"
$LOAD_PATH << './yakslib'
require 'yaks'
