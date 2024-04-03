library(googlesheets4)
#
# read data from google sheet =====
data <- read_sheet("https://docs.google.com/spreadsheets/d/1ZE0DmZfJcgQ_K_1jsta_OAVmADc8z5F_aLhJlEk7CZU/edit#gid=0")
save(list = "data", file = "data.Rdata") # save as Rdata for subsequent analysis
#
# if error in reading google sheet (PERMISSION_DENIED) try run the following:
# googlesheets4::gs4_deauth()
# googlesheets4::gs4_auth()
# then choose "Send me to the browser for a new auth process." and check the box "See, edit, create, and delete all your Google Sheets spreadsheets."