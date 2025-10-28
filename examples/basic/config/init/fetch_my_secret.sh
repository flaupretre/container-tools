# This script fetches a secret value from a remote location and transmits
# it to the main container(s).
#=============================================================================

MY_SECRET='secret-"value\1`23\$foo$bar'  # Replace this with the actual code to fetch secret

ctools_save_var MY_SECRET
